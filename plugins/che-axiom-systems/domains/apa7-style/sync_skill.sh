#!/bin/bash
# sync_skill.sh - Sync YAML files to Claude Code skill folder
#
# Usage: ./sync_skill.sh
#
# This script copies the authority source YAML files to the skill folder
# to ensure the skill remains self-contained and up-to-date.

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="$SCRIPT_DIR/.claude/skills/apa-rewriter"

echo "=== Syncing APA Skill Files ==="
echo "Source: $SCRIPT_DIR"
echo "Target: $SKILL_DIR"
echo ""

# Ensure skill directory exists
mkdir -p "$SKILL_DIR"

# Copy transformation rules (required)
echo "Copying transformation rules..."
cp "$SCRIPT_DIR/02_transformation/forbidden_patterns.yaml" "$SKILL_DIR/"
cp "$SCRIPT_DIR/02_transformation/transformation_rules.yaml" "$SKILL_DIR/"

# Copy core axioms (optional but recommended)
echo "Copying core axioms..."
cp "$SCRIPT_DIR/01_core_axioms/writing_style.yaml" "$SKILL_DIR/"
cp "$SCRIPT_DIR/01_core_axioms/writing_guidelines.yaml" "$SKILL_DIR/"

echo ""
echo "=== Sync Complete ==="
echo ""
echo "Files in skill folder:"
ls -lh "$SKILL_DIR"/*.yaml

echo ""
echo "Remember to commit changes if needed:"
echo "  git add .claude/skills/apa-rewriter/"
echo "  git commit -m 'Sync skill YAML files'"
