#!/bin/bash
# Auto-install and update check for che-apple-notes-mcp

BINARY_NAME="CheAppleNotesMCP"
INSTALL_PATH="$HOME/bin/$BINARY_NAME"
GITHUB_REPO="PsychQuant/che-apple-notes-mcp"
RELEASE_URL="https://github.com/$GITHUB_REPO/releases/latest/download/$BINARY_NAME"

LOCATIONS=(
    "$HOME/bin/$BINARY_NAME"
    "/usr/local/bin/$BINARY_NAME"
    "$HOME/.local/bin/$BINARY_NAME"
)

MCP_FOUND=false
MCP_PATH=""

for loc in "${LOCATIONS[@]}"; do
    if [[ -x "$loc" ]]; then
        MCP_FOUND=true
        MCP_PATH="$loc"
        break
    fi
done

get_latest_version() {
    curl -sI "https://github.com/$GITHUB_REPO/releases/latest" 2>/dev/null | \
        grep -i "^location:" | \
        sed -E 's|.*/v?([0-9]+\.[0-9]+\.[0-9]+).*|\1|' | \
        tr -d '\r\n'
}

install_binary() {
    echo "📦 Installing $BINARY_NAME..."
    mkdir -p "$HOME/bin"

    if curl -fsSL "$RELEASE_URL" -o "$INSTALL_PATH" 2>/dev/null; then
        chmod +x "$INSTALL_PATH"
        echo "✅ Installed $BINARY_NAME to $INSTALL_PATH"
        echo "   Run once: $INSTALL_PATH --setup   # for Automation + FDA guidance"
        return 0
    else
        echo "❌ Failed to download $BINARY_NAME"
        echo "   Manual install: $RELEASE_URL"
        return 1
    fi
}

if [[ "$MCP_FOUND" == "true" ]]; then
    INSTALLED_VERSION=$(timeout 2 "$MCP_PATH" --version 2>/dev/null | awk '{print $NF}' || true)
    LATEST_VERSION=$(get_latest_version)

    if [[ -n "$INSTALLED_VERSION" && -n "$LATEST_VERSION" ]]; then
        if [[ "$INSTALLED_VERSION" != "$LATEST_VERSION" ]]; then
            echo "⬆️  che-apple-notes-mcp v$INSTALLED_VERSION → v$LATEST_VERSION available"
            echo "   Update: curl -fsSL $RELEASE_URL -o $MCP_PATH && chmod +x $MCP_PATH"
        else
            echo "✓ che-apple-notes-mcp v$INSTALLED_VERSION (latest)"
        fi
    elif [[ -n "$INSTALLED_VERSION" ]]; then
        echo "✓ che-apple-notes-mcp v$INSTALLED_VERSION installed"
    else
        echo "✓ che-apple-notes-mcp installed: $MCP_PATH"
    fi
else
    echo "⚠️  che-apple-notes-mcp not found — install on first MCP call, or run:"
    echo "   curl -fsSL $RELEASE_URL -o $INSTALL_PATH && chmod +x $INSTALL_PATH"
fi
