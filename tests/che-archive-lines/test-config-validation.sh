#!/bin/bash
# Regression test for #149: config values must be integers before they reach
# bash arithmetic in scripts/line-save-chat.sh.
#
# bash evaluates array subscripts inside $((…)), so a config value such as
# a[$(cmd)] runs cmd. load_config read three values with grep and passed them
# straight into $((…)) in `save` and `test`; calibrate wrote whatever the user
# typed as menu_offset_y. Each case below plants a payload that would create a
# marker file, then checks the marker never appears and nothing is clicked.
#
# The script never touches the real mouse here: a stub directory first on PATH
# provides cliclick (logs its arguments; `p` prints a fixed position) and
# osascript (prints a fixed LINE window for the System Events query, nothing
# otherwise), and HOME points at a scratch directory so the real config under
# ~/.config/che-archive-lines is never read or written.
#
# Usage:
#   bash tests/che-archive-lines/test-config-validation.sh

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="$(cd "$SCRIPT_DIR/../../plugins/che-archive-lines/scripts" && pwd)/line-save-chat.sh"
SCRATCH=$(mktemp -d "${TMPDIR:-/tmp}/archive-lines-config-XXXXXX") || { echo "✗ mktemp failed" >&2; exit 1; }
[ -n "$SCRATCH" ] && [ -d "$SCRATCH" ] || { echo "✗ scratch dir missing" >&2; exit 1; }
trap 'rm -rf "$SCRATCH"' EXIT

STUB="$SCRATCH/stub"
mkdir -p "$STUB"
# STUB_POS / STUB_WINDOW override what the stubs report (default: a sane
# cursor position and LINE window), so a case can feed a payload through them.
cat > "$STUB/cliclick" <<EOF
#!/bin/bash
echo "\$*" >> "$SCRATCH/clicks.log"
[ "\$1" = p ] && echo "\${STUB_POS:-500,300}"
exit 0
EOF
cat > "$STUB/osascript" <<'EOF'
#!/bin/bash
case "$*" in *"System Events"*) echo "${STUB_WINDOW:-100 100 800 600}" ;; esac
exit 0
EOF
chmod +x "$STUB/cliclick" "$STUB/osascript"

PASSED=0
FAILED=0
CONFIG="$SCRATCH/home/.config/che-archive-lines/config.json"
MARK="$SCRATCH/PWNED"

reset() {
    rm -rf "$SCRATCH/home" "$SCRATCH/clicks.log" "$MARK"
    mkdir -p "$SCRATCH/home"
}
write_config() {  # $1 offset_x, $2 offset_y, $3 menu_offset_y line (empty = omit)
    mkdir -p "$(dirname "$CONFIG")"
    {
        echo '{'
        echo '  "version": "1.0",'
        echo "  \"offset_x\": $1,"
        echo "  \"offset_y\": $2,"
        [ -n "$3" ] && echo "  \"menu_offset_y\": $3,"
        echo '  "description": "x"'
        echo '}'
    } > "$CONFIG"
}
run() {  # $@ = script arguments; stdin passes through. Runs the script by its
         # shebang (/bin/bash, 3.2 on macOS), as the skill does — not PATH's bash.
    HOME="$SCRATCH/home" PATH="$STUB:$PATH" "$TARGET" "$@" > "$SCRATCH/out.log" 2>&1
}
ok()   { echo "  ✓ $1"; PASSED=$((PASSED + 1)); }
bad()  { echo "  ✗ $1"; sed 's/^/      /' "$SCRATCH/out.log"; FAILED=$((FAILED + 1)); }
clicks() { cat "$SCRATCH/clicks.log" 2>/dev/null | grep -v '^p$' || true; }

expect_rejected() {  # $1 name, then script args; the run must fail, run no payload, click nothing
    local name="$1"; shift
    run "$@"; local rc=$?
    if [ "$rc" -ne 0 ] && [ ! -e "$MARK" ] && [ -z "$(clicks)" ]; then ok "$name"
    else bad "$name (exit $rc, payload ran: $([ -e "$MARK" ] && echo yes || echo no), clicks: $(clicks | tr '\n' ' '))"; fi
}

# load_config strips spaces (tr -d ' ') and stops at the first , or }, so the
# payload uses an unbraced $IFS for the space. (A ${IFS} payload is cut off at
# its } by that grep, which hides the bug instead of testing it.)
PAYLOAD="a[\$(touch\$IFS$MARK)]"
case "$MARK" in
    *[[:space:],:}]*) echo "✗ scratch path $MARK contains a space, comma, colon or } — the payload would be cut off and every payload case would pass vacuously"; exit 1 ;;
esac
[ -x "$TARGET" ] || { echo "✗ $TARGET is not executable"; exit 1; }

echo "test-config-validation.sh (#149)"

