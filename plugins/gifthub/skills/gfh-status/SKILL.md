---
name: gfh-status
description: Show GiftHub status — pointer file count, registry info, and Drive connection status. Use when user asks about GiftHub state in current repo.
allowed-tools:
  - Bash
  - Read
  - Grep
  - Glob
---

# /gfh-status — GiftHub Repo Status

Show the current state of GiftHub in this repo.

## Steps

1. Check `.gfh.json` exists — if not, report "Not a GiftHub repo"
2. Read `.gfh.json` to get Drive folder ID
3. Count total files tracked by git: `git ls-files | wc -l`
4. Count pointer files (< 200 bytes, starts with `version https://git-lfs`)
5. Count hydrated files (tracked by LFS but not pointers)
6. Check `~/bin/gfh` exists and get version
7. Check if pre-push hook is installed: `cat .git/hooks/pre-push`

## Output Format

```
## GiftHub Status

| Item | Value |
|------|-------|
| Drive folder | {id} |
| gfh version | {version} |
| Total tracked | {N} files |
| Pointers | {N} (need `gfh pull`) |
| Hydrated | {N} |
| Pre-push hook | installed / missing |
```
