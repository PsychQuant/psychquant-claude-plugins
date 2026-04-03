#!/bin/bash
# GiftHub PostToolUse hook — auto-install gfh after successful swift build
#
# Triggers on: Bash tool calls containing "swift build" that succeeded
# Only in the GiftHub development repo

# Only care about Bash tool
if [ "$TOOL_NAME" != "Bash" ]; then
  exit 0
fi

# Only in GiftHub repo
if [ ! -f "Package.swift" ] || ! grep -q '"GiftHub"' Package.swift 2>/dev/null; then
  exit 0
fi

# Check if the command was swift build and it succeeded
if [ "$EXIT_CODE" != "0" ]; then
  exit 0
fi

# Check tool input contains swift build (but not swift test, swift build -c release already)
TOOL_INPUT="${TOOL_INPUT:-}"
if ! echo "$TOOL_INPUT" | grep -q "swift build"; then
  exit 0
fi

# Skip if it was already a release build + copy (avoid infinite loop)
if echo "$TOOL_INPUT" | grep -q "release"; then
  exit 0
fi

# Do the release build + install
echo "Auto-installing gfh to ~/bin/..."
swift build -c release -q 2>/dev/null
if [ $? -eq 0 ]; then
  cp .build/release/gfh "$HOME/bin/gfh"
  echo "gfh installed to ~/bin/gfh"
else
  echo "Release build failed — skipping auto-install"
fi