# ---- valid config: save and test click where expected ----
reset; write_config -20 30 240
run save; rc=$?
if [ "$rc" -eq 0 ] && [ "$(clicks | tr '\n' ' ')" = "c:880,130 c:880,370 " ]; then ok "valid config: save clicks ⋮ and the menu item"
else bad "valid config: save (exit $rc, clicks: $(clicks | tr '\n' ' '))"; fi
reset; write_config -20 30 240
run test; rc=$?
if [ "$rc" -eq 0 ] && [ "$(clicks | tr '\n' ' ')" = "c:880,130 " ]; then ok "valid config: test clicks ⋮ only"
else bad "valid config: test (exit $rc, clicks: $(clicks | tr '\n' ' '))"; fi
reset; write_config -20 30 ""
run save; rc=$?
if [ "$rc" -eq 0 ] && [ "$(clicks | tr '\n' ' ')" = "c:880,130 c:880,370 " ]; then ok "menu_offset_y missing: defaults to 240"
else bad "menu_offset_y missing (exit $rc, clicks: $(clicks | tr '\n' ' '))"; fi

# ---- read side: every value that reaches $((…)) ----
reset; write_config "$PAYLOAD" 30 240;  expect_rejected "offset_x payload (save)" save
reset; write_config "$PAYLOAD" 30 240;  expect_rejected "offset_x payload (test)" test
reset; write_config -20 "$PAYLOAD" 240; expect_rejected "offset_y payload (save)" save
reset; write_config -20 "$PAYLOAD" 240; expect_rejected "offset_y payload (test)" test
reset; write_config -20 30 "$PAYLOAD";  expect_rejected "menu_offset_y payload (save)" save
reset; write_config -20 30 "x+1";       expect_rejected "expression instead of a number" save
reset; write_config -20 30 "010";       expect_rejected "leading zero (bash reads it as octal)" save
reset; write_config -20 30 "1234567";   expect_rejected "more than six digits" save

# A key that appears twice: grep returns both lines, and is_int must reject the
# pair as a whole (a per-line check would accept the valid second line).
reset; write_config -20 30 240; printf '{\n  "offset_x": %s,\n  "offset_x": -20,\n  "offset_y": 30\n}\n' "$PAYLOAD" > "$CONFIG"
expect_rejected "duplicate key: payload line then a valid line (save)" save
reset; write_config -20 30 240; printf '{\n  "offset_x": %s,\n  "offset_x": -20,\n  "offset_y": 30\n}\n' "$PAYLOAD" > "$CONFIG"
expect_rejected "duplicate key: payload line then a valid line (test)" test
# menu_offset_y present but unreadable must stop, not fall back to 240
reset; write_config -20 30 " ";         expect_rejected "menu_offset_y present but empty" save
reset; write_config -20 30 240; printf '{\n  "offset_x": -20,\n  "offset_y": 30,\n  "menu_offset_y":\n    300,\n  "description": "x"\n}\n' > "$CONFIG"
expect_rejected "menu_offset_y value on the next line (grep cannot read it)" save

# ---- values from osascript and cliclick reach $((…)) too ----
reset; write_config -20 30 240
export STUB_WINDOW="$PAYLOAD 100 800 600"; expect_rejected "window position from osascript is a payload" save; unset STUB_WINDOW

# ---- messages: a bad config is not reported as "not calibrated" ----
reset; write_config -20 30 "x+1"; run save
if grep -q '整數' "$SCRATCH/out.log" && ! grep -q '尚未校準' "$SCRATCH/out.log"; then ok "invalid config: one message, not \"not calibrated\""
else bad "invalid config message"; fi
reset; run save
if grep -q '尚未校準' "$SCRATCH/out.log"; then ok "missing config: \"not calibrated\""
else bad "missing config message"; fi

# ---- write side: calibrate stores only integers ----
reset
printf '\n%s\n' "$PAYLOAD" | run calibrate; rc=$?
if [ "$rc" -ne 0 ] && [ ! -e "$CONFIG" ] && [ ! -e "$MARK" ]; then ok "calibrate refuses a non-integer menu offset and writes nothing"
else bad "calibrate payload (exit $rc, config written: $([ -e "$CONFIG" ] && echo yes || echo no))"; fi
reset
export STUB_POS="$PAYLOAD,300"
printf '\n250\n' | run calibrate; rc=$?
unset STUB_POS
if [ "$rc" -ne 0 ] && [ ! -e "$CONFIG" ] && [ ! -e "$MARK" ]; then ok "calibrate refuses a cursor position that is not an integer"
else bad "calibrate cursor payload (exit $rc, config written: $([ -e "$CONFIG" ] && echo yes || echo no), payload ran: $([ -e "$MARK" ] && echo yes || echo no))"; fi
reset
printf '\n250\n' | run calibrate; rc=$?
if [ "$rc" -eq 0 ] && grep -q '"menu_offset_y": 250,' "$CONFIG" && grep -q '"offset_x": -400,' "$CONFIG" && grep -q '"offset_y": 200,' "$CONFIG"
then ok "calibrate stores the computed offsets and a typed menu offset"
else bad "calibrate valid (exit $rc): $(tr '\n' ' ' < "$CONFIG" 2>/dev/null)"; fi
reset
printf '\n\n' | run calibrate; rc=$?
if [ "$rc" -eq 0 ] && grep -q '"menu_offset_y": 240,' "$CONFIG"; then ok "calibrate: an empty menu offset stores the default 240"
else bad "calibrate empty (exit $rc): $(tr '\n' ' ' < "$CONFIG" 2>/dev/null)"; fi

echo
echo "Results: $PASSED passed, $FAILED failed"
[ "$FAILED" -eq 0 ]
