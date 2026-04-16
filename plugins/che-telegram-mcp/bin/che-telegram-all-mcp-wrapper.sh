#!/bin/bash
# Wrapper for che-telegram-all-mcp (personal account via TDLib)
# Credentials are read from macOS Keychain at runtime — never stored in config files.

BINARY_NAME="CheTelegramAllMCP"
GITHUB_REPO="PsychQuant/che-msg"
INSTALL_DIR="$HOME/bin"

# Find binary — prefer $HOME/bin (installed from release) > source builds
BINARY=""
for loc in "$INSTALL_DIR/$BINARY_NAME" "/usr/local/bin/$BINARY_NAME" "$HOME/.local/bin/$BINARY_NAME" "$HOME/Developer/che-msg/che-telegram-all-mcp/.build/release/$BINARY_NAME" "$HOME/Developer/che-mcps/che-telegram-all-mcp/.build/release/$BINARY_NAME"; do
    [[ -x "$loc" ]] && BINARY="$loc" && break
done

# Fallback: download latest binary from GitHub Release
if [[ -z "$BINARY" ]]; then
    echo "$BINARY_NAME not found. Downloading from GitHub Release..." >&2
    mkdir -p "$INSTALL_DIR"
    URL=$(curl -sL "https://api.github.com/repos/$GITHUB_REPO/releases/latest" \
        | grep '"browser_download_url"' | grep "/$BINARY_NAME\"" | head -1 \
        | sed 's/.*"\(https[^"]*\)".*/\1/')
    if [[ -n "$URL" ]]; then
        curl -sL "$URL" -o "$INSTALL_DIR/$BINARY_NAME" && chmod +x "$INSTALL_DIR/$BINARY_NAME" \
            || { echo "ERROR: Download failed." >&2; exit 1; }
        # Strip macOS quarantine to avoid Gatekeeper prompt
        xattr -dr com.apple.quarantine "$INSTALL_DIR/$BINARY_NAME" 2>/dev/null || true
        BINARY="$INSTALL_DIR/$BINARY_NAME"
        echo "Installed $BINARY_NAME to $INSTALL_DIR/" >&2
    else
        echo "ERROR: No release asset found for $BINARY_NAME." >&2
        echo "Check https://github.com/$GITHUB_REPO/releases or build from source:" >&2
        echo "  git clone https://github.com/$GITHUB_REPO.git" >&2
        echo "  cd che-telegram-all-mcp && swift build -c release" >&2
        exit 1
    fi
fi

# Read credentials from macOS Keychain
export TELEGRAM_API_ID="$(security find-generic-password -a "che-telegram-all-mcp" -s "TELEGRAM_API_ID" -w 2>/dev/null)"
export TELEGRAM_API_HASH="$(security find-generic-password -a "che-telegram-all-mcp" -s "TELEGRAM_API_HASH" -w 2>/dev/null)"

if [[ -z "$TELEGRAM_API_ID" || -z "$TELEGRAM_API_HASH" ]]; then
    echo "Telegram API credentials not found in Keychain." >&2
    echo "Set them up:" >&2
    echo "  security add-generic-password -a che-telegram-all-mcp -s TELEGRAM_API_ID -w 'YOUR_ID' -U" >&2
    echo "  security add-generic-password -a che-telegram-all-mcp -s TELEGRAM_API_HASH -w 'YOUR_HASH' -U" >&2
    echo "Get credentials at: https://my.telegram.org" >&2
    exit 1
fi

# --- PID tracking + orphan cleanup (#8) ---
# Claude Code 異常退出時，上一個 MCP server process 可能 orphan 繼續持有
# TDLib DB lock，導致新 process 的 authState 卡在 waitingForParameters。
PID_FILE="$HOME/.cache/che-telegram-all-mcp.pid"
mkdir -p "$(dirname "$PID_FILE")"

if [[ -f "$PID_FILE" ]]; then
    # `read` preserves internal whitespace (rejected by regex below),
    # unlike `tr -d` which would silently concatenate "12 34" → "1234".
    OLD_PID=
    read -r OLD_PID < "$PID_FILE" 2>/dev/null || true
    if [[ "$OLD_PID" =~ ^[0-9]+$ ]] && kill -0 "$OLD_PID" 2>/dev/null; then
        # PID recycling 防護：比對 comm 的 basename（exact match，不用 substring）
        OLD_COMM=$(ps -p "$OLD_PID" -o comm= 2>/dev/null)
        OLD_BASENAME=$(basename "$OLD_COMM" 2>/dev/null)
        if [[ "$OLD_BASENAME" == "$BINARY_NAME" ]]; then
            kill -TERM "$OLD_PID" 2>/dev/null
            # Wait up to 2s for graceful shutdown
            for _ in 1 2 3 4; do
                kill -0 "$OLD_PID" 2>/dev/null || break
                sleep 0.5
            done
            kill -0 "$OLD_PID" 2>/dev/null && kill -KILL "$OLD_PID" 2>/dev/null
        fi
    fi
fi

# Fork + wait + trap（不能用 exec，因為 exec 會取代 shell，無法 trap cleanup）
# CRITICAL: `<&0` explicitly inherits wrapper's stdin. Without it, POSIX/bash
# redirects backgrounded (&) command's stdin to /dev/null, breaking MCP
# stdio JSON-RPC protocol (#8 follow-up bug).
"$BINARY" "$@" <&0 &
BIN_PID=$!
echo "$BIN_PID" > "$PID_FILE"

cleanup() {
    # Kill binary FIRST (before removing PID file, so orphans remain trackable)
    if [[ -n "$BIN_PID" ]] && kill -0 "$BIN_PID" 2>/dev/null; then
        kill -TERM "$BIN_PID" 2>/dev/null
        # Wait up to 2s for graceful shutdown
        for _ in 1 2 3 4; do
            kill -0 "$BIN_PID" 2>/dev/null || break
            sleep 0.5
        done
        kill -0 "$BIN_PID" 2>/dev/null && kill -KILL "$BIN_PID" 2>/dev/null
        wait "$BIN_PID" 2>/dev/null
    fi
    # Ownership check: only remove PID file if it still belongs to us
    # (prevents old wrapper's late-firing trap from deleting new wrapper's PID file)
    if [[ -f "$PID_FILE" ]]; then
        CURRENT_PID=
        read -r CURRENT_PID < "$PID_FILE" 2>/dev/null || true
        [[ "$CURRENT_PID" == "$BIN_PID" ]] && rm -f "$PID_FILE"
    fi
}
trap cleanup EXIT INT TERM

wait "$BIN_PID"
exit $?
