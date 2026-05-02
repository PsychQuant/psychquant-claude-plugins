# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.0] - 2026-05-02

### Changed
- **Renamed plugin from `changelog-tools` to `doc-tools`** — scope expanded from CHANGELOG-only to general documentation lifecycle. Skill names keep `changelog-` prefix (no need to retrain muscle memory) but plugin invocation changes from `/changelog-tools:*` to `/doc-tools:*`. Migration: `claude plugin uninstall changelog-tools && claude plugin install doc-tools@psychquant-claude-plugins`.
- Plugin description rewritten to reflect the three concerns (CHANGELOG hygiene + doc-update guardrail + bootstrap migration) instead of CHANGELOG-only positioning.

### Added
- **NEW Stop hook**: `hooks/doc-update-guard.sh` — absorbs the user-level `~/.claude/hooks/changelog-update.sh` from `che-claude-config`. Blocks turn-end when HEAD commit changed ≥3 code files but updated none of `CHANGELOG.md` / `README.md` / `CLAUDE.md` / `changelog/`. Auto-registered via `hooks/hooks.json` (no manual `~/.claude/settings.json` edit needed). Original design rationale preserved: per-commit (compact-aware), Stop+block (intentional because doc updates are clearly actionable), 3-file threshold (heuristic for significant change), code-extension allowlist (R/sh/sql/py/ts/swift/go/rs/etc — user's primary languages), `stop_hook_active=true` bypass (infinite-loop protection).
- **NEW three-tier config injection** for the hook (precedence high → low):
  1. `<repo>/.claude/doc-tools.json` — per-project override
  2. `~/.cache/doc-tools/config.json` — per-machine override
  3. Built-in defaults in `scripts/doc-update-config.sh`
- **NEW kill-switch**: `~/.cache/doc-tools/disabled` flag file — touch to silence the hook entirely (mirrors `archive-first` plugin pattern).
- **Config schema**: `{enabled, min_changed_files, code_extensions[], doc_files[], skip_paths[]}` — all fields optional, missing keys fall through to defaults. `code_extensions` and `doc_files` use full replace; `skip_paths` appends across layers.
- **NEW `references/doc-update-design.md`** — full hook design rationale captured for the first time. Covers both originally-documented decisions (per-commit not per-day, Stop+block intentional) AND previously-implicit ones (3-file threshold reasoning, code-extension list source, 4-doc-files acceptance set, lenient pass criterion). Also includes a "Rejected alternatives" table mirroring the `pending-tasks-nudge.py` README convention.
- `scripts/doc-update-config.sh` — shared config loader sourced by the hook. Uses `jq has()` (not `// empty` which silently swallows the literal `false` value).

### Fixed
- `_merge_config` JSON loading: switched from `jq -r '.field // empty'` to `jq -r 'if has("field") then .field else empty end'` — the `//` operator falls through on falsy values (`false`, `null`, `0`, `""`), making `{"enabled": false}` config get silently ignored. The `has()` form correctly distinguishes "field absent" from "field is false".
- Hook BLOCK output: built reason string entirely inside `jq` filter using `\n` escapes instead of passing multi-line shell variable via `--arg`. Resulting JSON now has properly-escaped `\n` (RFC 8259 compliant) instead of literal control characters.
- Hook git diff: added `--root` flag to `git diff-tree --no-commit-id --name-only -r HEAD` — without it, root commits (no parent) return empty file list, silently passing all checks even when files were committed.

## [0.1.1] - 2026-05-02

### Changed
- `changelog-validate`: Relaxed the "description must start with `vX.Y.Z:`" check to "description must mention `vX.Y.Z` somewhere in first 400 chars" — PsychQuant convention leads descriptions with product tagline, not version prefix. Drift count drops from ~30 plugins to 0 with this change.
- `changelog-validate`: Version header parser now accepts placeholder dates like `(date unknown — please fill in)` so init-output entries are still parsed; ISO-format check happens separately and reports placeholder as a violation user can fix later.
- `changelog-init normalize`: Now also remaps common non-KAC section names (`### Changes` → `### Changed`, `### Migration` → `### Changed`, `### Bug Fixes` → `### Fixed`, etc.) and injects KAC preamble if missing. Three idempotent transforms in one pass: bracket headers + section remap + preamble.

### Fixed
- `issue-driven-dev` CHANGELOG.md hand-fixed two custom subsection names that don't auto-remap (`### 上下游責任分工` and `### Thesis` → `### Changed` with `<!-- (formerly: ...) -->` comment markers preserving original intent).

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
