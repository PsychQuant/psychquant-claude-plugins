#!/bin/bash
# SessionStart hook: 檢查 bot inbox 狀態
#
# 兩個檢查：
#   1. daemon 產生的待審核項目（.bot-inbox-pending.json）
#   2. 距離上次檢查超過 1 小時（fallback）

cd "$CLAUDE_PROJECT_DIR" || exit 0

# 只在有設定檔的專案才執行
CONFIG_FILE=".bot-inbox-config.json"
if [ ! -f "$CONFIG_FILE" ]; then
  exit 0
fi

PENDING_FILE=$(python3 -c "import json; print(json.load(open('$CONFIG_FILE')).get('pending_file','.bot-inbox-pending.json'))" 2>/dev/null || echo ".bot-inbox-pending.json")
OFFSET_FILE=$(python3 -c "import json; print(json.load(open('$CONFIG_FILE')).get('offset_file','.bot-inbox-offset'))" 2>/dev/null || echo ".bot-inbox-offset")

# 優先檢查：daemon 產生的待審核項目
if [ -f "$PENDING_FILE" ]; then
  ITEMS=$(python3 -c "import json; print(len(json.load(open('$PENDING_FILE')).get('items',[])))" 2>/dev/null || echo "0")
  if [ "$ITEMS" -gt 0 ] 2>/dev/null; then
    echo "SessionStart:bot-inbox hook: daemon 發現 ${ITEMS} 個待審核項目（來自 Telegram）。請檢視 ${PENDING_FILE} 的內容，用 AskUserQuestion 讓用戶審核後決定是否建立/更新 issue。"
    exit 0
  fi
fi

# Fallback：檢查 offset 檔案的修改時間
if [ ! -f "$OFFSET_FILE" ]; then
  echo "SessionStart:bot-inbox hook: 尚未檢查過 Telegram 訊息。請執行 inbox-pipeline skill 檢查新訊息。"
  exit 0
fi

if [[ "$OSTYPE" == "darwin"* ]]; then
  LAST_MOD=$(stat -f %m "$OFFSET_FILE" 2>/dev/null || echo 0)
else
  LAST_MOD=$(stat -c %Y "$OFFSET_FILE" 2>/dev/null || echo 0)
fi

NOW=$(date +%s)
ELAPSED=$(( NOW - LAST_MOD ))

if [ "$ELAPSED" -gt 3600 ]; then
  HOURS=$(( ELAPSED / 3600 ))
  echo "SessionStart:bot-inbox hook: 距離上次檢查 Telegram 訊息已過 ${HOURS} 小時。請執行 inbox-pipeline skill 檢查新訊息。"
  exit 0
fi

exit 0
