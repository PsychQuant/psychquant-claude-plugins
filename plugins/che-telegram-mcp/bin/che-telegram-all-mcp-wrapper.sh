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

# --- Atomic-claim lock (#10) ---
# TDLib DB is single-instance — two MCP servers can't share it. The previous
# PID-tracking strategy (#8) is racy on multi-window scenarios: window B reads
# window A's PID, sees an alive CheTelegramAllMCP process, sends SIGTERM →
# kills window A's server unannounced. Atomic claim prevents that: window B
# finds the lock held, fails fast, lets the user decide which window keeps it.
LOCK_DIR="$HOME/.cache/che-telegram-all-mcp.lock"
LOCK_FILE="${LOCK_DIR}.flock"
LOCK_MODE=""

mkdir -p "$(dirname "$LOCK_DIR")"

if command -v flock >/dev/null 2>&1; then
    LOCK_MODE="flock"
    exec 200>"$LOCK_FILE"
    if ! flock -n 200; then
        echo "$BINARY_NAME: Another instance is already running. Use the existing Claude Code window, or kill the previous wrapper first." >&2
        exit 1
    fi
    # fd 200 stays open through wrapper lifetime; OS releases on exit
else
    LOCK_MODE="mkdir"
    if ! mkdir "$LOCK_DIR" 2>/dev/null; then
        # Stale-lock cleanup: if owner PID is dead, remove and retry once
        OWNER_PID=
        [ -f "$LOCK_DIR/owner.pid" ] && read -r OWNER_PID < "$LOCK_DIR/owner.pid" 2>/dev/null
        if [[ "$OWNER_PID" =~ ^[0-9]+$ ]] && ! kill -0 "$OWNER_PID" 2>/dev/null; then
            rm -rf "$LOCK_DIR"
            mkdir "$LOCK_DIR" 2>/dev/null || {
                echo "$BINARY_NAME: Failed to claim lock (stale-cleanup race). Retry shortly." >&2
                exit 1
            }
        else
            echo "$BINARY_NAME: Another instance is already running (lock held by PID ${OWNER_PID:-?}). Use the existing Claude Code window, or kill the previous wrapper first." >&2
            exit 1
        fi
    fi
    echo $$ > "$LOCK_DIR/owner.pid"
fi

# --- PID tracking (#8, retained for cleanup() bookkeeping) ---
# Atomic claim above prevents the multi-instance race. The PID file below is
# now used solely by cleanup() to know which child to reap, not to gate startup.
# The old "kill the previous PID if alive" branch is now unreachable because the
# lock above would have refused, so the residual logic just resets a dead PID
# file from a crashed wrapper without sending signals.
PID_FILE="$HOME/.cache/che-telegram-all-mcp.pid"
mkdir -p "$(dirname "$PID_FILE")"

if [[ -f "$PID_FILE" ]]; then
    OLD_PID=
    read -r OLD_PID < "$PID_FILE" 2>/dev/null || true
    if [[ "$OLD_PID" =~ ^[0-9]+$ ]] && kill -0 "$OLD_PID" 2>/dev/null; then
        # If this branch fires, atomic claim above failed silently — investigate.
        # Retain the kill-old behavior as defense-in-depth, but log it.
        echo "$BINARY_NAME: warning — old PID $OLD_PID alive after lock claim succeeded; killing as defense-in-depth (#8)." >&2
        OLD_COMM=$(ps -p "$OLD_PID" -o comm= 2>/dev/null)
        OLD_BASENAME=$(basename "$OLD_COMM" 2>/dev/null)
        if [[ "$OLD_BASENAME" == "$BINARY_NAME" ]]; then
            kill -TERM "$OLD_PID" 2>/dev/null
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
    # Release atomic claim (#10). flock mode auto-releases on fd close;
    # mkdir mode needs explicit rmdir.
    if [[ "$LOCK_MODE" == "mkdir" ]] && [[ -d "$LOCK_DIR" ]]; then
        OWNER_PID=
        [ -f "$LOCK_DIR/owner.pid" ] && read -r OWNER_PID < "$LOCK_DIR/owner.pid" 2>/dev/null
        # Only release if we own it (avoid late trap deleting another wrapper's lock)
        [[ "$OWNER_PID" == "$$" ]] && rm -rf "$LOCK_DIR"
    fi
}
trap cleanup EXIT INT TERM

wait "$BIN_PID"
exit $?
