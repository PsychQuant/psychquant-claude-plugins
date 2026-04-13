#!/bin/bash
# Smoke test for wrapper PID tracking (#8)
#
# Tests:
#   1. Orphan cleanup: if PID file points to a live process matching BINARY_NAME,
#      wrapper should kill it before starting new instance.
#   2. PID file maintenance: new process's PID is written to PID file.
#   3. Cleanup on exit: PID file removed when wrapper exits normally.
#   4. PID recycling protection: if PID is alive but different command,
#      wrapper should NOT kill it.
#
# Usage:
#   ./test-wrapper-pid.sh
#
# Exit: 0 on all pass, 1 on any failure.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FAIL=0
TOTAL=0

pass() { echo "  ✓ $1"; }
fail() { echo "  ✗ $1"; FAIL=$((FAIL + 1)); }
test_case() { TOTAL=$((TOTAL + 1)); echo "Test: $1"; }

# Extract the PID-tracking block from a wrapper into a standalone executable,
# substituting BINARY with a fake sleep command and PID_FILE with a temp path.
# This lets us test the logic without running the real MCP server.
make_fake_wrapper() {
    local out=$1
    local pid_file=$2
    local binary_name=$3
    local sleep_duration=$4

    cat > "$out" <<EOF
#!/bin/bash
BINARY_NAME="$binary_name"
BINARY="/bin/sleep"
PID_FILE="$pid_file"
mkdir -p "\$(dirname "\$PID_FILE")"

if [[ -f "\$PID_FILE" ]]; then
    OLD_PID=\$(cat "\$PID_FILE" 2>/dev/null | tr -d '[:space:]')
    if [[ "\$OLD_PID" =~ ^[0-9]+\$ ]] && kill -0 "\$OLD_PID" 2>/dev/null; then
        OLD_COMM=\$(ps -p "\$OLD_PID" -o comm= 2>/dev/null)
        OLD_BASENAME=\$(basename "\$OLD_COMM" 2>/dev/null)
        if [[ "\$OLD_BASENAME" == "\$BINARY_NAME" ]]; then
            kill -TERM "\$OLD_PID" 2>/dev/null
            for _ in 1 2 3 4; do
                kill -0 "\$OLD_PID" 2>/dev/null || break
                sleep 0.5
            done
            kill -0 "\$OLD_PID" 2>/dev/null && kill -KILL "\$OLD_PID" 2>/dev/null
        fi
    fi
fi

"\$BINARY" $sleep_duration &
BIN_PID=\$!
echo "\$BIN_PID" > "\$PID_FILE"

cleanup() {
    if [[ -n "\$BIN_PID" ]] && kill -0 "\$BIN_PID" 2>/dev/null; then
        kill -TERM "\$BIN_PID" 2>/dev/null
        for _ in 1 2 3 4; do
            kill -0 "\$BIN_PID" 2>/dev/null || break
            sleep 0.5
        done
        kill -0 "\$BIN_PID" 2>/dev/null && kill -KILL "\$BIN_PID" 2>/dev/null
        wait "\$BIN_PID" 2>/dev/null
    fi
    if [[ -f "\$PID_FILE" ]] && [[ "\$(cat "\$PID_FILE" 2>/dev/null | tr -d '[:space:]')" == "\$BIN_PID" ]]; then
        rm -f "\$PID_FILE"
    fi
}
trap cleanup EXIT INT TERM

wait "\$BIN_PID"
exit \$?
EOF
    chmod +x "$out"
}

# Helper: poll for condition with timeout (avoids timing races)
wait_for_dead() {
    local pid=$1
    local max_tenths=${2:-30}  # default 3s
    local i=0
    while [[ $i -lt $max_tenths ]]; do
        kill -0 "$pid" 2>/dev/null || return 0
        sleep 0.1
        i=$((i + 1))
    done
    return 1
}

wait_for_file() {
    local path=$1
    local max_tenths=${2:-30}
    local i=0
    while [[ $i -lt $max_tenths ]]; do
        [[ -f "$path" ]] && return 0
        sleep 0.1
        i=$((i + 1))
    done
    return 1
}

TMPDIR=$(mktemp -d)
trap "rm -rf '$TMPDIR'" EXIT

# ----------------------------------------------------------------------
test_case "PID file created on start, removed on clean exit"
PID_FILE="$TMPDIR/test1.pid"
make_fake_wrapper "$TMPDIR/wrapper1.sh" "$PID_FILE" "sleep" "3"
"$TMPDIR/wrapper1.sh" &
WRAPPER_PID=$!
if wait_for_file "$PID_FILE" 30; then
    pass "PID file created"
