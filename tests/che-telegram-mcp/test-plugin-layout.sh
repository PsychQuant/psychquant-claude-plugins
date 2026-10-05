#!/bin/bash
# Structural regression test for the che-telegram-mcp plugin layout (#138).
#
# Guards the shape that `claude plugin validate` does not check:
#   (a) no bin/ — files there land on the Bash tool's PATH, and claude.ai /
#       Cowork refuse to install a plugin that has it
#   (b) every .mcp.json command resolves to an executable file
#   (c) every ${CLAUDE_PLUGIN_ROOT} in a hook command is quoted
#   (d) every mcp__ entry in allowed-tools uses the real plugin tool prefix
#       and names a tool the README documents (the old commands used
#       mcp__che-telegram-mcp__*, which never matched anything)
#   (e) no commands/ — the slash entry points live in skills/
#   (f) the send skill does not pre-approve send_message: a sent message
#       cannot be recalled, so the permission prompt stays as the hard gate
#   (g) telegram-messaging stays model-invocable — it is the natural-language
#       router. A glob edit over skills/*/SKILL.md once added
#       disable-model-invocation to it along with the four slash skills.
#
# Usage:
#   bash tests/che-telegram-mcp/test-plugin-layout.sh

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="$(cd "$SCRIPT_DIR/../../plugins/che-telegram-mcp" && pwd)"

FAILURES=0
pass() { echo "PASS $1"; }
fail() { echo "FAIL $1"; FAILURES=$((FAILURES + 1)); }

echo "test-plugin-layout.sh (#138) — $PLUGIN_DIR"

# (a)
if [ -e "$PLUGIN_DIR/bin" ]; then
    fail "(a) bin/ exists: $(ls "$PLUGIN_DIR/bin" | tr '\n' ' ')"
else
    pass "(a) no bin/"
fi

# (b)
B_OUT=$(python3 - "$PLUGIN_DIR" <<'EOF'
import json, os, sys
root = sys.argv[1]
cfg = json.load(open(os.path.join(root, ".mcp.json")))
servers = cfg.get("mcpServers", cfg)
bad = []
for name, spec in servers.items():
    cmd = spec.get("command", "").replace("${CLAUDE_PLUGIN_ROOT}", root)
    if not (os.path.isfile(cmd) and os.access(cmd, os.X_OK)):
        bad.append(f"{name} -> {cmd}")
print("\n".join(bad))
EOF
)
if [ -n "$B_OUT" ]; then
    fail "(b) .mcp.json command not executable: $B_OUT"
else
    pass "(b) .mcp.json commands resolve to executables"
fi

# (c)
C_OUT=$(python3 - "$PLUGIN_DIR" <<'EOF'
import json, os, re, sys
d = json.load(open(os.path.join(sys.argv[1], "hooks", "hooks.json")))
bad = []
for event, matchers in d.get("hooks", {}).items():
    for m in matchers:
        for h in m.get("hooks", []):
            cmd = h.get("command", "")
            for mt in re.finditer(r"\$\{CLAUDE_PLUGIN_ROOT\}", cmd):
                i, j = mt.start(), mt.end()
                if not (i > 0 and cmd[i - 1] == '"' and j < len(cmd) and cmd[j] == '"'):
                    bad.append(f"{event}: {cmd}")
print("\n".join(bad))
EOF
)
if [ -n "$C_OUT" ]; then
    fail "(c) unquoted \${CLAUDE_PLUGIN_ROOT} in hook: $C_OUT"
else
    pass "(c) hook commands quote \${CLAUDE_PLUGIN_ROOT}"
fi

# (d) and (f) share the frontmatter parser
DF_OUT=$(python3 - "$PLUGIN_DIR" <<'EOF'
import glob, os, re, sys
root = sys.argv[1]
readme = open(os.path.join(root, "README.md")).read()
documented = set(re.findall(r"`([a-z_]+)`", readme))
prefix = re.compile(r"^mcp__plugin_che-telegram-mcp_telegram-(all|bot)__([a-z_]+)$")

def allowed_tools(path):
    text = open(path).read()
    if not text.startswith("---\n"):
        return []
    fm = text.split("---\n", 2)[1]
    tools, in_list = [], False
    for line in fm.splitlines():
        if line.startswith("allowed-tools:"):
            rest = line.split(":", 1)[1].strip()
            if rest:
                tools += [t for t in re.split(r"[,\s]+", rest) if t]
                in_list = False
            else:
                in_list = True
        elif in_list and re.match(r"^\s+-\s+", line):
            tools.append(re.sub(r"^\s+-\s+", "", line).strip())
        elif in_list and line and not line.startswith(" "):
            in_list = False
    return tools

files = sorted(glob.glob(os.path.join(root, "commands", "*.md")) +
               glob.glob(os.path.join(root, "skills", "*", "SKILL.md")))
for f in files:
    rel = os.path.relpath(f, root)
    for t in allowed_tools(f):
        if not t.startswith("mcp__"):
            continue
        m = prefix.match(t)
        if not m:
            print(f"D {rel}: wrong prefix {t}")
        elif m.group(2) not in documented:
            print(f"D {rel}: {m.group(2)} not documented in README")

router = os.path.join(root, "skills", "telegram-messaging", "SKILL.md")
router_fm = open(router).read().split("---\n", 2)[1] if os.path.exists(router) else ""
if re.search(r"^disable-model-invocation:\s*(true|yes|on|1)\s*$", router_fm, re.M | re.I):
    print("G skills/telegram-messaging/SKILL.md sets disable-model-invocation")

send = os.path.join(root, "skills", "send", "SKILL.md")
if os.path.exists(send):
    if any(t.endswith("__send_message") for t in allowed_tools(send)):
        print("F skills/send/SKILL.md pre-approves send_message")
else:
    print("F skills/send/SKILL.md missing")
EOF
)
D_OUT=$(printf '%s\n' "$DF_OUT" | sed -n 's/^D //p')
F_OUT=$(printf '%s\n' "$DF_OUT" | sed -n 's/^F //p')
G_OUT=$(printf '%s\n' "$DF_OUT" | sed -n 's/^G //p')
if [ -n "$D_OUT" ]; then
    fail "(d) allowed-tools:"$'\n'"$D_OUT"
else
    pass "(d) allowed-tools use the real plugin tool prefix"
fi

# (e)
if [ -e "$PLUGIN_DIR/commands" ]; then
    fail "(e) commands/ exists: $(ls "$PLUGIN_DIR/commands" | tr '\n' ' ')"
else
    pass "(e) no commands/"
fi

# (f)
if [ -n "$F_OUT" ]; then
    fail "(f) $F_OUT"
else
    pass "(f) send skill keeps the permission prompt for send_message"
fi

# (g)
if [ -n "$G_OUT" ]; then
    fail "(g) $G_OUT"
else
    pass "(g) telegram-messaging stays model-invocable"
fi

echo
if [ "$FAILURES" -gt 0 ]; then
    echo "$FAILURES check(s) failed"
    exit 1
fi
echo "all checks passed"
