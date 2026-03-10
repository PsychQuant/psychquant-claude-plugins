# archive-first

Protect your files from AI-assisted deletion with the Archive-First strategy.

## What it does

This plugin adds three layers of protection for files in `archived/` directories:

| Layer | Mechanism | How |
|-------|-----------|-----|
| **PreToolUse hook** | Blocks destructive commands | Denies any `rm`, `rmdir`, or `unlink` targeting paths containing `archived` |
| **PostToolUse hook** | Auto-locks archived files | Applies macOS `chflags uchg` (immutable flag) after every Bash command |
| **Slash commands** | Manual archive/unlock | `/archive-first:archive` and `/archive-first:unlock` |

## Commands

### `/archive-first:archive [path]`

Copy a directory to `archived/` with a timestamp and lock it with the immutable flag.

```
/archive-first:archive ./src
# Creates: ./archived/src-20260310-143022 (locked)
```

### `/archive-first:unlock [path]`

Remove the immutable flag from archived files for cleanup.

```
/archive-first:unlock ./archived/src-20260310-143022
```

## How it works

**Before AI restructures your files:**
```bash
/archive-first:archive ./my-project
```

**During AI work:** The hooks automatically:
1. Block any `rm`/`rmdir` command targeting `archived/` paths (PreToolUse)
2. Lock any new files added to `archived/` directories (PostToolUse)

**If something goes wrong:**
```bash
/archive-first:unlock ./archived/my-project-20260310-143022
cp -r ./archived/my-project-20260310-143022 ./my-project
```

## Requirements

- **macOS only** — uses `chflags uchg` (user immutable flag)
- Linux alternative: replace `chflags -R uchg` with `chattr -R +i` (requires root)

## Background

Read the full rationale: [Your AI Coding Agent Will Delete Your Files: The Archive-First Defense](https://che-cheng.vercel.app/blog/vibe-coding-data-loss)
