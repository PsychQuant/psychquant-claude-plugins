# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

> ⚠ This file was bootstrapped by `changelog-tools:changelog-init` from the
> `plugin.json` description field. Section categorization is best-effort —
> review and refine `Added` / `Changed` / `Fixed` etc. as needed.

## [Unreleased]

## [2.2.0] - 2026-05-11

### Changed
- PreToolUse hooks now protect both `archive/` and `archived/` directory conventions. Previous releases only matched `archived/`, leaving `archive/` directories (used by `git archive`, openspec patterns, and many engineering repos in the same workstation) unprotected even though they serve the same purpose. Regex updated from `archived` to `archived?/` on the Bash hook, and from `/archived/` to `/archived?/` on Write and Edit hooks.
- Regex now anchored on trailing slash. The earlier choice of `archived/` (over `archive/`) was motivated by false-positive concerns — `archive` as a bare word appears in `git archive HEAD`, `tar archive.tar`, etc. Requiring the trailing slash resolves the false-positive risk while accepting both naming conventions. Verified: `git archive HEAD > a.tar && rm tmp.txt` no longer triggers; `rm -rf /tmp/archive/old` and `rm -rf /tmp/archived/old` both blocked.
- Error messages updated to read "archive/ or archived/ directory" instead of "archived/ directory".
- Plugin description updated to reflect dual protection.

### Documentation
- See accompanying revision to the [Archive-First Defense post](https://che-cheng.vercel.app/blog/vibe-coding-data-loss) (Naming Note section) for the design history and trade-off discussion.

## [2.1.1] - 2026-05-07

### Fixed
- PreToolUse Bash hook regex narrowed to word boundaries (`grep -wE`) for both `(rm|rmdir|unlink)` and `archived` matches. Previously over-broad substring grep fired false-positives on commands containing `platform` / `format` / `perform` / `transform` / `inform` / `harm` (any English word with `rm` substring) when the same command also mentioned `archived` anywhere — common in `gh issue comment` heredoc bodies discussing archive governance. Resolves #32.

## [2.1.0] - (date unknown — please fill in)

### Changed
- Protect files from AI-assisted deletion with the Archive-First strategy.
- PreToolUse hooks block destructive commands on archived/ paths.
- Toggle protection with archived-lock/archived-unlock
