# changelog-tools

Changelog management toolkit for Claude Code plugin marketplaces.

## What is this?

A plugin that enforces [Keep a Changelog](https://keepachangelog.com) format and three-way synchronization between:

- `CHANGELOG.md` latest entry
- `plugin.json` `description` field
- `marketplace.json` plugin entry `description` field

## Why?

Auditing PsychQuant's marketplace surfaced a structural problem: **35 of 36 plugins had no `CHANGELOG.md`**. All release history lived in `plugin.json` `description` as a run-on string spanning 5+ versions, making history unreadable in the marketplace UI and silently no-op'ing `plugin-deploy`'s CHANGELOG-based README freshness check.

This plugin fixes that hole.

## Skills

| Skill | What it does |
|-------|-------------|
| `/changelog-tools:changelog-validate <plugin-path>` | Check KAC compliance + 3-way sync drift. Exit 0/1/2/3 for CI. |
| `/changelog-tools:changelog-init <plugin-path>` | Initialize `CHANGELOG.md` for one plugin (parses `plugin.json` description's `vX.Y.Z:` segments → KAC entries). Interactive. |
| `/changelog-tools:changelog-migrate <marketplace-path>` | Batch: run `changelog-init` across an entire marketplace. Migration report per plugin. |

## Coming in Phase 2

| Skill | What it will do |
|-------|----------------|
| `/changelog-tools:changelog-add <plugin-path>` | Add `[Unreleased]` entry. Calls Composio's `changelog-generator` for git-commit parsing. |
| `/changelog-tools:changelog-release <plugin-path>` | Promote `[Unreleased]` → `vX.Y.Z` + DATE. Auto-bump semver from sections. Sync 3 files. |

Plus hooks into `plugin-deploy` / `mcp-deploy` / `cli-deploy` so missing CHANGELOG.md becomes a deploy-time warning.

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
/changelog-tools:changelog-validate plugins/issue-driven-dev

# Initialize a CHANGELOG.md from existing plugin.json description
/changelog-tools:changelog-init plugins/che-word-mcp

# Batch migrate every plugin in the marketplace
/changelog-tools:changelog-migrate .
```

## License

MIT
