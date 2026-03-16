#!/bin/bash
# E2E tests for archive-first v2.1.0 hooks
# Run from repo root: bash tests/archive-first/test_hooks.sh

set -uo pipefail

PASS=0
FAIL=0
HOOK_CACHE="$HOME/.cache/archive-first"

# --- Helpers ---

# Extract the Bash PreToolUse hook command from hooks.json
HOOK_CMD=$(python3 -c "
import json
with open('plugins/archive-first/hooks/hooks.json') as f:
    d = json.load(f)
for h in d['hooks']['PreToolUse']:
    if h['matcher'] == 'Bash':
        print(h['hooks'][0]['command'])
        break
")

# Extract the Write PreToolUse hook command
WRITE_HOOK_CMD=$(python3 -c "
import json
with open('plugins/archive-first/hooks/hooks.json') as f:
    d = json.load(f)
for h in d['hooks']['PreToolUse']:
    if h['matcher'] == 'Write':
        print(h['hooks'][0]['command'])
        break
")

# Extract the Edit PreToolUse hook command
EDIT_HOOK_CMD=$(python3 -c "
import json
with open('plugins/archive-first/hooks/hooks.json') as f:
    d = json.load(f)
for h in d['hooks']['PreToolUse']:
    if h['matcher'] == 'Edit':
        print(h['hooks'][0]['command'])
        break
")

run_bash_hook() {
    local command="$1"
    local json_input=$(jq -n --arg cmd "$command" '{tool_input: {command: $cmd}}')
    echo "$json_input" | bash -c "$HOOK_CMD" 2>/dev/null || true
}

run_write_hook() {
    local file_path="$1"
    local json_input=$(jq -n --arg fp "$file_path" '{tool_input: {file_path: $fp}}')
    echo "$json_input" | bash -c "$WRITE_HOOK_CMD" 2>/dev/null || true
}

run_edit_hook() {
    local file_path="$1"
    local json_input=$(jq -n --arg fp "$file_path" '{tool_input: {file_path: $fp}}')
    echo "$json_input" | bash -c "$EDIT_HOOK_CMD" 2>/dev/null || true
}

assert_blocked() {
    local test_name="$1"
    local output="$2"
    if echo "$output" | grep -q '"deny"'; then
        echo "  ✅ PASS: $test_name"
        ((PASS++))
    else
        echo "  ❌ FAIL: $test_name (expected deny, got: $output)"
        ((FAIL++))
    fi
}

assert_allowed() {
    local test_name="$1"
    local output="$2"
    if [ -z "$output" ] || ! echo "$output" | grep -q '"deny"'; then
        echo "  ✅ PASS: $test_name"
        ((PASS++))
    else
        echo "  ❌ FAIL: $test_name (expected allow, got: $output)"
        ((FAIL++))
    fi
}

# --- Setup: ensure locked state ---
rm -f "$HOOK_CACHE/disabled"

echo ""
echo "=== archive-first E2E Tests ==="
echo ""

# --- Test 1: rm targeting archived → blocked ---
echo "--- Bash hook (locked state) ---"
output=$(run_bash_hook "rm -rf archived/backup")
assert_blocked "rm -rf archived/backup" "$output"

# --- Test 2: rm not targeting archived → allowed ---
output=$(run_bash_hook "rm /tmp/foo.txt")
assert_allowed "rm /tmp/foo.txt (no archived)" "$output"

# --- Test 3: compound command, rm not targeting archived → allowed ---
output=$(run_bash_hook "rm /tmp/foo && mv bar archived/dest")
assert_allowed "rm /tmp/foo && mv bar archived/ (rm not on archived)" "$output"

# --- Test 4: rmdir on archived → blocked ---
output=$(run_bash_hook "rmdir archived/old")
assert_blocked "rmdir archived/old" "$output"

# --- Test 5: unlink on archived → blocked ---
output=$(run_bash_hook "unlink archived/file.txt")
assert_blocked "unlink archived/file.txt" "$output"

# --- Test 6: normal command mentioning archived → allowed ---
output=$(run_bash_hook "ls archived/")
assert_allowed "ls archived/ (not destructive)" "$output"

# --- Test 7: Write to archived path → blocked ---
echo ""
echo "--- Write hook (locked state) ---"
output=$(run_write_hook "/Users/che/projects/archived/file.txt")
assert_blocked "Write to /Users/che/projects/archived/file.txt" "$output"

# --- Test 8: Write to non-archived path → allowed ---
output=$(run_write_hook "/Users/che/projects/src/file.txt")
assert_allowed "Write to /Users/che/projects/src/file.txt" "$output"

# --- Test 9: Edit archived path → blocked ---
echo ""
echo "--- Edit hook (locked state) ---"
output=$(run_edit_hook "/Users/che/projects/archived/file.txt")
assert_blocked "Edit /Users/che/projects/archived/file.txt" "$output"

# --- Test 10: Edit non-archived path → allowed ---
output=$(run_edit_hook "/Users/che/projects/src/file.txt")
assert_allowed "Edit /Users/che/projects/src/file.txt" "$output"

# --- Test 11: Unlock (disabled flag) → rm archived allowed ---
echo ""
echo "--- Unlocked state ---"
mkdir -p "$HOOK_CACHE"
touch "$HOOK_CACHE/disabled"

output=$(run_bash_hook "rm -rf archived/backup")
assert_allowed "rm -rf archived/backup (UNLOCKED)" "$output"

output=$(run_write_hook "/Users/che/projects/archived/file.txt")
assert_allowed "Write to archived (UNLOCKED)" "$output"

output=$(run_edit_hook "/Users/che/projects/archived/file.txt")
assert_allowed "Edit archived (UNLOCKED)" "$output"

# --- Test 12: Re-lock → rm archived blocked again ---
echo ""
echo "--- Re-locked state ---"
rm -f "$HOOK_CACHE/disabled"

output=$(run_bash_hook "rm -rf archived/backup")
assert_blocked "rm -rf archived/backup (RE-LOCKED)" "$output"

# --- Summary ---
echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
