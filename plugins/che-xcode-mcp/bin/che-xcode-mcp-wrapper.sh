#!/bin/bash
# Wrapper script to find and execute CheXcodeMCP binary
# Loads ASC credentials from ~/.appstoreconnect/config if env vars are empty

# --- Load credentials ---
CONFIG="$HOME/.appstoreconnect/config"
if [[ -f "$CONFIG" ]]; then
    # Only set vars that are empty (allow .mcp.json env to override)
    while IFS='=' read -r key value; do
        [[ "$key" =~ ^#.*$ || -z "$key" ]] && continue
        value="${value#\"}" && value="${value%\"}"  # strip quotes
        case "$key" in
            ASC_KEY_ID)         [[ -z "$ASC_KEY_ID" ]]         && export ASC_KEY_ID="$value" ;;
            ASC_ISSUER_ID)      [[ -z "$ASC_ISSUER_ID" ]]      && export ASC_ISSUER_ID="$value" ;;
            ASC_PRIVATE_KEY_PATH) [[ -z "$ASC_PRIVATE_KEY_PATH" ]] && export ASC_PRIVATE_KEY_PATH="$value" ;;
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

# Expand ~ in path
ASC_PRIVATE_KEY_PATH="${ASC_PRIVATE_KEY_PATH/#\~/$HOME}"
export ASC_PRIVATE_KEY_PATH

# --- Find and execute binary ---
LOCATIONS=(
    "$HOME/bin/CheXcodeMCP"
    "/usr/local/bin/CheXcodeMCP"
    "$HOME/.local/bin/CheXcodeMCP"
    "$HOME/Library/Application Support/Claude/mcp-servers/che-xcode-mcp/server/CheXcodeMCP"
)

for loc in "${LOCATIONS[@]}"; do
    if [[ -x "$loc" ]]; then
        # Fix Dropbox xattr causing macOS to block execution
        xattr -cr "$loc" 2>/dev/null
        codesign -s - -f "$loc" 2>/dev/null
        exec "$loc" "$@"
    fi
done

echo "ERROR: CheXcodeMCP binary not found!" >&2
echo "Please install from: https://github.com/kiki830621/che-xcode-mcp/releases" >&2
exit 1
