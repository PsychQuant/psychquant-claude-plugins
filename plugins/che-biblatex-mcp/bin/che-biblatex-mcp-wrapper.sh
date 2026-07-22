#!/bin/bash
# Version-aware auto-download wrapper for akashic-mcp.
# Repo 為 private：優先 gh CLI（使用者認證）下載，公開後 curl fallback 自動可用。
set -u

REPO="kiki830621/che-biblatex-mcp"
BINARY_NAME="CheBiblatexMCP"
ASSET_NAME="CheBiblatexMCP"
INSTALL_DIR="$HOME/bin"
BINARY="$INSTALL_DIR/$BINARY_NAME"
VERSION_FILE="$INSTALL_DIR/.${BINARY_NAME}.version"

PLUGIN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PLUGIN_JSON="$PLUGIN_ROOT/.claude-plugin/plugin.json"

DESIRED_VERSION=""
if [[ -f "$PLUGIN_JSON" ]]; then
    DESIRED_VERSION=$(grep -oE '"version":[[:space:]]*"[^"]+"' "$PLUGIN_JSON" 2>/dev/null \
        | head -1 | cut -d'"' -f4 || true)
fi
INSTALLED_VERSION=""
[[ -f "$VERSION_FILE" ]] && INSTALLED_VERSION=$(tr -d '[:space:]' < "$VERSION_FILE" 2>/dev/null || true)

NEED_DOWNLOAD=false
if [[ ! -x "$BINARY" ]]; then
    NEED_DOWNLOAD=true
elif [[ -n "$DESIRED_VERSION" ]] && [[ "$INSTALLED_VERSION" != "$DESIRED_VERSION" ]]; then
    NEED_DOWNLOAD=true
fi

if $NEED_DOWNLOAD; then
    echo "$BINARY_NAME: downloading v${DESIRED_VERSION:-latest} from $REPO..." >&2
    mkdir -p "$INSTALL_DIR"
    TAG="v${DESIRED_VERSION}"
    TMP_DIR="$(mktemp -d)"
    OK=false
    if command -v gh >/dev/null 2>&1; then
        if gh release download "$TAG" --repo "$REPO" --pattern "$ASSET_NAME" \
             --dir "$TMP_DIR" 2>/dev/null \
           || gh release download --repo "$REPO" --pattern "$ASSET_NAME" \
                --dir "$TMP_DIR" 2>/dev/null; then
            OK=true
        fi
    fi
    if ! $OK; then
        URL="https://github.com/$REPO/releases/download/$TAG/$ASSET_NAME"
        curl -sL --max-time 120 -o "$TMP_DIR/$ASSET_NAME" "$URL" 2>/dev/null \
          && file "$TMP_DIR/$ASSET_NAME" 2>/dev/null | grep -q "Mach-O" && OK=true
    fi
    if $OK && [[ -s "$TMP_DIR/$ASSET_NAME" ]]; then
        chmod +x "$TMP_DIR/$ASSET_NAME"
        mv "$TMP_DIR/$ASSET_NAME" "$BINARY"
        echo "${DESIRED_VERSION:-unknown}" > "$VERSION_FILE"
        echo "$BINARY_NAME: installed v${DESIRED_VERSION:-latest}" >&2
    else
        rm -rf "$TMP_DIR"
        if [[ -x "$BINARY" ]]; then
            echo "$BINARY_NAME: WARNING — download failed, keeping existing binary" >&2
        else
            echo "$BINARY_NAME: ERROR — download failed（private repo 需 gh auth login）" >&2
            exit 1
        fi
    fi
    rm -rf "$TMP_DIR" 2>/dev/null
fi

exec "$BINARY" "$@"
