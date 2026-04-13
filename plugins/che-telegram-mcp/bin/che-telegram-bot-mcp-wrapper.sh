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

# NOTE: bot-mcp 不需要 PID tracking (#12)
#
# Telegram Bot API 是 stateless HTTPS client — 沒有 local DB lock、沒有
# file handle 競爭、沒有 single-instance constraint。多個 bot-mcp instance
# 並存對 Telegram 服務端來說是合法的。所以 #8 引入的整套 PID file +
# orphan cleanup + ownership check 對 bot-mcp 完全沒對應的 root cause，
# 純粹是維護成本和潛在 multi-instance race（見 #10）。
#
# 對照組：che-telegram-all-mcp-wrapper.sh 仍然需要 PID tracking，因為
# TDLib 用 single-instance binlog/sqlite。
exec "$BINARY" "$@"
