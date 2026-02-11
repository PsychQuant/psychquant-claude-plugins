#!/bin/bash
# inbox-daemon.sh — 定時檢查 Telegram 新訊息（由 launchd 呼叫）
#
# 泛用版：讀取 .bot-inbox-config.json 取得專案設定
#
# 用法：
#   ./inbox-daemon.sh [PROJECT_DIR]      # 正常執行
#   ./inbox-daemon.sh [PROJECT_DIR] --dry-run  # 只檢查，不執行 claude
#
# 需要：
#   - PROJECT_DIR 下有 .bot-inbox-config.json
#   - claude CLI 在 PATH 中

set -euo pipefail

# 專案目錄：優先用參數，否則用 CLAUDE_PROJECT_DIR，否則用 pwd
PROJECT_DIR="${1:-${CLAUDE_PROJECT_DIR:-$(pwd)}}"
shift 2>/dev/null || true

cd "$PROJECT_DIR" || { echo "無法進入 $PROJECT_DIR"; exit 1; }

CONFIG_FILE=".bot-inbox-config.json"
if [ ! -f "$CONFIG_FILE" ]; then
  echo "錯誤：$PROJECT_DIR 下找不到 $CONFIG_FILE"
  exit 1
fi

# 從 config 讀取設定
read_config() {
  python3 -c "import json; c=json.load(open('$CONFIG_FILE')); print(c.get('$1','$2'))" 2>/dev/null || echo "$2"
}

TELEGRAM_GROUP_ID=$(read_config "telegram_group_id" "")
GITHUB_REPO=$(read_config "github_repo" "")
BOT_USER_ID=$(read_config "bot_user_id" "")
OFFSET_FILE=$(read_config "offset_file" ".bot-inbox-offset")
PENDING_FILE=$(read_config "pending_file" ".bot-inbox-pending.json")
LOG_FILE=$(read_config "log_file" ".bot-inbox-daemon.log")

# 成員列表（JSON 字串）
MEMBERS_JSON=$(python3 -c "import json; print(json.dumps(json.load(open('$CONFIG_FILE')).get('members',[])))" 2>/dev/null || echo "[]")

if [ -z "$TELEGRAM_GROUP_ID" ] || [ -z "$GITHUB_REPO" ]; then
  echo "錯誤：config 缺少 telegram_group_id 或 github_repo"
  exit 1
fi

