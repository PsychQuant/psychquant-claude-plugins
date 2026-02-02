#!/bin/bash
# Wrapper script to find and execute che-apple-mail-mcp binary
# This allows the plugin to work regardless of where the binary is installed

# Possible installation locations (in priority order)
LOCATIONS=(
    "$HOME/bin/CheAppleMailMCP"
    "/usr/local/bin/che-apple-mail-mcp"
    "/usr/local/bin/CheAppleMailMCP"
    "$HOME/.local/bin/CheAppleMailMCP"
    # MCPB installation location (Claude Desktop)
    "$HOME/Library/Application Support/Claude/mcp-servers/che-apple-mail-mcp/server/CheAppleMailMCP"
)

for loc in "${LOCATIONS[@]}"; do
    if [[ -x "$loc" ]]; then
        exec "$loc" "$@"
    fi
done

# Not found - output error to stderr (MCP protocol requirement)
echo "ERROR: CheAppleMailMCP binary not found!" >&2
echo "Please install from: https://github.com/kiki830621/che-apple-mail-mcp/releases" >&2
exit 1
