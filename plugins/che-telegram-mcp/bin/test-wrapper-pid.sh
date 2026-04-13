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
    OLD_PID=\$(cat "\$PID_FILE" 2>/dev/null)
    if [[ -n "\$OLD_PID" ]] && kill -0 "\$OLD_PID" 2>/dev/null; then
        if ps -p "\$OLD_PID" -o comm= 2>/dev/null | grep -q "\$BINARY_NAME"; then
            kill -TERM "\$OLD_PID" 2>/dev/null
            sleep 0.5
            kill -0 "\$OLD_PID" 2>/dev/null && kill -KILL "\$OLD_PID" 2>/dev/null
        fi
    fi
fi

"\$BINARY" $sleep_duration &
BIN_PID=\$!
echo "\$BIN_PID" > "\$PID_FILE"

cleanup() {
    rm -f "\$PID_FILE"
    if [[ -n "\$BIN_PID" ]] && kill -0 "\$BIN_PID" 2>/dev/null; then
        kill -TERM "\$BIN_PID" 2>/dev/null
        wait "\$BIN_PID" 2>/dev/null
    fi
}
trap cleanup EXIT INT TERM

wait "\$BIN_PID"
exit \$?
EOF
    chmod +x "$out"
}

TMPDIR=$(mktemp -d)
trap "rm -rf '$TMPDIR'" EXIT

# ----------------------------------------------------------------------
test_case "PID file created on start, removed on clean exit"
PID_FILE="$TMPDIR/test1.pid"
make_fake_wrapper "$TMPDIR/wrapper1.sh" "$PID_FILE" "sleep" "2"
"$TMPDIR/wrapper1.sh" &
WRAPPER_PID=$!
sleep 0.5
if [[ -f "$PID_FILE" ]]; then
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

make_fake_wrapper "$TMPDIR/wrapper2.sh" "$PID_FILE" "sleep" "2"
"$TMPDIR/wrapper2.sh" &
WRAPPER_PID=$!
sleep 0.5
if ! kill -0 "$ORPHAN_PID" 2>/dev/null; then
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
# tail -f /dev/null sits forever; comm name = "tail"
/usr/bin/tail -f /dev/null &
UNRELATED_PID=$!
echo "$UNRELATED_PID" > "$PID_FILE"
sleep 0.2
if ! kill -0 "$UNRELATED_PID" 2>/dev/null; then
    fail "unrelated process setup failed (tail died unexpectedly)"
fi

# Wrapper looks for "sleep" as BINARY_NAME, but PID points to "tail"
make_fake_wrapper "$TMPDIR/wrapper3.sh" "$PID_FILE" "sleep" "2"
"$TMPDIR/wrapper3.sh" &
WRAPPER_PID=$!
sleep 0.5
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

make_fake_wrapper "$TMPDIR/wrapper4.sh" "$PID_FILE" "sleep" "2"
"$TMPDIR/wrapper4.sh" &
WRAPPER_PID=$!
sleep 0.5
if [[ -f "$PID_FILE" ]]; then
    NEW_PID=$(cat "$PID_FILE")
    if [[ "$NEW_PID" != "99999" ]] && kill -0 "$NEW_PID" 2>/dev/null; then
        pass "stale PID replaced with live PID ($NEW_PID)"
    else
        fail "stale PID not handled correctly (got $NEW_PID)"
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
sleep 0.5
BIN_PID=$(cat "$PID_FILE" 2>/dev/null)
if [[ -z "$BIN_PID" ]]; then
    fail "could not read BIN_PID"
else
    kill -TERM "$WRAPPER_PID"
    sleep 0.5
    if ! kill -0 "$BIN_PID" 2>/dev/null; then
        pass "binary terminated when wrapper received SIGTERM"
    else
        fail "binary survived wrapper SIGTERM (PID $BIN_PID still alive)"
        kill -KILL "$BIN_PID" 2>/dev/null
    fi
fi
wait "$WRAPPER_PID" 2>/dev/null

# ----------------------------------------------------------------------
echo ""
echo "Results: $((TOTAL - FAIL))/$TOTAL passed"
exit $FAIL
