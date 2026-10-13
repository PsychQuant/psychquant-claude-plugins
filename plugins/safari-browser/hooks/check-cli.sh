#!/bin/bash
# Check if safari-browser CLI is installed, and whether it is older than its source.
#
# che-ical-mcp compares `--version` with the latest GitHub release. safari-browser
# can't do that yet: the CLI has no --version, and fixes land on main long before a
# release is cut (the dialog-body fix #127 merged 2026-09-13; the latest release is
# still v2.6.0 from April). So the freshness signal here is source-based: the build
# time of ~/bin/safari-browser against the last commit that touched the code that
# gets compiled. No network, no auto-install over a working binary.

BINARY_NAME="safari-browser"
INSTALL_PATH="$HOME/bin/$BINARY_NAME"
SOURCE_DIR="$HOME/Developer/safari-browser"

print_install_hint() {
    echo "   Then, in $SOURCE_DIR:"
    echo "     make install                                  # ad-hoc signed"
    echo "     DEVELOPER_ID=<cert-sha1> make install-signed   # Developer ID signed"
    echo "   Use install-signed if you want history / bookmarks / cloud-tabs /"
    echo "   downloads: those need Full Disk Access, and an ad-hoc grant stops"
    echo "   applying after every rebuild (safari-browser#119)."
}

if [[ ! -x "$INSTALL_PATH" ]]; then
    echo "⚠️  $BINARY_NAME not found at $INSTALL_PATH"
    if [[ ! -d "$SOURCE_DIR" ]]; then
        echo "   Clone first:"
        echo "     git clone git@github.com:PsychQuant/safari-browser.git $SOURCE_DIR"
    fi
    print_install_hint
    exit 0
fi

echo "✓ $BINARY_NAME installed: $INSTALL_PATH"

# Freshness: only when the source checkout is there. Anything missing → stay silent.
if [[ -d "$SOURCE_DIR/.git" ]]; then
    # Last commit touching what the compiler reads (not docs/openspec/tests).
    SRC_LINE=$(git -C "$SOURCE_DIR" log -1 --format='%ct %h %s' -- Sources Package.swift Package.resolved 2>/dev/null)
    SRC_TS="${SRC_LINE%% *}"
    BIN_TS=$(stat -f %m "$INSTALL_PATH" 2>/dev/null)

    if [[ "$SRC_TS" =~ ^[0-9]+$ && "$BIN_TS" =~ ^[0-9]+$ && "$SRC_TS" -gt "$BIN_TS" ]]; then
        BIN_DATE=$(date -r "$BIN_TS" '+%Y-%m-%d %H:%M')
        SRC_DATE=$(date -r "$SRC_TS" '+%Y-%m-%d %H:%M')
        echo "⬆️  $BINARY_NAME binary is older than its source (binary $BIN_DATE, source $SRC_DATE)"
        echo "   Last code change: ${SRC_LINE#* }"
        echo "   Fixes merged since the build are not in the installed binary."
        print_install_hint
    fi
fi