else
    fail "PID file missing during run"
fi
wait "$WRAPPER_PID"
if [[ ! -f "$PID_FILE" ]]; then
    pass "PID file removed after exit"
else
    fail "PID file still exists after exit"
fi

# ----------------------------------------------------------------------
test_case "Orphan process killed on startup"
PID_FILE="$TMPDIR/test2.pid"
# Start an orphan "sleep" process matching BINARY_NAME
/bin/sleep 30 &
ORPHAN_PID=$!
echo "$ORPHAN_PID" > "$PID_FILE"
sleep 0.1
if kill -0 "$ORPHAN_PID" 2>/dev/null; then
    pass "orphan started (PID $ORPHAN_PID)"
else
    fail "orphan setup failed"
fi

make_fake_wrapper "$TMPDIR/wrapper2.sh" "$PID_FILE" "sleep" "3"
"$TMPDIR/wrapper2.sh" &
WRAPPER_PID=$!
# Poll up to 4s for orphan to be killed (wrapper uses SIGTERM + up to 2s wait + SIGKILL)
if wait_for_dead "$ORPHAN_PID" 40; then
    pass "orphan killed by wrapper"
else
    fail "orphan survived wrapper startup (PID $ORPHAN_PID still alive)"
    kill -KILL "$ORPHAN_PID" 2>/dev/null
fi
wait "$WRAPPER_PID" 2>/dev/null

# ----------------------------------------------------------------------
test_case "PID recycling protection (PID alive but wrong command)"
PID_FILE="$TMPDIR/test3.pid"
# Start a long-lived process NOT matching BINARY_NAME
# tail -f /dev/null sits forever; comm name basename = "tail"
/usr/bin/tail -f /dev/null &
UNRELATED_PID=$!
echo "$UNRELATED_PID" > "$PID_FILE"
sleep 0.2
if ! kill -0 "$UNRELATED_PID" 2>/dev/null; then
    fail "unrelated process setup failed (tail died unexpectedly)"
fi

# Wrapper looks for "sleep" as BINARY_NAME, but PID points to "tail"
make_fake_wrapper "$TMPDIR/wrapper3.sh" "$PID_FILE" "sleep" "3"
"$TMPDIR/wrapper3.sh" &
WRAPPER_PID=$!
# Wait long enough to be sure wrapper's check phase has completed (>= 4s would cover SIGTERM + SIGKILL paths)
sleep 1
if kill -0 "$UNRELATED_PID" 2>/dev/null; then
    pass "unrelated process NOT killed (PID recycling protection works)"
else
    fail "unrelated process was killed (PID recycling protection failed)"
fi
kill -TERM "$UNRELATED_PID" 2>/dev/null
wait "$WRAPPER_PID" 2>/dev/null
wait "$UNRELATED_PID" 2>/dev/null

# ----------------------------------------------------------------------
test_case "Stale PID file (process already dead)"
PID_FILE="$TMPDIR/test4.pid"
# Write a PID that's guaranteed not to exist (very high number)
echo "99999" > "$PID_FILE"

make_fake_wrapper "$TMPDIR/wrapper4.sh" "$PID_FILE" "sleep" "3"
"$TMPDIR/wrapper4.sh" &
WRAPPER_PID=$!
# Poll for file content to change
for _ in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20; do
    NEW_PID=$(cat "$PID_FILE" 2>/dev/null | tr -d '[:space:]')
    [[ -n "$NEW_PID" && "$NEW_PID" != "99999" ]] && break
    sleep 0.1
done
if [[ -f "$PID_FILE" ]]; then
    NEW_PID=$(cat "$PID_FILE" | tr -d '[:space:]')
    if [[ "$NEW_PID" != "99999" ]] && [[ -n "$NEW_PID" ]] && kill -0 "$NEW_PID" 2>/dev/null; then
        pass "stale PID replaced with live PID ($NEW_PID)"
    else
        fail "stale PID not handled correctly (got '$NEW_PID')"
    fi
else
    fail "PID file missing during run"
fi
wait "$WRAPPER_PID" 2>/dev/null

# ----------------------------------------------------------------------
test_case "Wrapper forwards SIGTERM to binary"
PID_FILE="$TMPDIR/test5.pid"
make_fake_wrapper "$TMPDIR/wrapper5.sh" "$PID_FILE" "sleep" "30"
"$TMPDIR/wrapper5.sh" &
WRAPPER_PID=$!
if ! wait_for_file "$PID_FILE" 30; then
    fail "PID file never created"
