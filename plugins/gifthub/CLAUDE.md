# gifthub Plugin

GiftHub CLI integration for Claude Code.

## What It Does

1. **SessionStart hook**: Detects GiftHub config（v2 `.claude/.gfs/config.json` 優先 / v1 `.gfh.json` fallback）and injects GiftHub usage context (commands, pointer file count, layout 標示)
2. **Auto-install hook**: After `swift build` succeeds in the GiftHub dev repo, automatically does release build + copies `gfh` to `~/bin/`
3. **Skills**: `/gifthub:gfh-status` shows repo GiftHub status, `/gifthub:gfh-import` imports Drive files into repo

## Config layout

| Layout | Default since | 路徑 |
|--------|--------------|-----|
| **v2** | gfh CLI v0.4.0 + plugin v1.2 | `.claude/.gfs/config.json` + `.claude/.gfs/aliases.json` + `.claude/.gfs/registry.json` |
| **v1** | gfh CLI ≤ v0.3.x | `.gfh.json` + `lfs-registry-aliases.json` + `lfs-registry.json`（root） |

新 `gfh init` 寫 v2；既有 v1 repo 仍 work（plugin hook + gfh CLI 都偵測 fallback）。

## Skills

| Skill | Purpose |
|-------|---------|
| `/gifthub:gfh-status` | Show pointer count, Drive config, hook status |
| `/gifthub:gfh-import` | Import a Drive file: `gws move` → `gfh link` → `gfh pull` |

## Key Workflow: `gfh link` → `gfh pull`

When a file already exists on Google Drive (e.g., Meet recordings), the optimal import flow is:

1. **`gws drive files update`** — move + rename to GiftHub-LFS folder on Drive
2. **`gfh link <drive-id> <local-path>`** — compute SHA-256 via streaming, create pointer + alias (no download needed)
3. **`gfh pull <path>`** — download the actual file from Drive

This avoids the download → upload round-trip of the traditional `git add` → `gfh push` workflow.

## Hooks

| Hook | Trigger | Action |
|------|---------|--------|
| `session-start.sh` | SessionStart | Detect v2 (`.claude/.gfs/config.json`) or v1 (`.gfh.json`), inject context with layout label |
| `auto-install.sh` | PostToolUse (Bash) | After `swift build` in GiftHub repo → release build + install to `~/bin/` |
