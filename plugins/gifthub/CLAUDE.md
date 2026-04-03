# gifthub Plugin

GiftHub CLI integration for Claude Code.

## What It Does

1. **SessionStart hook**: Detects `.gfh.json` in any repo and injects GiftHub usage context (commands, pointer file count, status)
2. **Auto-install hook**: After `swift build` succeeds in the GiftHub dev repo, automatically does release build + copies `gfh` to `~/bin/`
3. **Skills**: `/gifthub:gfh-status` shows repo GiftHub status

## Skills

| Skill | Purpose |
|-------|---------|
| `/gifthub:gfh-status` | Show pointer count, Drive config, hook status |

## Hooks

| Hook | Trigger | Action |
|------|---------|--------|
| `session-start.sh` | SessionStart | Detect `.gfh.json`, inject context |
| `auto-install.sh` | PostToolUse (Bash) | After `swift build` in GiftHub repo → release build + install to `~/bin/` |
