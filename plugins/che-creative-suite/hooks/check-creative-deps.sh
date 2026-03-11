#!/bin/bash
# Dependency check for che-creative-suite
# Only CHECKS if binaries exist — does NOT auto-install

INSTALL_DIR="$HOME/bin"

check_binary() {
    local BINARY_NAME="$1"
    local DISPLAY_NAME="$2"

    for loc in "$INSTALL_DIR/$BINARY_NAME" "/usr/local/bin/$BINARY_NAME" "$HOME/.local/bin/$BINARY_NAME"; do
        if [[ -x "$loc" ]]; then
            echo "OK $DISPLAY_NAME ($loc)"
            return 0
        fi
    done

    echo "MISSING $DISPLAY_NAME — install: /mcp-tools:mcp-deploy in the $DISPLAY_NAME project directory"
    return 1
}

SVG_OK=true
PIXEL_OK=true

check_binary "CheSvgMCP" "che-svg-mcp" || SVG_OK=false
check_binary "ChePixelMCP" "che-pixel-mcp" || PIXEL_OK=false

if [[ "$SVG_OK" == "true" && "$PIXEL_OK" == "true" ]]; then
    echo "Creative Suite ready"
elif [[ "$SVG_OK" == "true" ]]; then
    echo "Creative Suite partial: SVG only"
elif [[ "$PIXEL_OK" == "true" ]]; then
    echo "Creative Suite partial: Pixel only"
else
    echo "Creative Suite: no servers installed"
fi
