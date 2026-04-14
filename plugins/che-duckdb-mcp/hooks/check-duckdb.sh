#!/bin/bash
# Session start check for che-duckdb-mcp

BINARY_NAME="CheDuckDBMCP"
REPO="PsychQuant/che-duckdb-mcp"

FOUND=""
for loc in "$HOME/bin/$BINARY_NAME" "/usr/local/bin/$BINARY_NAME" "$HOME/.local/bin/$BINARY_NAME"; do
    if [[ -x "$loc" ]]; then
        FOUND="$loc"
        break
    fi
done

if [[ -n "$FOUND" ]]; then
    LOCAL_VERSION=$(timeout 2 "$FOUND" --version 2>/dev/null | awk '{print $NF}')
    LATEST=$(curl -sL --max-time 3 "https://api.github.com/repos/$REPO/releases/latest" 2>/dev/null \
        | grep '"tag_name"' | head -1 | sed 's/.*"v\{0,1\}\([^"]*\)".*/\1/')
    if [[ -n "$LATEST" && -n "$LOCAL_VERSION" && "$LOCAL_VERSION" != "$LATEST" ]]; then
        NEWER=$(printf '%s\n%s\n' "$LOCAL_VERSION" "$LATEST" | sort -V | tail -1)
        if [[ "$NEWER" == "$LATEST" ]]; then
            echo "⬆️  $BINARY_NAME $LOCAL_VERSION → v$LATEST available"
            echo "   Update: curl -fsSL https://github.com/$REPO/releases/latest/download/$BINARY_NAME -o $HOME/bin/$BINARY_NAME && chmod +x $HOME/bin/$BINARY_NAME"
        fi
    fi
else
    echo "⚠️  $BINARY_NAME not found — wrapper.sh will auto-download on first MCP call"
    echo "   Manual install: https://github.com/$REPO/releases"
fi
