#!/bin/bash
# Mutation test for tests/che-archive-lines/test-plugin-layout.sh (#139).
#
# Each case copies the plugin into a scratch tree, breaks ONE thing, and
# asserts the layout test catches it with the RIGHT check — including that a
# missing skill fails the checks that read it instead of passing them. The real
# repo is never modified. Portable: perl -pi, not BSD-only `sed -i ''`.
#
# Usage:
#   bash tests/che-archive-lines/test-plugin-layout-mutations.sh

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_PLUGIN="$(cd "$SCRIPT_DIR/../../plugins/che-archive-lines" && pwd)"
LAYOUT_TEST="$SCRIPT_DIR/test-plugin-layout.sh"
SCRATCH=$(mktemp -d "${TMPDIR:-/tmp}/archive-lines-mutations-XXXXXX") || {
    echo "✗ mktemp failed — cannot create a scratch tree" >&2
    exit 1
}
[ -n "$SCRATCH" ] && [ -d "$SCRATCH" ] || { echo "✗ scratch dir missing" >&2; exit 1; }
trap 'rm -rf "$SCRATCH"' EXIT

PASSED=0
FAILED=0

fresh() {
    rm -rf "$SCRATCH/tree"
    mkdir -p "$SCRATCH/tree/tests/che-archive-lines" "$SCRATCH/tree/plugins"
    cp -R "$SRC_PLUGIN" "$SCRATCH/tree/plugins/che-archive-lines"
    cp "$LAYOUT_TEST" "$SCRATCH/tree/tests/che-archive-lines/"
    echo "$SCRATCH/tree/plugins/che-archive-lines"
}
run_layout() { bash "$SCRATCH/tree/tests/che-archive-lines/test-plugin-layout.sh" 2>&1; }
expect_fail() {
    local name="$1" pattern="$2" out rc
    out=$(run_layout); rc=$?
    if [ "$rc" -ne 0 ] && printf '%s\n' "$out" | grep -qE "$pattern"; then
        echo "  ✓ $name"; PASSED=$((PASSED + 1))
    else
        echo "  ✗ $name (exit $rc; expected /$pattern/)"
        printf '%s\n' "$out" | sed 's/^/      /'; FAILED=$((FAILED + 1))
    fi
}
expect_pass() {
    local name="$1" out rc
    out=$(run_layout); rc=$?
    if [ "$rc" -eq 0 ]; then
        echo "  ✓ $name"; PASSED=$((PASSED + 1))
    else
        echo "  ✗ $name (exit $rc, expected pass)"
        printf '%s\n' "$out" | sed 's/^/      /'; FAILED=$((FAILED + 1))
    fi
}
add_bom() { python3 -c 'import sys;p=sys.argv[1];b=open(p,"rb").read();open(p,"wb").write(b"\xef\xbb\xbf"+b)' "$1"; }
set_allowed() {  # $1 = file, $2 = replacement for the whole allowed-tools line
    ALLOWED_LINE="$2" perl -pi -e 's/^allowed-tools:.*$/$ENV{ALLOWED_LINE}/' "$1"
}
set_dmi() {  # $1 = file, $2 = replacement for the whole disable-model-invocation line
    DMI_LINE="$2" perl -pi -e 's/^disable-model-invocation:.*$/$ENV{DMI_LINE}/' "$1"
}
SKILL=skills/archive-lines/SKILL.md
RULE='Bash(${CLAUDE_PLUGIN_ROOT}/scripts/line-save-chat.sh *)'
SAVE_CMD='"${CLAUDE_PLUGIN_ROOT}/scripts/line-save-chat.sh" save'
replace_save() {  # $1 = file, $2 = replacement for the save invocation
    FROM="$SAVE_CMD" TO="$2" perl -pi -e 's/\Q$ENV{FROM}\E/$ENV{TO}/' "$1"
}

echo "test-plugin-layout-mutations.sh (#139)"

P=$(fresh); expect_pass "unmodified copy passes"
P=$(fresh); add_bom "$P/$SKILL"
expect_pass "UTF-8 BOM on the skill is accepted"
P=$(fresh); set_allowed "$P/$SKILL" "allowed-tools:
  - $RULE"
expect_pass "allowed-tools as a YAML list with the same rule is accepted"

P=$(fresh); perl -0pi -e 's/\A---\n/---\nallowed-tools: [Read\n/' "$P/$SKILL"
expect_fail "broken YAML fails closed" "parser crashed"

P=$(fresh); mkdir -p "$P/commands"; printf -- '---\ndescription: x\n---\n' > "$P/commands/archive-lines.md"
expect_fail "commands/ reappears" "FAIL \(a\)"

P=$(fresh); rm "$P/$SKILL"
expect_fail "skill deleted: (b) fails" "FAIL \(b\)"
expect_fail "skill deleted: (e) does not pass silently" "FAIL \(e\)"
expect_fail "skill deleted: (f) does not pass silently" "FAIL \(f\)"
expect_fail "skill deleted: (n) does not pass silently" "FAIL \(n\)"

