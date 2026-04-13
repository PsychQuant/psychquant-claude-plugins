#!/bin/bash
# Wrapper for che-telegram-bot-mcp (Bot API)
# Bot token is read from macOS Keychain at runtime.

BINARY_NAME="CheTelegramBotMCP"
GITHUB_REPO="kiki830621/che-msg"
RELEASE_URL="https://github.com/$GITHUB_REPO/releases/latest/download/$BINARY_NAME"
INSTALL_DIR="$HOME/bin"

# Find binary
BINARY=""
for loc in "$INSTALL_DIR/$BINARY_NAME" "/usr/local/bin/$BINARY_NAME" "$HOME/.local/bin/$BINARY_NAME" "$HOME/Developer/che-msg/che-telegram-bot-mcp/.build/release/$BINARY_NAME" "$HOME/Developer/che-mcps/che-telegram-bot-mcp/.build/release/$BINARY_NAME"; do
    [[ -x "$loc" ]] && BINARY="$loc" && break
done

if [[ -z "$BINARY" ]]; then
    echo "$BINARY_NAME not found. Downloading from GitHub..." >&2
    mkdir -p "$INSTALL_DIR"
    URL=$(curl -sL "https://api.github.com/repos/$GITHUB_REPO/releases/latest" \
        | grep '"browser_download_url"' | grep "$BINARY_NAME" | head -1 \
        | sed 's/.*"\(https[^"]*\)".*/\1/')
    if [[ -n "$URL" ]]; then
        curl -sL "$URL" -o "$INSTALL_DIR/$BINARY_NAME" && chmod +x "$INSTALL_DIR/$BINARY_NAME" \
            || { echo "ERROR: Download failed." >&2; exit 1; }
        BINARY="$INSTALL_DIR/$BINARY_NAME"
        echo "Installed $BINARY_NAME to $INSTALL_DIR/" >&2
    else
        echo "No release found. Build from source:" >&2
        echo "  git clone https://github.com/$GITHUB_REPO.git" >&2
        echo "  cd che-telegram-bot-mcp && swift build -c release" >&2
        exit 1
    fi
fi

# Read bot token from macOS Keychain
export TELEGRAM_BOT_TOKEN="$(security find-generic-password -a "che-telegram-bot-mcp" -s "TELEGRAM_BOT_TOKEN" -w 2>/dev/null)"

if [[ -z "$TELEGRAM_BOT_TOKEN" ]]; then
    echo "Bot token not found in Keychain." >&2
    echo "Set it up:" >&2
    echo "  security add-generic-password -a che-telegram-bot-mcp -s TELEGRAM_BOT_TOKEN -w 'YOUR_TOKEN' -U" >&2
    echo "Get a token from @BotFather on Telegram." >&2
    exit 1
fi

# NOTE: bot-mcp 不需要 local resource PID tracking (#12)
#
# Bot API 是 HTTPS client，本地端 **沒有** local DB、file lock、binlog
# 這類 single-instance resource。所以 #8 引入的 PID file + orphan
# cleanup + ownership check 針對的「orphan 卡住下次啟動」問題，在
# bot-mcp 不存在。
#
# Caveat：`get_updates` 是 long-polling API，Telegram 服務端規定同一個
# bot token 只能有一個 client 在 polling，第二個會收到
# "409 Conflict: terminated by other getUpdates request"。所以 **多
# instance 不會 corrupt local state，但 getUpdates 會在 server side
# 互踢**。修這個 race 應該用 server-side locking (advisory lock 在
# getUpdates 呼叫前檢查)，而不是 wrapper PID tracking。見 #10 /
# Server.swift follow-up。
#
# 對照組：che-telegram-all-mcp-wrapper.sh 仍然需要 PID tracking，因為
# TDLib 用 single-instance binlog/sqlite 無法共享。
exec "$BINARY" "$@"
