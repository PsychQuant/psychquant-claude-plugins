#!/bin/bash
# Structural regression test for the che-telegram-mcp plugin layout (#138).
#
# Guards the shape that `claude plugin validate` does not check:
#   (a)  bin/ holds only the MCP wrappers (*-wrapper.sh) — no test scripts.
#        Files in bin/ go on the Bash tool's PATH, so nothing else belongs there.
#        The wrappers themselves stay in bin/: harness-devtools (plugin-update,
#        plugin-deploy, plugin-binary-meta.sh) only finds wrappers in bin/ and
#        hooks/, and moving them out silently disabled its release gate (#138
#        verify round 1).
#   (b)  every .mcp.json command is ${CLAUDE_PLUGIN_ROOT}/bin/<name>-wrapper.sh
#        and resolves to an executable file
#   (b2) every wrapper carries a literal DESIRED_VERSION pin — the value the
#        devtools post-release bump rewrites
#   (c)  every ${CLAUDE_PLUGIN_ROOT} in a hook command sits inside double quotes
#   (d)  every mcp__ entry in allowed-tools uses the real plugin tool prefix and
#        names a tool the README documents under THAT server
#   (e)  no commands/ — the slash entry points live in skills/
#   (f)  no skill pre-approves an irreversible tool. Irreversible = any tool the
#        README documents that is not get_*/search_*/auth_* or the read-only
#        dump_chat_to_markdown. A sent, edited, deleted or forwarded message
#        cannot be recalled, so the permission prompt stays where one exists.
#   (g)  telegram-messaging exists and stays model-invocable — it is the
#        natural-language router. A glob edit over skills/*/SKILL.md once added
#        disable-model-invocation to it along with the four slash skills.
#   (h)  the four slash skills (auth, chats, search, send) set
#        disable-model-invocation: true — they run only when the user types them
#
# Every check FAILS CLOSED: if its parser cannot run (bad JSON, missing file,
# no python3), the check fails. An empty "no problems found" output is only
# trusted when the parser exited 0.
#
# Usage:
#   bash tests/che-telegram-mcp/test-plugin-layout.sh

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="$(cd "$SCRIPT_DIR/../../plugins/che-telegram-mcp" 2>/dev/null && pwd)"

FAILURES=0
pass() { echo "PASS $1"; }
fail() { echo "FAIL $1"; FAILURES=$((FAILURES + 1)); }

if [ -z "$PLUGIN_DIR" ]; then
    echo "FAIL plugin directory not found next to $SCRIPT_DIR"
    exit 1
fi
if ! command -v python3 >/dev/null 2>&1; then
    echo "FAIL python3 not found — no check can run"
    exit 1
fi

echo "test-plugin-layout.sh (#138) — $PLUGIN_DIR"

