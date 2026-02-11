#!/bin/bash
# inbox-install.sh — 安裝/移除 bot-inbox launchd 定時任務
#
# 泛用版：讀取 .bot-inbox-config.json 取得專案設定
#
# 用法：
#   ./inbox-install.sh [PROJECT_DIR] install    # 安裝（每 10 分鐘執行）
#   ./inbox-install.sh [PROJECT_DIR] uninstall  # 移除
#   ./inbox-install.sh [PROJECT_DIR] status     # 檢查狀態

set -euo pipefail

# 專案目錄：如果第一個參數是目錄就用它，否則用 pwd
if [ -d "${1:-}" ]; then
  PROJECT_DIR="$1"
  shift
else
  PROJECT_DIR="$(pwd)"
fi

CONFIG_FILE="$PROJECT_DIR/.bot-inbox-config.json"
if [ ! -f "$CONFIG_FILE" ]; then
  echo "錯誤：$PROJECT_DIR 下找不到 .bot-inbox-config.json"
  echo "請先建立設定檔。範例："
  echo '{'
  echo '  "telegram_group_id": "-XXXXXXXXXX",'
  echo '  "github_repo": "owner/repo",'
  echo '  "members": [{"name": "Alice", "user_id": 12345}],'
  echo '  "bot_user_id": 67890,'
  echo '  "offset_file": ".bot-inbox-offset",'
  echo '  "pending_file": ".bot-inbox-pending.json"'
  echo '}'
  exit 1
fi

# 從 config 讀取設定
read_config() {
  python3 -c "import json; c=json.load(open('$CONFIG_FILE')); print(c.get('$1','$2'))" 2>/dev/null || echo "$2"
}

OFFSET_FILE=$(read_config "offset_file" ".bot-inbox-offset")
PENDING_FILE=$(read_config "pending_file" ".bot-inbox-pending.json")
LOG_FILE=$(read_config "log_file" ".bot-inbox-daemon.log")

# 用專案名稱產生唯一的 plist 名
PROJECT_SLUG=$(basename "$PROJECT_DIR" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
PLIST_NAME="com.bot-inbox.${PROJECT_SLUG}"
PLIST_PATH="$HOME/Library/LaunchAgents/${PLIST_NAME}.plist"

# daemon 腳本：plugin 目錄下的 scripts/inbox-daemon.sh
PLUGIN_DIR="$(cd "$(dirname "$0")" && pwd)"
DAEMON_SCRIPT="$PLUGIN_DIR/inbox-daemon.sh"

INTERVAL=600  # 10 分鐘

install() {
  echo "安裝 bot-inbox 定時任務..."
  echo "  專案: $PROJECT_DIR"
  echo "  Plist: $PLIST_NAME"

  # 確認 daemon 腳本存在且可執行
  if [ ! -f "$DAEMON_SCRIPT" ]; then
    echo "錯誤：找不到 $DAEMON_SCRIPT"
    exit 1
  fi
  chmod +x "$DAEMON_SCRIPT"

  # 如果已存在，先卸載
  if launchctl list | grep -q "$PLIST_NAME" 2>/dev/null; then
    echo "偵測到已安裝，先卸載..."
    launchctl bootout "gui/$(id -u)" "$PLIST_PATH" 2>/dev/null || true
  fi

  # 產生 plist
  cat > "$PLIST_PATH" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>${PLIST_NAME}</string>

  <key>ProgramArguments</key>
  <array>
    <string>${DAEMON_SCRIPT}</string>
    <string>${PROJECT_DIR}</string>
  </array>

  <key>StartInterval</key>
  <integer>${INTERVAL}</integer>

  <key>WorkingDirectory</key>
  <string>${PROJECT_DIR}</string>

  <key>StandardOutPath</key>
  <string>${PROJECT_DIR}/${LOG_FILE}</string>

  <key>StandardErrorPath</key>
  <string>${PROJECT_DIR}/${LOG_FILE}</string>

  <key>EnvironmentVariables</key>
  <dict>
    <key>PATH</key>
    <string>/usr/local/bin:/usr/bin:/bin:/opt/homebrew/bin</string>
    <key>HOME</key>
    <string>${HOME}</string>
  </dict>

  <key>RunAtLoad</key>
  <false/>

  <key>Nice</key>
  <integer>10</integer>
</dict>
</plist>
PLIST

  # 載入
  launchctl bootstrap "gui/$(id -u)" "$PLIST_PATH"

  echo ""
  echo "已安裝！每 ${INTERVAL} 秒（$(( INTERVAL / 60 )) 分鐘）檢查一次"
  echo "Plist: $PLIST_PATH"
  echo "Log:   $PROJECT_DIR/$LOG_FILE"
  echo ""
  echo "管理指令："
  echo "  狀態：  $0 $PROJECT_DIR status"
  echo "  移除：  $0 $PROJECT_DIR uninstall"
  echo "  手動跑：$DAEMON_SCRIPT $PROJECT_DIR"
}

uninstall() {
  echo "移除 bot-inbox 定時任務 ($PLIST_NAME)..."

  if launchctl list | grep -q "$PLIST_NAME" 2>/dev/null; then
    launchctl bootout "gui/$(id -u)" "$PLIST_PATH" 2>/dev/null || true
    echo "已從 launchd 卸載"
  else
    echo "launchd 中沒有找到此任務"
  fi

  if [ -f "$PLIST_PATH" ]; then
    rm "$PLIST_PATH"
    echo "已刪除 $PLIST_PATH"
  fi

  echo "完成"
}

status() {
  echo "=== Bot Inbox Daemon 狀態 ==="
  echo "專案: $PROJECT_DIR"
  echo ""

  # launchd 狀態
  if launchctl list | grep -q "$PLIST_NAME" 2>/dev/null; then
    echo "launchd: 已安裝（每 $(( INTERVAL / 60 )) 分鐘）"
    launchctl list "$PLIST_NAME" 2>/dev/null || true
  else
    echo "launchd: 未安裝"
  fi
  echo ""

  # Plist
  if [ -f "$PLIST_PATH" ]; then
    echo "Plist:   $PLIST_PATH"
  else
    echo "Plist:   不存在"
  fi

  # Offset
  if [ -f "$PROJECT_DIR/$OFFSET_FILE" ]; then
    echo "Offset:  $(cat "$PROJECT_DIR/$OFFSET_FILE")"
  else
    echo "Offset:  (未初始化)"
  fi

  # Pending
  if [ -f "$PROJECT_DIR/$PENDING_FILE" ]; then
    ITEMS=$(python3 -c "import json; print(len(json.load(open('$PROJECT_DIR/$PENDING_FILE')).get('items',[])))" 2>/dev/null || echo "?")
    echo "Pending: $ITEMS 個待審核項目"
  else
    echo "Pending: (無)"
  fi

  # Log 最後幾行
  if [ -f "$PROJECT_DIR/$LOG_FILE" ]; then
    echo ""
    echo "=== 最近 Log ==="
    tail -5 "$PROJECT_DIR/$LOG_FILE"
  fi
}

case "${1:-}" in
  install)   install ;;
  uninstall) uninstall ;;
  status)    status ;;
  *)
    echo "用法: $0 [PROJECT_DIR] {install|uninstall|status}"
    echo ""
    echo "  install    安裝 launchd 定時任務（每 10 分鐘）"
    echo "  uninstall  移除定時任務"
    echo "  status     檢查狀態"
    echo ""
    echo "PROJECT_DIR 預設為目前目錄，需含 .bot-inbox-config.json"
    exit 1
    ;;
esac
