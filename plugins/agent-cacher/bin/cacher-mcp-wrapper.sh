#!/bin/bash
# cacher-mcp-wrapper.sh — auto-installs `cacher` CLI + `cacher-mcp` MCP server
# from PsychQuant/agent-cacher GitHub Release, then execs the MCP server.
#
# Auto-upgrade design (mirrors che-telegram-mcp-wrapper):
# - DESIRED_VERSION pins the binary version this plugin expects.
# - Sidecar version files at ~/bin/.{cacher,cacher-mcp}.version track installs.
# - On version mismatch, re-downloads (atomic .tmp + mv).
# - Source builds (.build/release/...) are NEVER auto-replaced.

GITHUB_REPO="PsychQuant/agent-cacher"
INSTALL_DIR="$HOME/bin"
DESIRED_VERSION="0.1.0"
DOWNLOAD_TIMEOUT=120

mkdir -p "$INSTALL_DIR"

ensure_binary() {
    local binary_name="$1"
    local installed="$INSTALL_DIR/$binary_name"
    local version_file="$INSTALL_DIR/.${binary_name}.version"
    local installed_version=""
    [[ -f "$version_file" ]] && installed_version=$(tr -d '[:space:]' < "$version_file" 2>/dev/null || true)

    # Search order: ~/bin (install target) > /usr/local/bin > source builds (never overwritten)
    local found=""
    for loc in \
        "$installed" \
        "/usr/local/bin/$binary_name" \
        "$HOME/.local/bin/$binary_name" \
        "$HOME/Developer/agent-cacher/.build/release/$binary_name" \
        "$HOME/Developer/agent-cacher/.build/debug/$binary_name"
    do
        [[ -x "$loc" ]] && { found="$loc"; break; }
    done

    local need_download=false
    if [[ -z "$found" ]]; then
        need_download=true
    elif [[ "$found" == "$installed" ]] && [[ "$installed_version" != "$DESIRED_VERSION" ]]; then
        need_download=true
    fi

    if $need_download; then
        local asset_url="https://github.com/${GITHUB_REPO}/releases/download/v${DESIRED_VERSION}/${binary_name}-arm64-macos"
        local tmp="${installed}.tmp.$$"
        echo "agent-cacher: downloading ${binary_name} v${DESIRED_VERSION} from ${asset_url}" >&2
        if ! curl --fail --location --silent --show-error --max-time "$DOWNLOAD_TIMEOUT" \
                -o "$tmp" "$asset_url"; then
            echo "agent-cacher: failed to download ${binary_name}; bailing" >&2
            rm -f "$tmp"
            return 1
        fi
        chmod +x "$tmp"
        mv "$tmp" "$installed"
        printf "%s" "$DESIRED_VERSION" > "$version_file"
        found="$installed"
    fi

    printf "%s" "$found"
}

CACHER_PATH=$(ensure_binary cacher) || exit 1
MCP_PATH=$(ensure_binary cacher-mcp) || exit 1

# Both binaries now present. Hand off to the MCP server. cacher-mcp reads
# AGENT_CACHER_DB_PATH for the DB location (see Sources/AgentCacherMCP/CacherMCP.swift).
exec "$MCP_PATH" "$@"