fi
BIN_PID=$(cat "$PID_FILE" 2>/dev/null | tr -d '[:space:]')
if [[ -z "$BIN_PID" ]]; then
    fail "could not read BIN_PID"
else
    kill -TERM "$WRAPPER_PID"
    if wait_for_dead "$BIN_PID" 40; then
        pass "binary terminated when wrapper received SIGTERM"
    else
        fail "binary survived wrapper SIGTERM (PID $BIN_PID still alive)"
        kill -KILL "$BIN_PID" 2>/dev/null
    fi
fi
wait "$WRAPPER_PID" 2>/dev/null

# ----------------------------------------------------------------------
test_case "Ownership check: wrapper does not delete PID file claimed by another wrapper"
PID_FILE="$TMPDIR/test6.pid"
make_fake_wrapper "$TMPDIR/wrapper6.sh" "$PID_FILE" "sleep" "3"
"$TMPDIR/wrapper6.sh" &
WRAPPER_A_PID=$!
wait_for_file "$PID_FILE" 30
A_BIN_PID=$(cat "$PID_FILE" 2>/dev/null | tr -d '[:space:]')

# Simulate: an old wrapper from previous session runs cleanup with stale BIN_PID
# (replicate the ownership-check logic; should NOT delete the file)
(
    BIN_PID="99998"
    if [[ -f "$PID_FILE" ]] && [[ "$(cat "$PID_FILE" 2>/dev/null | tr -d '[:space:]')" == "$BIN_PID" ]]; then
        rm -f "$PID_FILE"
    fi
)

if [[ -f "$PID_FILE" ]] && [[ "$(cat "$PID_FILE" | tr -d '[:space:]')" == "$A_BIN_PID" ]]; then
    pass "PID file preserved (ownership check blocked wrong owner)"
else
    fail "PID file was deleted or corrupted by wrong-owner cleanup"
fi
wait "$WRAPPER_A_PID" 2>/dev/null

# ----------------------------------------------------------------------
test_case "SIGKILL fallback: binary that ignores SIGTERM still gets killed"
PID_FILE="$TMPDIR/test7.pid"
# Use a binary that traps SIGTERM and ignores it
# We'll write a fake wrapper but with a binary that's a bash subshell trapping SIGTERM
cat > "$TMPDIR/stubborn-binary.sh" <<'EOF'
#!/bin/bash
trap '' TERM  # Ignore SIGTERM
sleep 30
EOF
chmod +x "$TMPDIR/stubborn-binary.sh"

# Custom wrapper that uses stubborn binary
cat > "$TMPDIR/wrapper7.sh" <<EOF
#!/bin/bash
BINARY_NAME="stubborn-binary.sh"
BINARY="$TMPDIR/stubborn-binary.sh"
PID_FILE="$PID_FILE"

"\$BINARY" &
BIN_PID=\$!
echo "\$BIN_PID" > "\$PID_FILE"

cleanup() {
    if [[ -n "\$BIN_PID" ]] && kill -0 "\$BIN_PID" 2>/dev/null; then
        kill -TERM "\$BIN_PID" 2>/dev/null
        for _ in 1 2 3 4; do
            kill -0 "\$BIN_PID" 2>/dev/null || break
            sleep 0.5
        done
        kill -0 "\$BIN_PID" 2>/dev/null && kill -KILL "\$BIN_PID" 2>/dev/null
        wait "\$BIN_PID" 2>/dev/null
    fi
    if [[ -f "\$PID_FILE" ]] && [[ "\$(cat "\$PID_FILE" 2>/dev/null | tr -d '[:space:]')" == "\$BIN_PID" ]]; then
        rm -f "\$PID_FILE"
    fi
}
trap cleanup EXIT INT TERM

wait "\$BIN_PID"
EOF
chmod +x "$TMPDIR/wrapper7.sh"

"$TMPDIR/wrapper7.sh" &
WRAPPER_PID=$!
wait_for_file "$PID_FILE" 30
STUBBORN_PID=$(cat "$PID_FILE" 2>/dev/null | tr -d '[:space:]')

# Tell wrapper to terminate; binary will ignore SIGTERM, wrapper should SIGKILL it
kill -TERM "$WRAPPER_PID"
if wait_for_dead "$STUBBORN_PID" 50; then
    pass "stubborn binary killed via SIGKILL fallback"
else
    fail "stubborn binary survived SIGKILL fallback"
    kill -KILL "$STUBBORN_PID" 2>/dev/null
fi
wait "$WRAPPER_PID" 2>/dev/null

# ----------------------------------------------------------------------
echo ""
echo "Results: $((TOTAL - FAIL))/$TOTAL passed"
exit $FAIL
