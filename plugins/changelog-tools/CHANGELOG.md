# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2026-05-02

### Added
- `changelog-validate` skill — KAC 1.1.0 compliance check + 3-way sync drift detection between `CHANGELOG.md` latest entry, `plugin.json` description, and `marketplace.json` description. Exit codes 0/1/2/3/4 for CI.
- `changelog-init` skill — bootstrap `CHANGELOG.md` for one plugin from `plugin.json` description. Two modes: `init` (parse `vX.Y.Z` segments → KAC entries) and `normalize` (rewrite non-KAC headers like em-dash format to KAC strict).
- `changelog-migrate` skill — batch run `changelog-init` across an entire marketplace, producing a markdown migration report at `<marketplace>/.claude-plugin/migration-report-YYYY-MM-DD.md`.
- `scripts/validate-changelog.py` — KAC parser + 3-way sync checker (Python 3, no external deps).
- `scripts/init-changelog.py` — description segment parser with major-version filtering (excludes dep-version mid-text noise) and `git log -S` pickaxe date resolution.
- `scripts/migrate-marketplace.py` — batch orchestrator that calls `init-changelog.py` per plugin and aggregates results into a markdown report.
- KAC 1.1.0 spec enforcement: six allowed section types (Added / Changed / Deprecated / Removed / Fixed / Security); strict version header format `## [MAJOR.MINOR.PATCH] - YYYY-MM-DD`; preamble must reference Keep a Changelog.

### Changed
- PsychQuant marketplace migration: 33 plugins gained `CHANGELOG.md` files via `changelog-migrate` first run (only `issue-driven-dev` already had one). `che-word-mcp` extracted 15 historical version segments with all dates resolved via `git log` pickaxe; other plugins extracted 1 segment (current version) since their descriptions only describe the latest release.
