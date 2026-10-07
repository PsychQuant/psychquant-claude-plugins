#!/bin/bash
# Structural regression test for the che-archive-lines plugin layout (#139).
#
# Guards what `claude plugin validate` does not check:
#   (a)  no commands/ — the entry point is skills/archive-lines/SKILL.md
#   (b)  EVERY mention of line-save-chat.sh in the skill body is the path
#        ${CLAUDE_PLUGIN_ROOT}/scripts/line-save-chat.sh, and that script exists
#        and is executable. Claude Code substitutes ${CLAUDE_PLUGIN_ROOT} in skill
#        content; any other spelling (scripts/…, ./scripts/…, the unbraced
#        $CLAUDE_PLUGIN_ROOT) resolves against the user's project or not at all.
#   (c)  no $0 / ${0 / $(dirname in the body: in skill content $0 is the first
#        argument (save, test, …), so a path derived from it is cwd-relative.
#   (d)  no hard-coded per-machine path anywhere in the plugin: no home
#        directory, no cloud-sync folder (CloudStorage, Dropbox, iCloud's Mobile
#        Documents), no ~/.claude/plugins/<name>/ copy location. This repo is
#        public. Files are read as bytes and decoded as UTF-16 when they carry a
#        UTF-16 BOM, otherwise as UTF-8 with errors="replace", so no file is
#        skipped.
#   (e)  allowed-tools is exactly these three rules, in any order:
#          Bash(${CLAUDE_PLUGIN_ROOT}/scripts/line-save-chat.sh save)
#          Bash(${CLAUDE_PLUGIN_ROOT}/scripts/line-save-chat.sh test)
#          Bash(${CLAUDE_PLUGIN_ROOT}/scripts/line-save-chat.sh help)
#        Claude Code matches a rule against each subcommand of a pipeline, so a
#        trailing `*` (…line-save-chat.sh *) also pre-approved calibrate, even
#        with `printf '\n\n' |` piped in front — verify round 2 (#139) probed
#        that, and with #149 it chains into running any command. With exact
#        rules calibrate goes through the user's normal permission settings.
#        Also: no `hooks:` in the frontmatter and no !`command` / ```! block in
#        the body — both run commands outside allowed-tools.
#   (f)  disable-model-invocation is the literal, unquoted `true` — only the user
#        starts GUI automation. Claude Code 2.1.218+ also accepts yes/on/1, but
#        earlier versions recognise only true, so the test accepts only true.
#   (n)  name: archive-lines — without a frontmatter name, a plugin skill has no
#        bare /archive-lines alias, and the README promises one.
#   (fm) the skill file has frontmatter Claude Code can read
#
# The frontmatter boundary is found the way Claude Code finds it: the first
# `---` after the opening line, anywhere — not only at the start of a line. A
# `---` inside a value therefore ends the frontmatter early in Claude Code, and
# the test sees the same truncated block (verify finding, #139 round 1). The
# match uses JavaScript's \s (no Python-only NEL) on text read without newline
# translation, so a lone CR does not end a line here either (round 2).
# Frontmatter is then parsed with PyYAML after stripping a UTF-8 BOM. Every
# check FAILS CLOSED: if the parser cannot run, the test fails instead of
# passing.
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

SCRIPT_PATH = "${CLAUDE_PLUGIN_ROOT}/scripts/line-save-chat.sh"
ALLOWED_RULES = {f"Bash({SCRIPT_PATH} {verb})" for verb in ("save", "test", "help")}
# JavaScript's \s, which Claude Code's frontmatter regex uses (Python's \s also
# matches NEL, U+0085).
JS_WS = "[\t\n\v\f\r \u00a0\u1680\u2000-\u200a\u2028\u2029\u202f\u205f\u3000\ufeff]"
FM_RE = re.compile(f"---{JS_WS}*\n([\\s\\S]*?)---{JS_WS}*\n?")

# ---------- (a) ----------
if os.path.exists(os.path.join(root, "commands")):
    bad("a", "commands/ exists: " + " ".join(sorted(os.listdir(os.path.join(root, "commands")))))

# ---------- skill ----------
# A missing skill must not make the checks that read it look clean: (fm) (c)
# (e) (f) (n) are reported as failures ("cannot check"), never as passes. (d)
# scans the whole plugin and runs regardless.
skill = os.path.join(root, "skills", "archive-lines", "SKILL.md")
script = os.path.join(root, "scripts", "line-save-chat.sh")
fm, fm_raw, body = None, None, None
if not os.path.isfile(skill):
    bad("b", "skills/archive-lines/SKILL.md is missing")
    for tag in ("fm", "c", "e", "f", "n"):
        bad(tag, "skills/archive-lines/SKILL.md is missing — cannot check")
