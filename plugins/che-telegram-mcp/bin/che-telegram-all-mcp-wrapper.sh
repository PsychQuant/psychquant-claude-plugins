#!/bin/bash
# Wrapper for che-telegram-all-mcp (personal account via TDLib)
# Credentials are read from macOS Keychain at runtime — never stored in config files.
#
# Auto-upgrade design (v1.3.0+):
# - DESIRED_VERSION below pins the binary version this plugin expects.
# - ~/bin/.CheTelegramAllMCP.version sidecar tracks what's installed.
# - On mismatch, re-downloads from GitHub Release (atomic .tmp + mv).
# - Source builds in $HOME/Developer/... are NEVER auto-replaced.

BINARY_NAME="CheTelegramAllMCP"
GITHUB_REPO="PsychQuant/che-msg"
INSTALL_DIR="$HOME/bin"
INSTALLED_BINARY="$INSTALL_DIR/$BINARY_NAME"
VERSION_FILE="$INSTALL_DIR/.${BINARY_NAME}.version"
DESIRED_VERSION="0.5.0"
DOWNLOAD_TIMEOUT=600  # universal binary ~220MB; allow slow links

# Find binary — prefer $HOME/bin (installed from release) > source builds
BINARY=""
for loc in "$INSTALLED_BINARY" "/usr/local/bin/$BINARY_NAME" "$HOME/.local/bin/$BINARY_NAME" "$HOME/Developer/che-msg/che-telegram-all-mcp/.build/release/$BINARY_NAME" "$HOME/Developer/che-mcps/che-telegram-all-mcp/.build/release/$BINARY_NAME"; do
    [[ -x "$loc" ]] && BINARY="$loc" && break
done

# Decide whether to download.
NEED_DOWNLOAD=false
REASON=""
INSTALLED_VERSION=""
[[ -f "$VERSION_FILE" ]] && INSTALLED_VERSION=$(tr -d '[:space:]' < "$VERSION_FILE" 2>/dev/null || true)

if [[ -z "$BINARY" ]]; then
    NEED_DOWNLOAD=true
    REASON="binary not installed"
elif [[ "$BINARY" == "$INSTALLED_BINARY" ]] && [[ "$INSTALLED_VERSION" != "$DESIRED_VERSION" ]]; then
    # Only auto-upgrade installed binaries; never touch source builds.
    NEED_DOWNLOAD=true
    REASON="plugin wants v${DESIRED_VERSION}, installed is v${INSTALLED_VERSION:-unknown}"
fi

if $NEED_DOWNLOAD; then
    echo "$BINARY_NAME: $REASON — downloading from $GITHUB_REPO..." >&2
    mkdir -p "$INSTALL_DIR"

    # Try pinned tag first, then fall back to latest release.
    URL=""
    for API_URL in \
        "https://api.github.com/repos/$GITHUB_REPO/releases/tags/v$DESIRED_VERSION" \
        "https://api.github.com/repos/$GITHUB_REPO/releases/latest"
    do
        URL=$(curl -sL --max-time 30 "$API_URL" 2>/dev/null \
            | grep '"browser_download_url"' | grep "/$BINARY_NAME\"" | head -1 \
            | sed 's/.*"\(https[^"]*\)".*/\1/')
        [[ -n "$URL" ]] && break
    done

    if [[ -z "$URL" ]]; then
        if [[ -x "$INSTALLED_BINARY" ]]; then
            echo "$BINARY_NAME: WARNING — no download URL found, keeping existing binary" >&2
            BINARY="$INSTALLED_BINARY"
        else
            echo "$BINARY_NAME: ERROR — no release asset found at $GITHUB_REPO." >&2
            echo "  Install manually: https://github.com/$GITHUB_REPO/releases" >&2
            echo "  Or build from source:" >&2
            echo "    git clone https://github.com/$GITHUB_REPO.git ~/Developer/che-msg" >&2
            echo "    cd ~/Developer/che-msg/che-telegram-all-mcp && swift build -c release --product $BINARY_NAME" >&2
            exit 1
        fi
    else
        if curl -sL --max-time "$DOWNLOAD_TIMEOUT" "$URL" -o "${INSTALLED_BINARY}.tmp" 2>/dev/null; then
            chmod +x "${INSTALLED_BINARY}.tmp"
            xattr -dr com.apple.quarantine "${INSTALLED_BINARY}.tmp" 2>/dev/null || true
            mv "${INSTALLED_BINARY}.tmp" "$INSTALLED_BINARY"
            echo "$DESIRED_VERSION" > "$VERSION_FILE"
            echo "$BINARY_NAME: installed v$DESIRED_VERSION" >&2
            BINARY="$INSTALLED_BINARY"
        else
            rm -f "${INSTALLED_BINARY}.tmp" 2>/dev/null
            if [[ -x "$INSTALLED_BINARY" ]]; then
                echo "$BINARY_NAME: WARNING — download failed, keeping existing binary" >&2
                BINARY="$INSTALLED_BINARY"
            else
                echo "$BINARY_NAME: ERROR — download failed" >&2
                exit 1
            fi
        fi
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
