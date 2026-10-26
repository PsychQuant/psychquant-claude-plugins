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
# `git describe` of the commit it was built from. When that commit is in the history of
# the checkout's HEAD, the hook counts the commits since it that touch what the compiler
# reads, so a docs-only commit never makes the CLI "outdated".
#
# When the commit cannot be placed in that history, the hook says why and falls back to
# the file-time signal it always used: the build time of ~/bin/safari-browser against the
# last commit that touched the compiled code. That case is common, not exotic: this
# repository squash-merges, so a binary built from a PR branch can never become an
# ancestor of main, and stopping at "cannot compare" would mean never warning again.
# Binaries from before #278 (they reject `--version`) and builds without git (`unknown`)
# use the file-time signal directly.

BINARY_NAME="safari-browser"
INSTALL_PATH="$HOME/bin/$BINARY_NAME"
SOURCE_DIR="$HOME/Developer/safari-browser"
COMPILED_PATHS=(Sources Package.swift Package.resolved)

# The version probe's temp file and process group, cleaned up however the probe ends.
# read_version runs inside $(...), a subshell that inherits neither these variables'
# later values nor the traps, so it installs this cleanup itself.
PROBE_OUT=""
PROBE_PID=""
probe_cleanup() {
    [[ -n "$PROBE_PID" ]] && kill -KILL -- "-$PROBE_PID" 2>/dev/null
    [[ -n "$PROBE_OUT" ]] && rm -f "$PROBE_OUT"
    PROBE_PID=""
    PROBE_OUT=""
}

print_install_hint() {
    echo "   Then, in $SOURCE_DIR:"
    echo "     make install                                  # ad-hoc signed"
    echo "     DEVELOPER_ID=<cert-sha1> make install-signed   # Developer ID signed"
    echo "   Use install-signed if you want history / bookmarks / cloud-tabs /"
    echo "   downloads: those need Full Disk Access, and an ad-hoc grant stops"
    echo "   applying after every rebuild (safari-browser#119)."
}

# First line of `--version`, within about 4 seconds in the worst case (measured 3.9).
# This runs at every session start, so a binary that hangs must cost a few seconds and not
# the session. The probe gets a process group of its own (job control), so its children
# are stopped with it; TERM first, then KILL after half a second, because a child that
# ignores TERM would otherwise be waited for until it chose to exit. The group also
# carries its own 4-second deadline (a timer that KILLs the group), because having a group
# of its own means a SIGKILL sent to the hook's group no longer reaches it: if the hook is
# killed outright, nothing else would stop a hung probe. Prints nothing when the flag is
# rejected (a build from before #278), the binary fails, or it is too slow. Only the first
# 4 KiB are read: the answer is one short line, and the caller rejects anything longer.
# Call it with stderr discarded: bash reports a job it had to kill on stderr.
read_version() {
    local waited=0 grace=0
    trap probe_cleanup EXIT
    trap 'exit 1' INT TERM HUP
    PROBE_OUT=$(mktemp "${TMPDIR:-/tmp}/check-cli.XXXXXX") || return 1
    set -m
    /bin/sh -c '(sleep 4; kill -KILL 0) & exec "$0" --version' "$INSTALL_PATH" \
        >"$PROBE_OUT" 2>/dev/null </dev/null &
    PROBE_PID=$!
    set +m
    while kill -0 "$PROBE_PID" 2>/dev/null; do
        if (( waited >= 30 )); then
            kill -TERM -- "-$PROBE_PID" 2>/dev/null
            while kill -0 "$PROBE_PID" 2>/dev/null && (( grace < 5 )); do
                sleep 0.1
                grace=$((grace + 1))
            done
            kill -KILL -- "-$PROBE_PID" 2>/dev/null
            wait "$PROBE_PID" 2>/dev/null
            probe_cleanup
            return 1
        fi
        sleep 0.1
        waited=$((waited + 1))
    done
    if wait "$PROBE_PID"; then
        head -c 4096 "$PROBE_OUT" | head -n 1
    fi
    # The probe exited; anything it left running in its group goes with it.
    probe_cleanup
}

