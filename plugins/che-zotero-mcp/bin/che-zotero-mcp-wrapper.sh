#!/bin/bash
# Auto-download wrapper for CheZoteroMCP
# Reads ZOTERO_API_KEY from macOS Keychain
REPO="kiki830621/che-zotero-mcp"
BINARY_NAME="CheZoteroMCP"
INSTALL_DIR="$HOME/bin"
KEYCHAIN_ACCOUNT="che-zotero-mcp"

# Find binary
BINARY=""
for loc in "$INSTALL_DIR/$BINARY_NAME" "/usr/local/bin/$BINARY_NAME" "$HOME/.local/bin/$BINARY_NAME"; do
    [[ -x "$loc" ]] && BINARY="$loc" && break
done

if [[ -z "$BINARY" ]]; then
    echo "$BINARY_NAME not found. Downloading from GitHub..." >&2
    mkdir -p "$INSTALL_DIR"
    URL=$(curl -sL "https://api.github.com/repos/$REPO/releases/latest" \
        | grep '"browser_download_url"' | grep "$BINARY_NAME" | head -1 \
        | sed 's/.*"\(https[^"]*\)".*/\1/')
    if [[ -n "$URL" ]]; then
        curl -sL "$URL" -o "$INSTALL_DIR/$BINARY_NAME" && chmod +x "$INSTALL_DIR/$BINARY_NAME" \
            || { echo "ERROR: Download failed." >&2; exit 1; }
        BINARY="$INSTALL_DIR/$BINARY_NAME"
        echo "Installed $BINARY_NAME to $INSTALL_DIR/" >&2
    else
        echo "No release found. Build from source: https://github.com/$REPO" >&2
        exit 1
    fi
fi

# Read credentials from macOS Keychain
export ZOTERO_API_KEY="$(security find-generic-password -a "$KEYCHAIN_ACCOUNT" -s "ZOTERO_API_KEY" -w 2>/dev/null)"

if [[ -z "$ZOTERO_API_KEY" ]]; then
    echo "ZOTERO_API_KEY not found in Keychain. Set it up:" >&2
    echo "  security add-generic-password -a \"$KEYCHAIN_ACCOUNT\" -s \"ZOTERO_API_KEY\" -w 'YOUR_KEY' -U" >&2
    exit 1
fi

exec "$BINARY" "$@"