P=$(fresh); chmod -x "$P/scripts/line-save-chat.sh"
expect_fail "script not executable" "FAIL \(b\)"

# ---- (b)/(c): every invocation, every spelling ----
P=$(fresh); replace_save "$P/$SKILL" './scripts/line-save-chat.sh save'
expect_fail "relative ./scripts/ path" "FAIL \(b\)"
P=$(fresh); replace_save "$P/$SKILL" 'bash scripts/line-save-chat.sh save'
expect_fail "relative scripts/ path without ./" "FAIL \(b\)"
P=$(fresh); replace_save "$P/$SKILL" '"$CLAUDE_PLUGIN_ROOT/scripts/line-save-chat.sh" save'
expect_fail "unbraced \$CLAUDE_PLUGIN_ROOT" "FAIL \(c\)"
P=$(fresh); printf '\nSCRIPT_DIR="$(dirname "$0")"\n' >> "$P/$SKILL"
expect_fail "\$(dirname \"\$0\") derivation" "FAIL \(c\)"
P=$(fresh); printf '\nSCRIPT_DIR="${0%%/*}/scripts"\n' >> "$P/$SKILL"
expect_fail "\${0%%/*} derivation" "FAIL \(c\)"

# ---- (d): per-machine paths, including files that are not valid UTF-8 ----
P=$(fresh); printf '\nSee /Users/example/notes for details.\n' >> "$P/README.md"
expect_fail "home-directory path in README" "FAIL \(d\)"
P=$(fresh); printf '\nScript: ~/Library/CloudStorage/Dropbox/x/run.sh\n' >> "$P/$SKILL"
expect_fail "CloudStorage path in the skill" "FAIL \(d\)"
P=$(fresh); printf '\nScript: ~/Dropbox/che_workspace/x/run.sh\n' >> "$P/README.md"
expect_fail "legacy ~/Dropbox path" "FAIL \(d\)"
P=$(fresh); printf '\nScript: ~/Library/Mobile Documents/com~apple~CloudDocs/x.sh\n' >> "$P/README.md"
expect_fail "iCloud Drive path" "FAIL \(d\)"
P=$(fresh); printf '\n\xff /Users/example/secret/\n' >> "$P/README.md"
expect_fail "home path in a file that is not valid UTF-8" "FAIL \(d\)"

# ---- (e): exactly the one anchored rule ----
P=$(fresh); set_allowed "$P/$SKILL" 'allowed-tools: Bash(*), Read, Write, Glob'
expect_fail "allowed-tools back to Bash(*)" "FAIL \(e\)"
P=$(fresh); set_allowed "$P/$SKILL" "allowed-tools: $RULE Read"
expect_fail "bare Read added next to the rule" "FAIL \(e\)"
P=$(fresh); set_allowed "$P/$SKILL" 'allowed-tools: Bash(bash *line-save-chat.sh *)'
expect_fail "leading-wildcard rule (also matches bash -c)" "FAIL \(e\)"
P=$(fresh); set_allowed "$P/$SKILL" "\"allowed-tools\":
  - $RULE

  - Write"
expect_fail "quoted key + blank line hides Write" "FAIL \(e\)"
P=$(fresh); set_allowed "$P/$SKILL" 'allowed-tools: Bash(*)'; add_bom "$P/$SKILL"
expect_fail "BOM does not hide Bash(*)" "FAIL \(e\)"

# ---- (f): only the literal true; the frontmatter boundary Claude Code uses ----
P=$(fresh); perl -ni -e 'print unless /^disable-model-invocation:/' "$P/$SKILL"
expect_fail "disable-model-invocation removed" "FAIL \(f\)"
P=$(fresh); set_dmi "$P/$SKILL" 'disable-model-invocation: false # temporarily'
expect_fail "disable-model-invocation false with a comment" "FAIL \(f\)"
P=$(fresh); set_dmi "$P/$SKILL" 'disable-model-invocation: 1'
expect_fail "disable-model-invocation: 1" "FAIL \(f\)"
P=$(fresh); set_dmi "$P/$SKILL" 'disable-model-invocation: yes'
expect_fail "disable-model-invocation: yes" "FAIL \(f\)"
P=$(fresh); set_dmi "$P/$SKILL" 'disable-model-invocation: "true"'
expect_fail "disable-model-invocation: \"true\" (quoted)" "FAIL \(f\)"
P=$(fresh); perl -pi -e 's/^description: /description: LINE --- /' "$P/$SKILL"
expect_fail "--- inside a value ends the frontmatter early (as in Claude Code)" "FAIL \(f\)"

# ---- (n) ----
P=$(fresh); perl -ni -e 'print unless /^name:/' "$P/$SKILL"
expect_fail "name removed (no bare /archive-lines alias)" "FAIL \(n\)"

echo
echo "Results: $PASSED passed, $FAILED failed"
[ "$FAILED" -eq 0 ]