# Lock file（用專案名避免衝突）
PROJECT_SLUG=$(basename "$PROJECT_DIR" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
LOCK_FILE="/tmp/bot-inbox-daemon-${PROJECT_SLUG}.lock"

# 防止重複執行
if [ -f "$LOCK_FILE" ]; then
  PID=$(cat "$LOCK_FILE" 2>/dev/null || echo "")
  if [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null; then
    echo "$(date): 另一個 daemon 正在執行 (PID $PID)，跳過" >> "$LOG_FILE"
    exit 0
  fi
  rm -f "$LOCK_FILE"
fi
echo $$ > "$LOCK_FILE"
trap 'rm -f "$LOCK_FILE"' EXIT

echo "$(date): 開始檢查 ($PROJECT_DIR)" >> "$LOG_FILE"

# dry-run 模式
if [ "${1:-}" = "--dry-run" ]; then
  echo "dry-run: 會執行 claude -p 檢查 Telegram 訊息"
  echo "PROJECT_DIR: $PROJECT_DIR"
  echo "GROUP_ID: $TELEGRAM_GROUP_ID"
  echo "REPO: $GITHUB_REPO"
  echo "OFFSET_FILE: $OFFSET_FILE (exists: $([ -f "$OFFSET_FILE" ] && echo yes || echo no))"
  echo "PENDING_FILE: $PENDING_FILE"
  echo "MEMBERS: $MEMBERS_JSON"
  exit 0
fi

# 讀取 offset
OFFSET=0
if [ -f "$OFFSET_FILE" ]; then
  OFFSET=$(cat "$OFFSET_FILE")
fi

# 用 claude -p 非互動模式執行
RESULT=$(claude -p "$(cat <<PROMPT
你是 bot-inbox daemon。檢查 Telegram 群組的新訊息。

設定：
- 群組 ID: ${TELEGRAM_GROUP_ID}
- GitHub repo: ${GITHUB_REPO}
- Bot user ID: ${BOT_USER_ID}
- 成員: ${MEMBERS_JSON}

步驟：
1. 用 mcp__che-telegram-bot-mcp__get_updates(offset=$((OFFSET + 1)), limit=100, timeout=0) 取得新訊息
2. 篩選群組 ${TELEGRAM_GROUP_ID} 的訊息，忽略 bot (user ID ${BOT_USER_ID}) 的訊息
3. 如果沒有新訊息，輸出 {"status":"no_new_messages"} 並結束
4. 對每則訊息分析類型（Feature Request / Bug Report / Data Request / Question / Chit-chat）
5. 如果有 actionable 訊息（不是 chit-chat），用 bot 在群組發消歧義問題
6. 每 30 秒 polling 等回覆，最多等 10 分鐘
7. 分析所有人的回覆，偵測觀點衝突，促進共識
8. 最後輸出 JSON：
{
  "status": "pending_review",
  "last_update_id": 最新的update_id,
  "items": [
    {
      "type": "update_issue" 或 "new_issue",
      "issue_number": 如果是更新現有issue,
      "title": "issue 標題",
      "body": "issue 內容",
      "labels": ["label1"],
      "source_messages": ["原始訊息摘要"],
      "consensus": "共識結論"
    }
  ]
}

如果所有訊息都是 chit-chat，輸出 {"status":"no_actionable_messages","last_update_id":最新的update_id}

重要：
- 不要建立 issue，只輸出建議
- 考慮所有成員的發言
- 用 gh api 檢查 ${GITHUB_REPO} 的 open issues 避免重複
- 最終輸出必須是合法 JSON
PROMPT
)" --output-format text --max-turns 30 2>>"$LOG_FILE" || true)

# 檢查結果
if [ -z "$RESULT" ]; then
  echo "$(date): claude -p 沒有輸出" >> "$LOG_FILE"
  exit 1
fi

# 從結果中提取 JSON
JSON=$(echo "$RESULT" | grep -o '{.*}' | tail -1 || echo "")

if [ -z "$JSON" ]; then
  echo "$(date): 無法提取 JSON，原始輸出：" >> "$LOG_FILE"
  echo "$RESULT" >> "$LOG_FILE"
  exit 1
fi

STATUS=$(echo "$JSON" | python3 -c "import sys,json; print(json.load(sys.stdin).get('status','unknown'))" 2>/dev/null || echo "unknown")

echo "$(date): 狀態=$STATUS" >> "$LOG_FILE"

case "$STATUS" in
  "no_new_messages"|"no_actionable_messages")
    NEW_OFFSET=$(echo "$JSON" | python3 -c "import sys,json; print(json.load(sys.stdin).get('last_update_id',''))" 2>/dev/null || echo "")
    if [ -n "$NEW_OFFSET" ] && [ "$NEW_OFFSET" != "" ]; then
      echo "$NEW_OFFSET" > "$OFFSET_FILE"
    fi
    echo "$(date): 沒有需要處理的訊息" >> "$LOG_FILE"
    ;;

  "pending_review")
    echo "$JSON" > "$PENDING_FILE"
    ITEM_COUNT=$(echo "$JSON" | python3 -c "import sys,json; print(len(json.load(sys.stdin).get('items',[])))" 2>/dev/null || echo "?")
    echo "$(date): 有 $ITEM_COUNT 個待審核項目" >> "$LOG_FILE"

    # macOS 通知
    PROJECT_NAME=$(basename "$PROJECT_DIR")
    osascript -e "display notification \"有 $ITEM_COUNT 個來自 Telegram 的待審核項目\" with title \"Bot Inbox\" subtitle \"$PROJECT_NAME — 開啟 Claude Code 審核\"" 2>/dev/null || true
    ;;

  *)
    echo "$(date): 未知狀態: $STATUS" >> "$LOG_FILE"
    echo "$RESULT" >> "$LOG_FILE"
    ;;
esac

# 保持 log 不要太大
if [ -f "$LOG_FILE" ]; then
  tail -200 "$LOG_FILE" > "${LOG_FILE}.tmp" && mv "${LOG_FILE}.tmp" "$LOG_FILE"
fi