# One python pass does all parsing and prints one line per problem, tagged by
# check letter. Exit status != 0 means the parse itself broke.
OUT=$(python3 - "$PLUGIN_DIR" <<'EOF'
import json, os, re, sys

root = sys.argv[1]
problems = []
def bad(tag, msg): problems.append(f"{tag} {msg}")

# ---------- (a) bin/ contents ----------
bindir = os.path.join(root, "bin")
if os.path.isdir(bindir):
    for name in sorted(os.listdir(bindir)):
        p = os.path.join(bindir, name)
        if not name.endswith("-wrapper.sh"):
            bad("a", f"bin/{name} is not an MCP wrapper (only *-wrapper.sh belongs on PATH)")
        elif not os.access(p, os.X_OK):
            bad("a", f"bin/{name} is not executable")

# ---------- (b) / (b2) .mcp.json ----------
cfg = json.load(open(os.path.join(root, ".mcp.json")))
servers = cfg.get("mcpServers", cfg)
if not servers:
    bad("b", ".mcp.json declares no servers")
for name, spec in servers.items():
    cmd = spec.get("command", "")
    if not re.fullmatch(r"\$\{CLAUDE_PLUGIN_ROOT\}/bin/[A-Za-z0-9._-]+-wrapper\.sh", cmd):
        bad("b", f"{name}: command is not ${{CLAUDE_PLUGIN_ROOT}}/bin/<name>-wrapper.sh: {cmd}")
        continue
    path = cmd.replace("${CLAUDE_PLUGIN_ROOT}", root)
    if not (os.path.isfile(path) and os.access(path, os.X_OK)):
        bad("b", f"{name}: {path} is not an executable file")
        continue
    src = open(path).read()
    if not re.search(r'^\s*DESIRED_VERSION="[0-9]+\.[0-9]+\.[0-9]+"', src, re.M):
        bad("b2", f"{name}: {os.path.basename(path)} has no literal DESIRED_VERSION=\"x.y.z\"")

# ---------- (c) hook quoting ----------
def inside_double_quotes(s, i):
    n, k = 0, 0
    while k < i:
        if s[k] == "\\":
            k += 2
            continue
        if s[k] == '"':
            n += 1
        k += 1
    return n % 2 == 1

hooks = json.load(open(os.path.join(root, "hooks", "hooks.json")))
for event, matchers in hooks.get("hooks", {}).items():
    for m in matchers:
        for h in m.get("hooks", []):
            cmd = h.get("command", "")
            for mt in re.finditer(r"\$\{CLAUDE_PLUGIN_ROOT\}", cmd):
                if not inside_double_quotes(cmd, mt.start()):
                    bad("c", f"{event}: unquoted ${{CLAUDE_PLUGIN_ROOT}} in: {cmd}")

# ---------- README: tools per server ----------
readme = open(os.path.join(root, "README.md")).read()
def section_tools(header_pat):
    m = re.search(header_pat + r".*?\n(.*?)(?=\n### |\n## |\Z)", readme, re.S)
    if not m:
        return None
    return set(re.findall(r"`([a-z][a-z0-9_]*)`", m.group(1)))
documented = {
    "all": section_tools(r"(?m)^### `telegram-all`"),
    "bot": section_tools(r"(?m)^### `telegram-bot`"),
}
for srv, tools in documented.items():
    if not tools:
        raise SystemExit(f"README has no tool list for telegram-{srv} — cannot check (d)/(f)")

def irreversible(tool):
    return not (tool.startswith(("get_", "search_", "auth_")) or tool == "dump_chat_to_markdown")

# ---------- frontmatter ----------
def frontmatter(path):
    text = open(path, encoding="utf-8").read()          # universal newlines: CRLF -> LF
    if not text.startswith("---\n"):
        return None
    parts = text.split("\n---\n", 1)
    if len(parts) < 2:
        raise SystemExit(f"{path}: unterminated frontmatter")
    return parts[0][4:]

def field_block(fm, key):
    """Raw text of a top-level key: its inline value plus any following list /
    indented continuation lines. Handles quoted, flow-style and column-0 lists."""
    lines = fm.split("\n")
    out, grabbing = [], False
    for line in lines:
        if re.match(rf"^{re.escape(key)}\s*:", line):
            grabbing = True
            out.append(line.split(":", 1)[1])
            continue
        if grabbing:
            if re.match(r"^\s*-\s", line) or (line[:1] in (" ", "\t") and line.strip()):
                out.append(line)
                continue
            grabbing = False
    return "\n".join(out) if out else None

def tool_tokens(raw):
    if raw is None:
        return []
    cleaned = re.sub(r"[\[\]\"',]", " ", raw)
    cleaned = re.sub(r"(?m)^\s*-\s", " ", cleaned)
    return [t for t in cleaned.split() if t]

def truthy(raw):
    if raw is None:
        return False
    v = re.sub(r"[\"'\s]", "", raw).lower()
    return v in ("true", "yes", "on", "1")

prefix = re.compile(r"^mcp__plugin_che-telegram-mcp_telegram-(all|bot)__([a-z0-9_]+)$")
skill_files = []
for d in ("commands",):
    p = os.path.join(root, d)
    if os.path.isdir(p):
        skill_files += [os.path.join(p, f) for f in sorted(os.listdir(p)) if f.endswith(".md")]
sk = os.path.join(root, "skills")
if os.path.isdir(sk):
    skill_files += [os.path.join(sk, d, "SKILL.md") for d in sorted(os.listdir(sk))
                    if os.path.isfile(os.path.join(sk, d, "SKILL.md"))]

for f in skill_files:
    rel = os.path.relpath(f, root)
    fm = frontmatter(f)
    if fm is None:
        continue
    raw = field_block(fm, "allowed-tools")
    flagged = set()
    for t in tool_tokens(raw):
        if "mcp__" not in t:
            continue
        m = prefix.match(t)
        if not m:
            bad("d", f"{rel}: wrong prefix {t}")
            continue
        srv, tool = m.group(1), m.group(2)
        if tool not in documented[srv]:
            bad("d", f"{rel}: {tool} is not documented under telegram-{srv} in README")
        if irreversible(tool) and tool not in flagged:
            flagged.add(tool)
            bad("f", f"{rel}: pre-approves irreversible tool {tool}")
    # Belt and braces for (f): independent of the tokenizer, take the segment
    # after the LAST "__" of every mcp-style token in the raw field text, so a
    # spelling the tokenizer mangles (or a wrong prefix) still cannot slip an
    # irreversible tool past this check.
    if raw is not None:
        for tok in re.findall(r"[A-Za-z0-9_-]*__[A-Za-z0-9_-]+", raw):
            tool = tok.rsplit("__", 1)[1]
            if irreversible(tool) and tool not in flagged:
                flagged.add(tool)
                bad("f", f"{rel}: pre-approves irreversible tool {tool}")

# ---------- (g) router ----------
router = os.path.join(root, "skills", "telegram-messaging", "SKILL.md")
if not os.path.isfile(router):
    bad("g", "skills/telegram-messaging/SKILL.md is missing")
else:
    fm = frontmatter(router) or ""
    if truthy(field_block(fm, "disable-model-invocation")):
        bad("g", "skills/telegram-messaging/SKILL.md sets disable-model-invocation")

# ---------- (h) slash skills ----------
for name in ("auth", "chats", "search", "send"):
    p = os.path.join(root, "skills", name, "SKILL.md")
    if not os.path.isfile(p):
        bad("h", f"skills/{name}/SKILL.md is missing")
        continue
    if not truthy(field_block(frontmatter(p) or "", "disable-model-invocation")):
        bad("h", f"skills/{name}/SKILL.md does not set disable-model-invocation: true")

print("\n".join(problems))
EOF
)
RC=$?

