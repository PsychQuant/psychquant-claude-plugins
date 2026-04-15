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

    # Accept either "### Step 0" (plain) or "### Step 0.5" (when Step 0 is a gate).
    if grep -qE '^### Step 0(\.5)?:' "$skill_md"; then
        echo "OK    $skill_name"
    else
        echo "MISS  $skill_name"
        miss=$((miss + 1))
    fi
done

echo
echo "Summary: $((total - miss))/$total skills have Step 0 Bootstrap"
exit $miss
