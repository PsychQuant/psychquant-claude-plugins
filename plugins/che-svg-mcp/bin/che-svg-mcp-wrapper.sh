#!/bin/bash
# Auto-download wrapper for CheSvgMCP
REPO="PsychQuant/che-svg-mcp"
BINARY_NAME="CheSvgMCP"
INSTALL_DIR="$HOME/bin"

BINARY=""
for loc in "$INSTALL_DIR/$BINARY_NAME" "/usr/local/bin/$BINARY_NAME" "$HOME/.local/bin/$BINARY_NAME"; do
    [[ -x "$loc" ]] && BINARY="$loc" && break
done

if [[ -z "$BINARY" ]]; then
    echo "$BINARY_NAME not found. Downloading from GitHub..." >&2
    mkdir -p "$INSTALL_DIR"
    if command -v gh &>/dev/null; then
        gh release download --repo "$REPO" --pattern "$BINARY_NAME" --dir "$INSTALL_DIR" --clobber 2>&2 \
            && chmod +x "$INSTALL_DIR/$BINARY_NAME"
    else
        echo "ERROR: gh CLI not found. Install with: brew install gh" >&2
        echo "Then run: gh release download --repo $REPO --pattern $BINARY_NAME --dir $INSTALL_DIR" >&2
        exit 1
    fi
    if [[ ! -x "$INSTALL_DIR/$BINARY_NAME" ]]; then
        echo "ERROR: Download failed. Install manually: https://github.com/$REPO/releases" >&2
        exit 1
    fi
    BINARY="$INSTALL_DIR/$BINARY_NAME"
    echo "Installed $BINARY_NAME to $INSTALL_DIR/" >&2
fi

exec "$BINARY" "$@"
