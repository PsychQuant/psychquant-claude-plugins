#!/usr/bin/env bash
#
# Audit: every IDD skill MUST declare a Step 0 (or Step 0.5) Bootstrap
# Stage Task List section so TaskCreate tracks its execution.
#
# Exit code: number of skills missing the Bootstrap section.
# Exit 0 = all skills clean.
#
# Usage:
#   ./scripts/audit_step0_bootstrap.sh
#
# Reference: issue #27 (psychquant-claude-plugins).

set -uo pipefail

PLUGIN_SKILLS_DIR="plugins/issue-driven-dev/skills"
if [ ! -d "$PLUGIN_SKILLS_DIR" ]; then
    echo "ERROR: must run from repo root (expected $PLUGIN_SKILLS_DIR)" >&2
    exit 99
fi

miss=0
total=0
for skill_dir in "$PLUGIN_SKILLS_DIR"/*/; do
    skill_name=$(basename "$skill_dir")
    skill_md="${skill_dir}SKILL.md"
    [ -f "$skill_md" ] || continue
    total=$((total + 1))

    # Match the literal Bootstrap heading. Accepts both "### Step 0:" (plain) and
    # "### Step 0.5:" (used when Step 0 is a non-bootstrap gate, e.g. idd-close's
    # Checklist Gate Check). The "Bootstrap Stage Task List" literal prevents
    # false positives where Step 0 exists but is something other than a bootstrap
    # (this is the bug Codex caught in #27 verify).
    if grep -qE '^### Step 0(\.5)?: Bootstrap Stage Task List' "$skill_md"; then
        # Defence in depth: also verify a TaskCreate( appears in the file.
        # An empty bootstrap section (just heading, no tasks) is also a bug.
        if grep -q 'TaskCreate(' "$skill_md"; then
            echo "OK    $skill_name"
        else
            echo "MISS  $skill_name (Bootstrap heading present but no TaskCreate( found)"
            miss=$((miss + 1))
        fi
    else
        echo "MISS  $skill_name (no '### Step 0[.5]: Bootstrap Stage Task List' heading)"
        miss=$((miss + 1))
    fi
done

echo
echo "Summary: $((total - miss))/$total skills have Step 0 Bootstrap"
exit $miss
