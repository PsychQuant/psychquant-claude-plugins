# doc-tools

Documentation lifecycle toolkit for Claude Code plugin marketplaces.

## What is this?

Three concerns under one roof:

1. **CHANGELOG hygiene** — enforce [Keep a Changelog](https://keepachangelog.com) 1.1.0 format + three-way sync (`CHANGELOG.md` ↔ `plugin.json` description ↔ `marketplace.json` description)
2. **Doc-update guardrail** — Stop hook that blocks turn-end when a commit changes ≥3 code files but updates none of `CHANGELOG.md` / `README.md` / `CLAUDE.md` / `changelog/`
3. **Bootstrap migration** — for marketplaces with many legacy plugins lacking `CHANGELOG.md`, batch-init from existing `plugin.json` description prose

## Why?

Audit of PsychQuant's marketplace surfaced a structural problem: **35 of 36 plugins had no `CHANGELOG.md`**. All release history lived in `plugin.json` `description` as a run-on string spanning 5+ versions, making history unreadable in the marketplace UI. Separately, a user-level Stop hook (`~/.claude/hooks/changelog-update.sh`) enforced "update doc when committing big changes" but only registered globally — every other plugin user had to recreate it.

`doc-tools` consolidates both concerns: skills for CHANGELOG, hook for doc-update enforcement, three-tier config injection so behavior is tunable per-machine and per-project.

## Skills

| Skill | What it does |
|-------|-------------|
| `/doc-tools:changelog-validate <plugin-path>` | Check KAC compliance + 3-way sync drift. Exit 0/1/2/3/4 for CI. |
| `/doc-tools:changelog-init <plugin-path>` | Initialize `CHANGELOG.md` from `plugin.json` description (`init` mode) OR rewrite non-KAC headers to KAC strict (`normalize` mode). |
| `/doc-tools:changelog-migrate <marketplace-path>` | Batch: run `changelog-init` across an entire marketplace. Migration report per plugin. |

## Hook

| File | Event | Behavior |
|------|-------|----------|
| `hooks/doc-update-guard.sh` | `Stop` | Block turn-end when HEAD commit changed ≥3 code files but no doc was updated |

Auto-registered via `hooks/hooks.json` on plugin install — no manual `~/.claude/settings.json` edit needed.

### Three-tier config injection

```
1. <repo>/.claude/doc-tools.json    ← per-project (highest priority)
2. ~/.cache/doc-tools/config.json   ← per-machine
3. built-in defaults                ← ships with the plugin
```

Plus kill-switch:

```bash
touch ~/.cache/doc-tools/disabled    # one-touch silence
```

Schema (all fields optional):

```json
{
  "enabled": true,
  "min_changed_files": 3,
  "code_extensions": ["py", "ts", "swift"],
  "doc_files": ["CHANGELOG.md", "README.md"],
  "skip_paths": ["~/Developer/scratch/**", "/tmp/**"]
}
```

Full design rationale: [`references/doc-update-design.md`](references/doc-update-design.md).

## Format spec (strict KAC 1.1.0)

```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.2.0] - 2026-05-02

### Added
- New thing

### Fixed
- Old bug
```

**Six allowed section types**: Added / Changed / Deprecated / Removed / Fixed / Security. Anything else fails `changelog-validate` with exit code 2.

## Quick start

```bash
# Validate one plugin
/doc-tools:changelog-validate plugins/issue-driven-dev

# Initialize a CHANGELOG.md from existing plugin.json description
/doc-tools:changelog-init init plugins/che-word-mcp

# Normalize an existing non-KAC CHANGELOG.md (em-dash format → KAC bracket)
/doc-tools:changelog-init normalize plugins/issue-driven-dev

# Batch migrate every plugin in a marketplace
/doc-tools:changelog-migrate /path/to/marketplace-repo

# Disable the hook for this machine
touch ~/.cache/doc-tools/disabled

# Disable the hook for one repo only
echo '{"enabled": false}' > .claude/doc-tools.json
```

## Coming in Phase 2

| Skill / Integration | Purpose |
|---------------------|---------|
| `/doc-tools:changelog-add <plugin-path>` | Interactive `[Unreleased]` entry creation. Calls Composio's `changelog-generator` for git-commit parsing. |
| `/doc-tools:changelog-release <plugin-path>` | Promote `[Unreleased]` → `vX.Y.Z` + DATE. Auto-bump semver from sections. Sync 3 files. |
| Hooks into `plugin-deploy` / `mcp-deploy` / `cli-deploy` | Deploy-time CHANGELOG freshness check |
| Absorb `~/.claude/hooks/claude-md-reminder.sh` | Same family as doc-update-guard; consolidate under doc-tools |

## License

MIT
