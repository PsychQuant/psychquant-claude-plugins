# changelog-tools — CLAUDE.md

## Purpose

Enforce [Keep a Changelog](https://keepachangelog.com) format across all plugins in a marketplace, plus three-way sync between `CHANGELOG.md` latest entry ↔ `plugin.json` description ↔ `marketplace.json` description.

Built because PsychQuant's marketplace had 35 of 36 plugins without `CHANGELOG.md` — all release history stuffed into `plugin.json` description as a run-on monster string, making history unreadable and breaking `plugin-deploy`'s CHANGELOG-based freshness check.

## Skills

| Skill | Purpose |
|-------|---------|
| `changelog-validate` | KAC compliance check + 3-way sync drift detection. Exit codes: 0 pass / 1 missing CHANGELOG / 2 KAC violation / 3 sync drift. CI-friendly. |
| `changelog-init` | Initialize `CHANGELOG.md` for one plugin by parsing `plugin.json` description's `vX.Y.Z:` segments → KAC entries. Interactive per-segment confirmation. |
| `changelog-migrate` | Batch mode: run `changelog-init` across an entire marketplace. Produces a migration report (per-plugin entries extracted, status, manual review needed). One-shot operation. |

Phase 2 (separate release) will add:

| Skill | Purpose |
|-------|---------|
| `changelog-add` | Interactive `[Unreleased]` entry creation. May call Composio `changelog-generator` for commit parsing. |
| `changelog-release` | Promote `[Unreleased]` → `vX.Y.Z` + DATE. Auto-bump semver from Added/Breaking/Fixed. Sync `plugin.json` + `marketplace.json` description. |

Plus hooks into `plugin-deploy` / `mcp-deploy` / `cli-deploy` freshness check pipeline.

## Format Spec

Strict Keep a Changelog 1.1.0:

```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- New feature description

## [1.2.0] - 2026-05-02

### Added
- Feature shipped in 1.2.0

### Changed
- Behavioral change

### Deprecated
- Marked for removal

### Removed
- Removed feature

### Fixed
- Bug fix

### Security
- Vulnerability patched
```

Six allowed section types: **Added / Changed / Deprecated / Removed / Fixed / Security**. Other section names trigger `changelog-validate` exit code 2.

Version format: `[MAJOR.MINOR.PATCH] - YYYY-MM-DD` with brackets and ISO date. Em-dash (`—`) format from PsychQuant's existing `issue-driven-dev` CHANGELOG is **non-conformant** and gets normalized by `changelog-init` / `changelog-migrate`.

## Three-Way Sync Rule

The latest released entry's content (excluding `[Unreleased]`) must match the **first 200 chars** (configurable) of:

- `plugin.json` `description`
- `marketplace.json` `plugins[name=$plugin].description`

Both descriptions should follow the pattern:

```
v<latest-version>: <one-line summary that matches CHANGELOG section heading or first ###>. <2-3 sentence elaboration>. <previous version recap optional>.
```

`changelog-validate` checks this and reports drift via exit code 3 + readable diff.

## Why a Plugin

Could be just a script — but as a plugin:

- Skills are discoverable via `/changelog-tools:*`
- `claude plugin marketplace update` distributes new validation rules
- Future hook integration into `plugin-deploy` / `mcp-deploy` / `cli-deploy` is one-line `Skill(skill="changelog-tools:changelog-validate", args="$PLUGIN")`
- Marketplace consumers benefit (not just PsychQuant)

## Related

- [Keep a Changelog spec](https://keepachangelog.com)
- [olivierlacan/keep-a-changelog](https://github.com/olivierlacan/keep-a-changelog)
- [Semantic Versioning](https://semver.org)
- [`ComposioHQ/awesome-claude-skills/changelog-generator`](https://github.com/ComposioHQ/awesome-claude-skills/tree/master/changelog-generator) — Phase 2 will integrate this for commit parsing
