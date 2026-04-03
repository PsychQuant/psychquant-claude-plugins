#!/bin/bash
# GiftHub SessionStart hook — detect .gfh.json and inject context

# Only activate if .gfh.json exists in current directory
if [ ! -f ".gfh.json" ]; then
  exit 0
fi

GFH_BIN="$HOME/bin/gfh"
GFH_REPO="PsychQuant/GiftHub"
UPDATE_MSG=""

if [ -x "$GFH_BIN" ]; then
  LOCAL_VERSION=$("$GFH_BIN" version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "unknown")

  # Check for updates (quick, non-blocking)
  LATEST_VERSION=$(curl -fsSL --max-time 3 "https://api.github.com/repos/$GFH_REPO/releases/latest" 2>/dev/null | grep '"tag_name"' | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')

  if [ -n "$LATEST_VERSION" ] && [ "$LOCAL_VERSION" != "$LATEST_VERSION" ] && [ "$LOCAL_VERSION" != "unknown" ]; then
    UPDATE_MSG="⬆️  gfh v${LOCAL_VERSION} → v${LATEST_VERSION} available
   Update: curl -fsSL https://github.com/$GFH_REPO/releases/latest/download/gfh -o $GFH_BIN && chmod +x $GFH_BIN"
    GFH_STATUS="gfh v$LOCAL_VERSION (update available: v$LATEST_VERSION)"
  else
    GFH_STATUS="gfh v$LOCAL_VERSION"
  fi
else
  GFH_STATUS="gfh NOT FOUND"
  UPDATE_MSG="Install: curl -fsSL https://github.com/$GFH_REPO/releases/latest/download/gfh -o ~/bin/gfh && chmod +x ~/bin/gfh"
fi

# Count pointer files
POINTER_COUNT=$(git ls-files 2>/dev/null | while read f; do
  if [ -f "$f" ] && [ "$(wc -c < "$f" 2>/dev/null)" -lt 200 ]; then
    head -1 "$f" 2>/dev/null | grep -q "^version https://git-lfs" && echo "$f"
  fi
done | wc -l | tr -d ' ')

# Print update notice first (if any)
if [ -n "$UPDATE_MSG" ]; then
  echo "$UPDATE_MSG"
fi

cat <<EOF
# GiftHub Detected

$GFH_STATUS | Pointers: $POINTER_COUNT

## Commands
| Command | Purpose |
|---------|---------|
| \`gfh pull [files...]\` | Download LFS objects from Google Drive |
| \`gfh upload <files...>\` | Upload to Drive + create LFS pointers |
| \`gfh clone <url>\` | Clone repo + auto-configure + pull |
| \`gfh dehydrate\` | Replace local files with pointers |

## Note
- Files < 200 bytes starting with \`version https://git-lfs\` are **LFS pointers** — run \`gfh pull\` to restore
- \`git push\` is safe (pre-push hook skips LFS upload)
- Use \`--concurrency N\` for parallel transfers (default 4)
EOF
