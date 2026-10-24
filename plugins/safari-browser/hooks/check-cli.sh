#!/bin/bash
# Check if safari-browser CLI is installed, and whether it is older than its source.
#
# che-ical-mcp compares `--version` with the latest GitHub release. safari-browser
# can't do that: fixes land on main long before a release is cut (the dialog-body fix
# #127 merged 2026-09-13; the latest release was still v2.6.0 from April), so "the
# latest release" is the wrong yardstick here. The freshness signal is the source
# checkout instead. No network, no auto-install over a working binary.
#
# A binary built since safari-browser#278 can say what it is: `--version` prints
# `git describe` of the commit it was built from. That commit is compared with the
# checkout's history, counting only commits that touch what the compiler reads, so a
# docs-only commit never makes the CLI "outdated" and a different branch is not
# mistaken for an older one.
#
# Anything older than that (it rejects `--version`), or built without git (`unknown`),
# falls back to the file-time signal: the build time of ~/bin/safari-browser against the
# last commit that touched the code that gets compiled.

BINARY_NAME="safari-browser"
INSTALL_PATH="$HOME/bin/$BINARY_NAME"
SOURCE_DIR="$HOME/Developer/safari-browser"
COMPILED_PATHS=(Sources Package.swift Package.resolved)

print_install_hint() {
    echo "   Then, in $SOURCE_DIR:"
    echo "     make install                                  # ad-hoc signed"
    echo "     DEVELOPER_ID=<cert-sha1> make install-signed   # Developer ID signed"
    echo "   Use install-signed if you want history / bookmarks / cloud-tabs /"
    echo "   downloads: those need Full Disk Access, and an ad-hoc grant stops"
    echo "   applying after every rebuild (safari-browser#119)."
}

# First line of `--version`, within 3 seconds. This runs at every session start, so a
# binary that hangs must cost a few seconds and not the session. Prints nothing when
# the flag is rejected (a build from before #278), the binary fails, or it is too slow.
read_version() {
    local out pid waited=0
    out=$(mktemp "${TMPDIR:-/tmp}/check-cli.XXXXXX") || return 1
    "$INSTALL_PATH" --version >"$out" 2>/dev/null &
    pid=$!
    while kill -0 "$pid" 2>/dev/null; do
        if (( waited >= 30 )); then
            kill "$pid" 2>/dev/null
            wait "$pid" 2>/dev/null
            rm -f "$out"
            return 1
        fi
        sleep 0.1
        waited=$((waited + 1))
    done
    if wait "$pid"; then
        head -n 1 "$out"
    fi
    rm -f "$out"
}

# Compare the commit the binary was built from with the checkout. Says so, instead of
# guessing, when the two cannot be compared: a commit the checkout does not have (built
# elsewhere, or the checkout is behind) and a commit that is not an ancestor of HEAD
# (built from another branch) would both read as "older" or "newer" by file time alone.
report_by_commit() {
    local commit count latest noun
    commit=$(git -C "$SOURCE_DIR" rev-parse --verify --quiet "$BUILD_REF^{commit}" 2>/dev/null) || {
        echo "ℹ️  $BINARY_NAME was built from $BUILD_REF, which is not in $SOURCE_DIR (built elsewhere, or the checkout is behind): freshness not compared."
        return
    }
    if ! git -C "$SOURCE_DIR" merge-base --is-ancestor "$commit" HEAD 2>/dev/null; then
        echo "ℹ️  $BINARY_NAME was built from $BUILD_REF, which is not in the history of $SOURCE_DIR's current HEAD (another branch?): freshness not compared."
        return
    fi
    count=$(git -C "$SOURCE_DIR" rev-list --count "$commit..HEAD" -- "${COMPILED_PATHS[@]}" 2>/dev/null)
    [[ "$count" =~ ^[0-9]+$ ]] || return
    if (( count > 0 )); then
        noun="commit"
        (( count > 1 )) && noun="commits"
        latest=$(git -C "$SOURCE_DIR" log -1 --format='%h %s' -- "${COMPILED_PATHS[@]}" 2>/dev/null)
        echo "⬆️  $BINARY_NAME is behind its source: $count $noun touching the compiled code since this build ($VERSION)"
        echo "   Latest code change: $latest"
        echo "   Fixes merged since the build are not in the installed binary."
        print_install_hint
    fi
}

# The signal for binaries that cannot say what they are.
report_by_file_times() {
    local src_line src_ts bin_ts bin_date src_date
    # Last commit touching what the compiler reads (not docs/openspec/tests).
    src_line=$(git -C "$SOURCE_DIR" log -1 --format='%ct %h %s' -- "${COMPILED_PATHS[@]}" 2>/dev/null)
    src_ts="${src_line%% *}"
    bin_ts=$(stat -f %m "$INSTALL_PATH" 2>/dev/null)

    if [[ "$src_ts" =~ ^[0-9]+$ && "$bin_ts" =~ ^[0-9]+$ && "$src_ts" -gt "$bin_ts" ]]; then
        bin_date=$(date -r "$bin_ts" '+%Y-%m-%d %H:%M')
        src_date=$(date -r "$src_ts" '+%Y-%m-%d %H:%M')
        echo "⬆️  $BINARY_NAME binary is older than its source (binary $bin_date, source $src_date)"
        echo "   Last code change: ${src_line#* }"
        echo "   Fixes merged since the build are not in the installed binary."
        print_install_hint
    fi
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

# Plain text only: the string is shown, and part of it becomes a git argument.
VERSION=$(read_version)
[[ "$VERSION" =~ ^[A-Za-z0-9][A-Za-z0-9._+-]*$ ]] || VERSION=""

echo "✓ $BINARY_NAME installed: $INSTALL_PATH${VERSION:+ ($VERSION)}"

# Freshness: only when the source checkout is there. Anything missing → stay silent.
if [[ -d "$SOURCE_DIR/.git" ]]; then
    # What the binary was built from: a bare hash (no tag reachable at build time), or
    # `git describe` output (`v1.2.3`, `v1.2.3-4-gabc1234`) which git resolves itself,
    # by the hash after `-g` and even when the checkout lacks the tag (gitrevisions(7),
    # <describeOutput>). `-dirty` only says the tree had edits; it names no other commit.
    BUILD_REF=""
    if [[ "$VERSION" =~ ^([0-9a-f]{7,40})(-dirty)?$ ]]; then
        BUILD_REF="${BASH_REMATCH[1]}"
    elif [[ "$VERSION" =~ ^v[0-9] ]]; then
        BUILD_REF="${VERSION%-dirty}"
    fi

    if [[ -n "$BUILD_REF" ]]; then
        report_by_commit
    else
        report_by_file_times
    fi
fi

exit 0
