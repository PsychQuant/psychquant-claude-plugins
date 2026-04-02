#!/bin/bash
# PostToolUse hook: auto lake build after editing .lean files
#
# Triggered by: Edit, Write tools on *.lean files
# Returns: lake build output (errors/warnings) for immediate feedback
#
# Hook config in plugin.json:
#   "hooks": [{
#     "type": "PostToolUse",
#     "matcher": { "tool": ["Edit", "Write"], "filePath": "*.lean" },
#     "command": "hooks/lake-build-on-edit.sh"
#   }]

# Get the edited file path from CLAUDE_TOOL_INPUT
FILE_PATH=$(echo "$CLAUDE_TOOL_INPUT" | jq -r '.file_path // .filePath // empty')

# Only trigger for .lean files (not in .lake/)
if [[ "$FILE_PATH" != *.lean ]] || [[ "$FILE_PATH" == *.lake/* ]]; then
  exit 0
fi

# Find project root (directory containing lakefile.toml)
DIR=$(dirname "$FILE_PATH")
while [[ "$DIR" != "/" ]]; do
  if [[ -f "$DIR/lakefile.toml" ]] || [[ -f "$DIR/lakefile.lean" ]]; then
    PROJECT_ROOT="$DIR"
    break
  fi
  DIR=$(dirname "$DIR")
done

if [[ -z "$PROJECT_ROOT" ]]; then
  echo "⚠ No lakefile.toml found — skipping lake build"
  exit 0
fi

# Run lake build
cd "$PROJECT_ROOT"
OUTPUT=$(lake build 2>&1)
EXIT_CODE=$?

# Count sorries and errors
SORRY_COUNT=$(echo "$OUTPUT" | grep -c "declaration uses 'sorry'" || true)
ERROR_COUNT=$(echo "$OUTPUT" | grep -c "error:" || true)

if [[ $EXIT_CODE -eq 0 ]] && [[ $ERROR_COUNT -eq 0 ]]; then
  if [[ $SORRY_COUNT -eq 0 ]]; then
    echo "✓ lake build clean — zero sorry!"
  else
    echo "✓ lake build ok — $SORRY_COUNT sorry remaining"
  fi
else
  echo "✗ lake build failed ($ERROR_COUNT errors, $SORRY_COUNT sorry)"
  echo ""
  # Show only error lines (not sorry warnings) for conciseness
  echo "$OUTPUT" | grep -A 2 "error:" | head -30
fi
