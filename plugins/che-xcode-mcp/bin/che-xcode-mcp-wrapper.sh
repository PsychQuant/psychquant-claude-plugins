#!/bin/bash
# Auto-download wrapper for CheXcodeMCP
# Also loads ASC credentials from ~/.appstoreconnect/config
REPO="kiki830621/che-xcode-mcp"
BINARY_NAME="CheXcodeMCP"
INSTALL_DIR="$HOME/bin"

# --- Load credentials ---
CONFIG="$HOME/.appstoreconnect/config"
if [[ -f "$CONFIG" ]]; then
    while IFS='=' read -r key value; do
        [[ "$key" =~ ^#.*$ || -z "$key" ]] && continue
        value="${value#\"}" && value="${value%\"}"
        case "$key" in
            ASC_KEY_ID)           [[ -z "$ASC_KEY_ID" ]]           && export ASC_KEY_ID="$value" ;;
            ASC_ISSUER_ID)        [[ -z "$ASC_ISSUER_ID" ]]        && export ASC_ISSUER_ID="$value" ;;
            ASC_PRIVATE_KEY_PATH) [[ -z "$ASC_PRIVATE_KEY_PATH" ]]  && export ASC_PRIVATE_KEY_PATH="$value" ;;
        esac
    done < "$CONFIG"
fi

if [[ -z "$ASC_KEY_ID" || -z "$ASC_ISSUER_ID" || -z "$ASC_PRIVATE_KEY_PATH" ]]; then
    echo "ERROR: ASC credentials not configured!" >&2
    echo "" >&2
    echo "Create ~/.appstoreconnect/config with:" >&2
    echo "  ASC_KEY_ID=YOUR_KEY_ID" >&2
    echo "  ASC_ISSUER_ID=YOUR_ISSUER_ID" >&2
    echo "  ASC_PRIVATE_KEY_PATH=~/.appstoreconnect/private_keys/AuthKey_XXXX.p8" >&2
    echo "" >&2
    echo "Get your API key from: https://appstoreconnect.apple.com/access/integrations/api" >&2
    exit 1
fi

ASC_PRIVATE_KEY_PATH="${ASC_PRIVATE_KEY_PATH/#\~/$HOME}"
export ASC_PRIVATE_KEY_PATH

# --- Find binary ---
BINARY=""
for loc in "$INSTALL_DIR/$BINARY_NAME" "/usr/local/bin/$BINARY_NAME" "$HOME/.local/bin/$BINARY_NAME"; do
    [[ -x "$loc" ]] && BINARY="$loc" && break
done

# --- Auto-download if not found ---
if [[ -z "$BINARY" ]]; then
    echo "$BINARY_NAME not found. Downloading from GitHub..." >&2
    mkdir -p "$INSTALL_DIR"
    URL=$(curl -sL "https://api.github.com/repos/$REPO/releases/latest" \
        | grep '"browser_download_url"' | grep "$BINARY_NAME" | head -1 \
        | sed 's/.*"\(https[^"]*\)".*/\1/')
    if [[ -z "$URL" ]]; then
        echo "ERROR: No download URL found. Install manually: https://github.com/$REPO/releases" >&2
        exit 1
    fi
    curl -sL "$URL" -o "$INSTALL_DIR/$BINARY_NAME" && chmod +x "$INSTALL_DIR/$BINARY_NAME" \
        || { echo "ERROR: Download failed." >&2; exit 1; }
    BINARY="$INSTALL_DIR/$BINARY_NAME"
    echo "Installed $BINARY_NAME to $INSTALL_DIR/" >&2
fi

exec "$BINARY" "$@"