if [ "$RC" -ne 0 ]; then
    echo "FAIL parser crashed (exit $RC) — every check below is UNVERIFIED, not passed:"
    printf '%s\n' "$OUT" | sed 's/^/    /'
    exit 1
fi

report() {  # $1 = tag, $2 = description when clean
    local lines
    lines=$(printf '%s\n' "$OUT" | sed -n "s/^$1 //p")
    if [ -n "$lines" ]; then
        fail "($1) $2"$'\n'"$(printf '%s\n' "$lines" | sed 's/^/    /')"
    else
        pass "($1) $2"
    fi
}

report a  "bin/ holds only executable *-wrapper.sh files"
report b  ".mcp.json commands are \${CLAUDE_PLUGIN_ROOT}/bin/*-wrapper.sh and executable"
report b2 "every wrapper pins a literal DESIRED_VERSION"
report c  "hook commands quote \${CLAUDE_PLUGIN_ROOT}"
report d  "allowed-tools use the real prefix and documented tools of the right server"
if [ -e "$PLUGIN_DIR/commands" ]; then
    fail "(e) commands/ exists: $(ls "$PLUGIN_DIR/commands" | tr '\n' ' ')"
else
    pass "(e) no commands/"
fi
report f  "no skill pre-approves an irreversible tool"
report g  "telegram-messaging exists and stays model-invocable"
report h  "auth/chats/search/send set disable-model-invocation: true"

echo
if [ "$FAILURES" -gt 0 ]; then
    echo "$FAILURES check(s) failed"
    exit 1
fi
echo "all checks passed"
