#!/bin/bash
# Check if safari-browser CLI is installed

BINARY_NAME="safari-browser"
INSTALL_PATH="$HOME/bin/$BINARY_NAME"
SOURCE_DIR="$HOME/Developer/safari-browser"

if [[ -x "$INSTALL_PATH" ]]; then
    echo "✓ $BINARY_NAME installed: $INSTALL_PATH"
else
    echo "⚠️  $BINARY_NAME not found at $INSTALL_PATH"
    if [[ -d "$SOURCE_DIR" ]]; then
        echo "   Build and install: cd $SOURCE_DIR && make install"
    else
        echo "   Clone and install:"
        echo "     git clone git@github.com:PsychQuant/safari-browser.git $SOURCE_DIR"
        echo "     cd $SOURCE_DIR && make install"
    fi
fi
