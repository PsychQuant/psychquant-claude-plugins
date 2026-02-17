#!/bin/bash
# Wrapper script for CheXcodeMCP MCP Server
# - Auto-downloads binary from GitHub Release if not found
# - Loads ASC credentials from ~/.appstoreconnect/config

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

# --- Validate credentials ---
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
LOCATIONS=(
    "$INSTALL_DIR/$BINARY_NAME"
    "/usr/local/bin/$BINARY_NAME"
    "$HOME/.local/bin/$BINARY_NAME"
)

for loc in "${LOCATIONS[@]}"; do
    if [[ -x "$loc" ]]; then
        BINARY="$loc"
        break
    fi
done

# --- Auto-download if not found ---
if [[ -z "$BINARY" ]]; then
    echo "CheXcodeMCP not found. Downloading from GitHub..." >&2
    mkdir -p "$INSTALL_DIR"

    DOWNLOAD_URL=$(curl -sL "https://api.github.com/repos/$REPO/releases/latest" \
        | grep '"browser_download_url"' \
        | grep "$BINARY_NAME" \
        | head -1 \
        | sed 's/.*"browser_download_url": *"\(.*\)".*/\1/')

    if [[ -z "$DOWNLOAD_URL" ]]; then
        echo "ERROR: Could not find download URL from GitHub Release." >&2
        echo "Install manually: https://github.com/$REPO/releases" >&2
        exit 1
    fi

    curl -sL "$DOWNLOAD_URL" -o "$INSTALL_DIR/$BINARY_NAME" 2>&1 >&2
    if [[ $? -ne 0 ]]; then
        echo "ERROR: Download failed." >&2
        exit 1
    fi

    chmod +x "$INSTALL_DIR/$BINARY_NAME"
    BINARY="$INSTALL_DIR/$BINARY_NAME"
    echo "Installed $BINARY_NAME to $INSTALL_DIR/" >&2
fi

# --- Fix Dropbox xattr + ad-hoc sign ---
xattr -cr "$BINARY" 2>/dev/null
codesign -s - -f "$BINARY" 2>/dev/null

exec "$BINARY" "$@"
