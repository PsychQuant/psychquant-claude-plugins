#!/bin/bash
# GiftHub SessionStart hook — detect .gfh.json and inject context

# Only activate if .gfh.json exists in current directory
if [ ! -f ".gfh.json" ]; then
  exit 0
fi

# Check if gfh binary exists
GFH_BIN="$HOME/bin/gfh"
if [ -x "$GFH_BIN" ]; then
  GFH_VERSION=$("$GFH_BIN" version 2>/dev/null || echo "unknown")
  GFH_STATUS="gfh $GFH_VERSION installed at $GFH_BIN"
else
  GFH_STATUS="gfh NOT FOUND — build from ~/Developer/GiftHub: swift build -c release && cp .build/release/gfh ~/bin/"
fi

# Count pointer files
POINTER_COUNT=$(git ls-files 2>/dev/null | while read f; do
  if [ -f "$f" ] && [ "$(wc -c < "$f" 2>/dev/null)" -lt 200 ]; then
    head -1 "$f" 2>/dev/null | grep -q "^version https://git-lfs" && echo "$f"
  fi
done | wc -l | tr -d ' ')

cat <<EOF
# GiftHub Detected

$GFH_STATUS

## Quick Reference
| Command | Purpose |
|---------|---------|
| \`gfh pull [files...]\` | Download LFS objects from Google Drive |
| \`gfh upload <files...>\` | Upload to Drive + create LFS pointers |
| \`gfh clone <url>\` | Clone repo + auto-configure + pull |
| \`gfh dehydrate\` | Replace local files with pointers |

## Current Repo
- Pointer files: $POINTER_COUNT
- Config: .gfh.json

## Important
- Files < 200 bytes starting with \`version https://git-lfs\` are **LFS pointers** — run \`gfh pull\` to restore
- \`git push\` is safe (pre-push hook skips LFS upload)
- Use \`--concurrency N\` for parallel transfers (default 4)
EOF