else:
    text = open(skill, encoding="utf-8-sig", newline="").read()
    # Claude Code's own boundary: lazy, not anchored to a line start.
    m = FM_RE.match(text)
    if not m:
        bad("fm", "skills/archive-lines/SKILL.md has no frontmatter Claude Code can read")
        for tag in ("e", "f", "n"):
            bad(tag, "no readable frontmatter — cannot check")
        body = text
    else:
        fm = yaml.safe_load(m.group(1)) or {}
        # BaseLoader builds no Python objects: every scalar stays a string, so
        # (f) can tell a literal true from yes/on/1/"true".
        fm_raw = yaml.load(m.group(1), Loader=yaml.BaseLoader) or {}
        if not isinstance(fm, dict) or not isinstance(fm_raw, dict):
            raise SystemExit("frontmatter is not a mapping")
        body = text[m.end():]

# ---------- (b) ----------
if body is not None:
    for mt in re.finditer(r"line-save-chat\.sh", body):
        start = mt.start() - len("${CLAUDE_PLUGIN_ROOT}/scripts/")
        if start < 0 or body[start:mt.end()] != SCRIPT_PATH:
            line = body[:mt.start()].count("\n") + 1
            bad("b", f"skill body line {line} names the script without ${{CLAUDE_PLUGIN_ROOT}}/scripts/: "
                     + body.splitlines()[line - 1].strip())
    if SCRIPT_PATH not in body:
        bad("b", "skill body never runs " + SCRIPT_PATH)
if not (os.path.isfile(script) and os.access(script, os.X_OK)):
    bad("b", "scripts/line-save-chat.sh is missing or not executable")

# ---------- (c) ----------
if body is not None:
    if re.search(r"\$\{?0", body):
        bad("c", "skill uses $0 — in skill content $0 is the first argument, not a path")
    if re.search(r"\$\(dirname", body):
        bad("c", "skill derives a path with $(dirname …)")
    if re.search(r"\$CLAUDE_PLUGIN_ROOT", body):
        bad("c", "skill uses unbraced $CLAUDE_PLUGIN_ROOT — only ${CLAUDE_PLUGIN_ROOT} is substituted")

# ---------- (d) every file in the plugin ----------
patterns = [
    (r"/Users/[^/\s`'\"]+/", "a home-directory absolute path"),
    (r"/home/[^/\s`'\"]+/", "a home-directory absolute path"),
    (r"CloudStorage/", "a cloud-sync folder path"),
    (r"Dropbox/", "a cloud-sync folder path"),
    (r"Mobile Documents/", "an iCloud Drive path"),
    (r"~/\.claude/plugins/che-archive-lines", "the obsolete ~/.claude/plugins/<name> install location"),
]
for dirpath, _, files in os.walk(root):
    for fname in files:
        p = os.path.join(dirpath, fname)
        rel = os.path.relpath(p, root)
        try:
            data = open(p, "rb").read()
            if data.startswith((b"\xff\xfe", b"\xfe\xff")):
                content = data.decode("utf-16", errors="replace")
            else:
                content = data.decode("utf-8", errors="replace")
        except OSError as e:
            bad("d", f"{rel} cannot be read — cannot check ({e})")
            continue
        for pat, what in patterns:
            if re.search(pat, content):
                bad("d", f"{rel} contains {what}")

if fm is not None:
    # ---------- (e) ----------
    raw = fm.get("allowed-tools")
    if raw is None:
        tools = []
    elif isinstance(raw, str):
        # space- or comma-separated; a rule's parentheses may contain spaces
        tools = re.findall(r"[^\s,()]+(?:\([^)]*\))?", raw)
    elif isinstance(raw, list):
        tools = [str(t).strip() for t in raw]
    else:
        raise SystemExit(f"allowed-tools has unsupported type {type(raw).__name__}")
    if sorted(tools) != sorted(ALLOWED_RULES):
        bad("e", f"allowed-tools must be exactly {sorted(ALLOWED_RULES)}; found {tools}")
    if "hooks" in fm:
        bad("e", "frontmatter sets hooks (they run without a permission prompt)")
if body is not None and re.search(r"!`|```!", body):
    bad("e", "skill body has a !`command` or ```! block (runs before Claude sees the skill)")

if fm is not None:
    # ---------- (f) ----------
    key = "disable-model-invocation"
    if not (fm.get(key) is True and str(fm_raw.get(key, "")).strip().lower() == "true"):
        bad("f", f"{key} is not the unquoted literal true (found {fm_raw.get(key)!r})")

    # ---------- (n) ----------
    if fm.get("name") != "archive-lines":
        bad("n", f"name must be archive-lines (found {fm.get('name')!r})")

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
report b  "every script path in the skill is \${CLAUDE_PLUGIN_ROOT}/scripts/line-save-chat.sh"
report c  "no \$0, \$(dirname) or unbraced \$CLAUDE_PLUGIN_ROOT"
report d  "no hard-coded per-machine path in the plugin"
report e  "allowed-tools pre-approves only save/test/help of the bundled script"
report f  "disable-model-invocation: true"
report n  "name: archive-lines"

echo
if [ "$FAILURES" -gt 0 ]; then
    echo "$FAILURES check(s) failed"
    exit 1
fi
echo "all checks passed"
