#!/bin/bash
# Wrapper script to find and execute CheXcodeMCP binary

LOCATIONS=(
    "$HOME/bin/CheXcodeMCP"
    "/usr/local/bin/CheXcodeMCP"
    "$HOME/.local/bin/CheXcodeMCP"
    "$HOME/Library/Application Support/Claude/mcp-servers/che-xcode-mcp/server/CheXcodeMCP"
)

for loc in "${LOCATIONS[@]}"; do
    if [[ -x "$loc" ]]; then
        exec "$loc" "$@"
    fi
done

echo "ERROR: CheXcodeMCP binary not found!" >&2
echo "Please install from: https://github.com/kiki830621/che-xcode-mcp/releases" >&2
exit 1
