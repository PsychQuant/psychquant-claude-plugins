#!/bin/bash
# Session start check for che-zotero-mcp

BINARY_NAME="CheZoteroMCP"
KEYCHAIN_ACCOUNT="che-zotero-mcp"
REPO="kiki830621/che-zotero-mcp"

# Check binary
FOUND=false
for loc in "$HOME/bin/$BINARY_NAME" "/usr/local/bin/$BINARY_NAME"; do
    [[ -x "$loc" ]] && FOUND=true && break
done

if [[ "$FOUND" == "true" ]]; then
    # Check for updates
    LOCAL_VERSION=$("$loc" --version 2>/dev/null || echo "unknown")
    LATEST=$(curl -sL "https://api.github.com/repos/$REPO/releases/latest" 2>/dev/null \
        | grep '"tag_name"' | head -1 | sed 's/.*"v\([^"]*\)".*/\1/')
    if [[ -n "$LATEST" && "$LOCAL_VERSION" != "$LATEST" && "$LOCAL_VERSION" != "unknown" ]]; then
        echo "⬆️  $BINARY_NAME $LOCAL_VERSION → v$LATEST available"
        echo "   Update: curl -fsSL https://github.com/$REPO/releases/latest/download/$BINARY_NAME -o $HOME/bin/$BINARY_NAME && chmod +x $HOME/bin/$BINARY_NAME"
    fi
else
    echo "⚠️  $BINARY_NAME not found"
    echo "   Install: https://github.com/$REPO/releases"
fi

# Check Keychain
if ! security find-generic-password -a "$KEYCHAIN_ACCOUNT" -s "ZOTERO_API_KEY" -w &>/dev/null; then
    echo "⚠️  ZOTERO_API_KEY not in Keychain"
    echo "   Run: security add-generic-password -a \"$KEYCHAIN_ACCOUNT\" -s \"ZOTERO_API_KEY\" -w 'YOUR_KEY' -U"
fi
