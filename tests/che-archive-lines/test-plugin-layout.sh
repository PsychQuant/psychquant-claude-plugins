#!/bin/bash
# Structural regression test for the che-archive-lines plugin layout (#139).
#
# Guards what `claude plugin validate` does not check:
#   (a)  no commands/ — the entry point is skills/archive-lines/SKILL.md
#   (b)  the skill reaches the script through ${CLAUDE_PLUGIN_ROOT}/scripts/
#        line-save-chat.sh, and that script exists and is executable
#        (Claude Code substitutes ${CLAUDE_PLUGIN_ROOT} in skill content)
#   (c)  no path that only works by accident: no $(dirname "$0") derivation
#        (a skill has no $0) and no ./scripts/ relative path (the user's
#        working directory is their project, not the plugin)
#   (d)  no hard-coded per-machine path anywhere in the plugin: no home
#        directory, no cloud-sync folder, no ~/.claude/plugins/<name>/ copy
#        location. This repo is public.
#   (e)  allowed-tools pre-approves nothing beyond Read. The script drives the
#        mouse (coordinate clicks in LINE), so running it keeps its permission
#        prompt; Bash(*) / Write / Glob were pre-approved before 1.1.0.
#   (f)  disable-model-invocation: true — only the user starts GUI automation
#   (fm) the skill file has frontmatter Claude Code can read
#
# Frontmatter is parsed with PyYAML after stripping a UTF-8 BOM. Every check
# FAILS CLOSED: if the parser cannot run, the test fails instead of passing.
#
# Usage:
#   bash tests/che-archive-lines/test-plugin-layout.sh

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="$(cd "$SCRIPT_DIR/../../plugins/che-archive-lines" 2>/dev/null && pwd)"

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

echo "test-plugin-layout.sh (#139) — $PLUGIN_DIR"

OUT=$(python3 - "$PLUGIN_DIR" <<'EOF'
import os, re, sys

try:
    import yaml
except ImportError:
    raise SystemExit("PyYAML is required (pip install pyyaml) — frontmatter checks cannot run without a real YAML parser")

root = sys.argv[1]
problems = []
def bad(tag, msg): problems.append(f"{tag} {msg}")

# ---------- (a) ----------
if os.path.exists(os.path.join(root, "commands")):
    bad("a", "commands/ exists: " + " ".join(sorted(os.listdir(os.path.join(root, "commands")))))

# ---------- skill ----------
# A missing skill must not make the checks that read it look clean: (fm) (c)
# (e) (f) are reported as failures ("cannot check"), never as passes. (d) scans
# the whole plugin and runs regardless.
skill = os.path.join(root, "skills", "archive-lines", "SKILL.md")
script = os.path.join(root, "scripts", "line-save-chat.sh")
fm, body = None, None
if not os.path.isfile(skill):
    bad("b", "skills/archive-lines/SKILL.md is missing")
    for tag in ("fm", "c", "e", "f"):
        bad(tag, "skills/archive-lines/SKILL.md is missing — cannot check")
else:
    text = open(skill, encoding="utf-8-sig").read().replace("\r\n", "\n")
    end = text.find("\n---\n", 4) if text.startswith("---\n") else -1
    if end < 0:
        bad("fm", "skills/archive-lines/SKILL.md has no frontmatter Claude Code can read")
        for tag in ("e", "f"):
            bad(tag, "no readable frontmatter — cannot check")
        body = text
    else:
        fm = yaml.safe_load(text[4:end]) or {}
        if not isinstance(fm, dict):
            raise SystemExit("frontmatter is not a mapping")
        body = text[end + 5:]

# ---------- (b) ----------
if body is not None and "${CLAUDE_PLUGIN_ROOT}/scripts/line-save-chat.sh" not in body:
    bad("b", "skill body does not reference ${CLAUDE_PLUGIN_ROOT}/scripts/line-save-chat.sh")
if not (os.path.isfile(script) and os.access(script, os.X_OK)):
    bad("b", "scripts/line-save-chat.sh is missing or not executable")

# ---------- (c) ----------
if body is not None:
    if re.search(r"\$\(dirname", body):
        bad("c", "skill derives a path with $(dirname …) — a skill has no $0")
    if re.search(r"(?<![\w}/])\./scripts/", body):
        bad("c", "skill uses a relative ./scripts/ path (resolves against the user's project)")

# ---------- (d) every text file in the plugin ----------
patterns = [
    (r"/Users/[^/\s`'\"]+/", "a home-directory absolute path"),
    (r"/home/[^/\s`'\"]+/", "a home-directory absolute path"),
    (r"CloudStorage/", "a cloud-sync folder path"),
    (r"~/\.claude/plugins/che-archive-lines", "the obsolete ~/.claude/plugins/<name> install location"),
]
for dirpath, _, files in os.walk(root):
    for fname in files:
        p = os.path.join(dirpath, fname)
        try:
            content = open(p, encoding="utf-8").read()
        except (UnicodeDecodeError, OSError):
            continue
        rel = os.path.relpath(p, root)
        for pat, what in patterns:
            if re.search(pat, content):
                bad("d", f"{rel} contains {what}")

if fm is not None:
    # ---------- (e) ----------
    raw = fm.get("allowed-tools")
    if raw is None:
        tools = []
    elif isinstance(raw, str):
        tools = [t for t in re.split(r"[,\s]+", raw) if t]
    elif isinstance(raw, list):
        tools = [str(t) for t in raw]
    else:
        raise SystemExit(f"allowed-tools has unsupported type {type(raw).__name__}")
    for t in tools:
        if t != "Read":
            bad("e", f"allowed-tools pre-approves {t} (only Read is allowed)")

    # ---------- (f) ----------
    dmi = fm.get("disable-model-invocation", False)
    if not (dmi is True or str(dmi).strip().lower() in ("true", "yes", "on", "1")):
        bad("f", "disable-model-invocation is not true")

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

report a  "no commands/"
report fm "the skill has readable frontmatter"
report b  "skill reaches the script via \${CLAUDE_PLUGIN_ROOT}/scripts/line-save-chat.sh"
report c  "no \$(dirname) derivation or ./scripts/ relative path"
report d  "no hard-coded per-machine path in the plugin"
report e  "allowed-tools pre-approves nothing beyond Read"
report f  "disable-model-invocation: true"

echo
if [ "$FAILURES" -gt 0 ]; then
    echo "$FAILURES check(s) failed"
    exit 1
fi
echo "all checks passed"
