#!/bin/bash
# Mutation test for test-plugin-layout.sh (#138 verify round 1).
#
# A layout test that never fails is worse than none: round 1 found that the
# first version reported PASS when its own parser crashed, and that quoted,
# column-0 and flow-style YAML slipped past the send_message guard. Each case
# below copies the plugin into a scratch tree, breaks ONE thing, and asserts the
# layout test catches it. The real repo is never modified.
#
# Usage:
#   bash tests/che-telegram-mcp/test-plugin-layout-mutations.sh

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_PLUGIN="$(cd "$SCRIPT_DIR/../../plugins/che-telegram-mcp" && pwd)"
LAYOUT_TEST="$SCRIPT_DIR/test-plugin-layout.sh"
SCRATCH=$(mktemp -d "${TMPDIR:-/tmp}/layout-mutations-XXXXXX")
trap 'rm -rf "$SCRATCH"' EXIT

PASSED=0
FAILED=0
ALL="mcp__plugin_che-telegram-mcp_telegram-all__"

fresh() {   # build a clean scratch copy; echo its plugin dir
    rm -rf "$SCRATCH/tree"
    mkdir -p "$SCRATCH/tree/tests/che-telegram-mcp" "$SCRATCH/tree/plugins"
    cp -R "$SRC_PLUGIN" "$SCRATCH/tree/plugins/che-telegram-mcp"
    cp "$LAYOUT_TEST" "$SCRATCH/tree/tests/che-telegram-mcp/"
    echo "$SCRATCH/tree/plugins/che-telegram-mcp"
}

run_layout() {
    bash "$SCRATCH/tree/tests/che-telegram-mcp/test-plugin-layout.sh" 2>&1
}

# expect <name> <pattern-that-must-appear> — the layout test must exit non-zero
# AND print the pattern (so the RIGHT check caught it, not an unrelated one)
expect_fail() {
    local name="$1" pattern="$2" out rc
    out=$(run_layout); rc=$?
    if [ "$rc" -ne 0 ] && printf '%s\n' "$out" | grep -qE "$pattern"; then
        echo "  ✓ $name"
        PASSED=$((PASSED + 1))
    else
        echo "  ✗ $name (exit $rc; expected /$pattern/)"
        printf '%s\n' "$out" | sed 's/^/      /'
        FAILED=$((FAILED + 1))
    fi
}
expect_pass() {
    local name="$1" out rc
    out=$(run_layout); rc=$?
    if [ "$rc" -eq 0 ]; then
        echo "  ✓ $name"
        PASSED=$((PASSED + 1))
    else
        echo "  ✗ $name (exit $rc, expected pass)"
        printf '%s\n' "$out" | sed 's/^/      /'
        FAILED=$((FAILED + 1))
    fi
}
# replace the frontmatter allowed-tools block of a skill with the given lines
set_allowed() {
    local file="$1"; shift
    python3 - "$file" "$@" <<'EOF'
import re, sys
path, lines = sys.argv[1], sys.argv[2:]
text = open(path, encoding="utf-8", newline="").read()
nl = "\r\n" if "\r\n" in text else "\n"
head, rest = text.split(nl + "---" + nl, 1)
out, skip = [], False
for line in head.split(nl):
    if line.startswith("allowed-tools:"):
        out.extend(lines); skip = True; continue
    if skip and (line.startswith(" ") or line.startswith("-")):
        continue
    skip = False
    out.append(line)
open(path, "w", encoding="utf-8", newline="").write(nl.join(out) + nl + "---" + nl + rest)
EOF
}

echo "test-plugin-layout-mutations.sh (#138)"

P=$(fresh); expect_pass "unmodified copy passes"

P=$(fresh); echo '{ not json' > "$P/.mcp.json"
expect_fail "broken .mcp.json fails closed" "parser crashed"

P=$(fresh); rm "$P/README.md"
expect_fail "missing README fails closed" "parser crashed"

P=$(fresh); printf '#!/bin/bash\n' > "$P/bin/test-x.sh"; chmod +x "$P/bin/test-x.sh"
expect_fail "test script in bin/" "FAIL \(a\)"

P=$(fresh); sed -i '' 's#/bin/che-telegram-bot#/scripts/che-telegram-bot#' "$P/.mcp.json"
expect_fail ".mcp.json points outside bin/" "FAIL \(b\)"

P=$(fresh); sed -i '' 's/^DESIRED_VERSION=.*/DESIRED_VERSION="$X"/' "$P/bin/che-telegram-bot-mcp-wrapper.sh"
expect_fail "wrapper loses its literal pin" "FAIL \(b2\)"

P=$(fresh); perl -pi -e 's#"\\"\$\{CLAUDE_PLUGIN_ROOT\}\\"/hooks#"\${CLAUDE_PLUGIN_ROOT}/hooks#' "$P/hooks/hooks.json"
expect_fail "unquoted hook path" "FAIL \(c\)"

P=$(fresh); perl -pi -e 's#"\\"\$\{CLAUDE_PLUGIN_ROOT\}\\"/hooks/check-mcp\.sh"#"\\"\${CLAUDE_PLUGIN_ROOT}/hooks/check-mcp.sh\\""#' "$P/hooks/hooks.json"
expect_pass "fully quoted hook path is accepted"

P=$(fresh); set_allowed "$P/skills/send/SKILL.md" "allowed-tools:" "  - \"${ALL}send_message\""
expect_fail "quoted send_message" "FAIL \(f\).*|send_message"

P=$(fresh); set_allowed "$P/skills/send/SKILL.md" "allowed-tools:" "- ${ALL}send_message"
expect_fail "column-0 list send_message" "send_message"

P=$(fresh); set_allowed "$P/skills/send/SKILL.md" "allowed-tools: [${ALL}auth_status, ${ALL}send_message]"
expect_fail "flow-style send_message" "send_message"

P=$(fresh); set_allowed "$P/skills/search/SKILL.md" "allowed-tools:" "  - ${ALL}search"
expect_fail "tool that does not exist" "FAIL \(d\)"

P=$(fresh); set_allowed "$P/skills/chats/SKILL.md" "allowed-tools:" "  - ${ALL}ban_chat_member"
expect_fail "bot tool under the all prefix" "not documented under telegram-all"

P=$(fresh); set_allowed "$P/skills/chats/SKILL.md" "allowed-tools:" "  - ${ALL}delete_messages"
expect_fail "irreversible tool other than send_message" "delete_messages"

P=$(fresh); rm -r "$P/skills/telegram-messaging"
expect_fail "router skill deleted" "FAIL \(g\)"

P=$(fresh); perl -0pi -e 's/^(description: [^\n]*\n)/$1disable-model-invocation: "true"\n/m' "$P/skills/telegram-messaging/SKILL.md"
expect_fail "router disabled with a quoted value" "FAIL \(g\)"

P=$(fresh); perl -ni -e 'print unless /^disable-model-invocation:/' "$P/skills/send/SKILL.md"
expect_fail "send loses disable-model-invocation" "FAIL \(h\)"

P=$(fresh); mkdir -p "$P/commands"; printf -- '---\nname: x\n---\n' > "$P/commands/x.md"
expect_fail "commands/ reappears" "FAIL \(e\)"

echo
echo "Results: $PASSED passed, $FAILED failed"
[ "$FAILED" -eq 0 ]
