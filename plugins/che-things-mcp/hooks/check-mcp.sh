#!/bin/bash
# Auto-install and update check for che-things-mcp

BINARY_NAME="CheThingsMCP"
INSTALL_PATH="$HOME/bin/$BINARY_NAME"
GITHUB_REPO="kiki830621/che-things-mcp"
RELEASE_URL="https://github.com/$GITHUB_REPO/releases/latest/download/$BINARY_NAME"

# Possible installation locations
LOCATIONS=(
    "$HOME/bin/$BINARY_NAME"
    "/usr/local/bin/che-things-mcp"
    "/usr/local/bin/$BINARY_NAME"
    "$HOME/.local/bin/$BINARY_NAME"
)

MCP_FOUND=false
MCP_PATH=""

# Check for existing installation
for loc in "${LOCATIONS[@]}"; do
    if [[ -x "$loc" ]]; then
        MCP_FOUND=true
        MCP_PATH="$loc"
        break
    fi
done

# Function to get latest version from GitHub
get_latest_version() {
    curl -sI "https://github.com/$GITHUB_REPO/releases/latest" 2>/dev/null | \
        grep -i "^location:" | \
        sed -E 's|.*/v?([0-9]+\.[0-9]+\.[0-9]+).*|\1|' | \
        tr -d '\r\n'
}

# Function to install binary
install_binary() {
    echo "📦 Installing $BINARY_NAME..."
    mkdir -p "$HOME/bin"

    if curl -fsSL "$RELEASE_URL" -o "$INSTALL_PATH" 2>/dev/null; then
        chmod +x "$INSTALL_PATH"
        echo "✅ Installed $BINARY_NAME to $INSTALL_PATH"

        # Register with Claude if not already
        if command -v claude &> /dev/null; then
            if ! claude mcp list 2>/dev/null | grep -q "che-things-mcp"; then
                claude mcp add --scope user che-things-mcp -- "$INSTALL_PATH" 2>/dev/null || true
                echo "✅ Registered with Claude Code"
            fi
        fi
        return 0
    else
        echo "❌ Failed to download $BINARY_NAME"
        echo "   Manual install: $RELEASE_URL"
        return 1
    fi
}

if [[ "$MCP_FOUND" == "true" ]]; then
    # Get installed version
    INSTALLED_VERSION=$(timeout 2 "$MCP_PATH" --version 2>/dev/null | awk '{print $NF}' || true)

    # Get latest version
    LATEST_VERSION=$(get_latest_version)

    if [[ -n "$INSTALLED_VERSION" && -n "$LATEST_VERSION" ]]; then
        if [[ "$INSTALLED_VERSION" != "$LATEST_VERSION" ]]; then
            echo "⬆️  che-things-mcp v$INSTALLED_VERSION → v$LATEST_VERSION available"
            # rm first: overwriting a binary a running process holds open leaves a stale code-signature cache
            echo "   Update: rm -f $MCP_PATH && curl -fsSL $RELEASE_URL -o $MCP_PATH && chmod +x $MCP_PATH"
        else
            echo "✓ che-things-mcp v$INSTALLED_VERSION (latest)"
        fi
    elif [[ -n "$INSTALLED_VERSION" ]]; then
        echo "✓ che-things-mcp v$INSTALLED_VERSION installed"
    else
        echo "✓ che-things-mcp installed: $MCP_PATH"
    fi
else
    # Check if registered via claude mcp (might be using different path)
    if command -v claude &> /dev/null; then
        if claude mcp list 2>/dev/null | grep -q "che-things-mcp"; then
            echo "✓ che-things-mcp registered (via claude mcp)"
            exit 0
        fi
    fi

    # Not found - auto install
    echo "⚠️  che-things-mcp not found - installing automatically..."
    install_binary
fi
