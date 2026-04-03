#!/bin/bash
# GiftHub PostToolUse hook — auto-install gfh after successful swift build
#
# Triggers on: Bash tool calls containing "swift build" that succeeded
# Only in the GiftHub development repo

# Read hook data from stdin (JSON)
HOOK_DATA=$(cat)
COMMAND=$(echo "$HOOK_DATA" | jq -r '.tool_input.command // empty')

# Only in GiftHub repo
if [ ! -f "Package.swift" ] || ! grep -q '"GiftHub"' Package.swift 2>/dev/null; then
  exit 0
fi

# Check if the command contains swift build
if ! echo "$COMMAND" | grep -q "swift build"; then
  exit 0
fi

# Skip if it was already a release build (avoid infinite loop)
if echo "$COMMAND" | grep -q "\-c release"; then
  exit 0
fi

# Check the build actually succeeded (look for "Build complete" in output)
TOOL_OUTPUT=$(echo "$HOOK_DATA" | jq -r '.tool_response // empty')
if ! echo "$TOOL_OUTPUT" | grep -q "Build complete"; then
  exit 0
fi

# Do the release build + install
swift build -c release -q 2>/dev/null
if [ $? -eq 0 ]; then
  cp .build/release/gfh "$HOME/bin/gfh"
  echo "gfh auto-installed to ~/bin/gfh"
else
  echo "gfh release build failed — skipping auto-install"
fi