# Compare the commit the binary was built from with the checkout. Returns 1 (and says
# why) when the commit cannot be placed in the history of HEAD, so the caller can fall
# back to file times.
report_by_commit() {
    local commit count latest noun
    commit=$(git -C "$SOURCE_DIR" rev-parse --verify --quiet "$BUILD_REF^{commit}" 2>/dev/null) || {
        echo "ℹ️  $BINARY_NAME was built from $BUILD_REF, which is not in $SOURCE_DIR (built elsewhere, the checkout is behind, or the commit was squashed or rebased away): comparing file times instead."
        return 1
    }
    if ! git -C "$SOURCE_DIR" merge-base --is-ancestor "$commit" HEAD 2>/dev/null; then
        # The usual case: the binary was built from a PR branch that was then squash-merged
        # (or rebased) with the same code. Same compiled code as HEAD means nothing is newer.
        if git -C "$SOURCE_DIR" diff --quiet "$commit" HEAD -- "${COMPILED_PATHS[@]}" 2>/dev/null; then
            return 0
        fi
        if git -C "$SOURCE_DIR" merge-base --is-ancestor HEAD "$commit" 2>/dev/null; then
            echo "ℹ️  $BINARY_NAME was built from $BUILD_REF, which is newer than $SOURCE_DIR's HEAD (the checkout is behind): comparing file times instead."
        else
            echo "ℹ️  $BINARY_NAME was built from $BUILD_REF, which is not in the history of $SOURCE_DIR's HEAD (another branch, or a commit that was squash-merged, rebased or amended): comparing file times instead."
        fi
        return 1
    fi
    count=$(git -C "$SOURCE_DIR" rev-list --count "$commit..HEAD" -- "${COMPILED_PATHS[@]}" 2>/dev/null)
    [[ "$count" =~ ^[0-9]+$ ]] || return 0
    if (( count > 0 )); then
        noun="commit"
        (( count > 1 )) && noun="commits"
        latest=$(git -C "$SOURCE_DIR" log -1 --format='%h %s' -- "${COMPILED_PATHS[@]}" 2>/dev/null)
        echo "⬆️  $BINARY_NAME is behind its source: $count $noun touching the compiled code since this build ($VERSION)"
        echo "   Latest code change: $latest"
        if [[ "$VERSION" == *-dirty ]]; then
            echo "   The build had uncommitted changes, so some of these may already be in it."
        else
            echo "   Fixes merged since the build are not in the installed binary."
        fi
        print_install_hint
    fi
    return 0
}

# The signal for binaries that cannot say what they are, or whose commit cannot be placed.
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

# Plain text only, and short: the string is shown, and part of it becomes a git argument.
VERSION=$(read_version 2>/dev/null)
(( ${#VERSION} <= 128 )) || VERSION=""
[[ "$VERSION" =~ ^[A-Za-z0-9][A-Za-z0-9._+-]*$ ]] || VERSION=""

echo "✓ $BINARY_NAME installed: $INSTALL_PATH${VERSION:+ ($VERSION)}"

# Freshness: only when the source checkout is there. Anything missing → stay silent.
if [[ -d "$SOURCE_DIR/.git" ]]; then
    # What the binary was built from: a bare hash (no tag reachable at build time), or
    # `git describe` output. git resolves `<tag>-<n>-g<hash>` by the hash alone (the tag
    # name and the count are not consulted, so a tag the checkout lacks does not matter);
    # a plain `<tag>` (a build exactly on it) resolves only if the checkout has that tag.
    # `-dirty` only says the tree had edits; it names no other commit.
    BUILD_REF=""
    if [[ "$VERSION" =~ ^([0-9a-f]{7,40})(-dirty)?$ ]]; then
        BUILD_REF="${BASH_REMATCH[1]}"
    elif [[ "$VERSION" =~ ^v[0-9] ]]; then
        BUILD_REF="${VERSION%-dirty}"
    fi

    if [[ -z "$BUILD_REF" ]] || ! report_by_commit; then
        report_by_file_times
    fi
fi

exit 0
