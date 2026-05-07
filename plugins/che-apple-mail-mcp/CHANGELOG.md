# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

> ⚠ This file was bootstrapped by `changelog-tools:changelog-init` from the
> `plugin.json` description field. Section categorization is best-effort —
> review and refine `Added` / `Changed` / `Fixed` etc. as needed.

## [Unreleased]

## [2.14.0] - 2026-05-07

### Added
- **Opt-in `dedup_strategy` for `/archive-mail` (#18)**:resolves real-world observation that `.email_index.json` is rarely built / used — tatsuma project ran archive-mail for 3 years without producing one. New `.claude/.mail/config.md` field `dedup_strategy` with three values:
  - `index` (default,backward compat) — load + write `email_index.json` as before
  - `last_archived` — skip index entirely;use `last_archived` ISO-date as `date_from` for Step 3 search;requires `last_archived` field set in config (fail-fast if missing,prevents silent full-inbox scan)
  - `both` — load index AND apply date filter (Message-ID set ∪ date filter)
- Step 1.6 of archive-mail.md gains a strategy-resolve block;Step 2 conditionally skips index load;Step 4 dedup logic branches per strategy;Step 5/6 conditionally skip index write.
- CLAUDE.md schema docs updated with `dedup_strategy` + `last_archived` fields.

### Notes
- Default behavior unchanged from v2.13.0;existing archives continue with index-based dedup until user explicitly opts into `last_archived` or `both`.

## [2.13.0] - 2026-05-07

### Changed
- **BEHAVIOR CHANGE — `/archive-mail` Step 5 markdown template default simplified (#17)**: previously every archived email got a 4-section template (元數據表 + 信件內容 + 重點摘要 + 待辦事項). Real-world usage (tatsuma project, 50 historical archives) showed the elaborate sections are unused noise — AI summaries are unreliable and require manual review, breaking batch processing consistency. Default is now a simple template (frontmatter + 4-line `Subject/From/To/Date` header + body), matching the historical convention. Existing archives are NOT reprocessed (Message-ID dedup prevents). Users wanting the old elaborate template can opt in via `.claude/.mail/config.md` frontmatter `enrichment: summary+todos`.
- Plugin version bumped 2.12.0 → 2.13.0 (after #13 PR #39 landed at 2.12.0). Frontmatter still includes all 6 fields (`message_id` / `thread_key` / `in_reply_to` / `date` / `sender` / `direction`) — thread index reconstruction depends on these.

### Added
- `enrichment` field to `.claude/.mail/config.md` schema. Values: `none` (default, simple template) | `summary+todos` (4-section enriched template). Documented in plugin CLAUDE.md.

## [2.12.0] - 2026-05-07

### Added
- `/archive-mail` 零參數模式 (#13):當 `$ARGUMENTS` 為空時,從 `.claude/.mail/config.md` frontmatter 讀 `filters` / `output_dir` / `last_archived` / `exclude_mailboxes` 自動執行。命令列參數覆寫 config 維持 backward compat。空 config + 零參數會 fail-fast 提示而非靜默 archive 全 inbox(危險預防)。
- `argument-hint` frontmatter 改 `[email-filter] [output-dir]`,UI 正確標示 v2.12.0+ filter 為可選 (#21)。

## [2.10.3] - 2026-05-03

### Changed
- **Plugin shell bumped to notify binary v2.6.0** ([release notes](https://github.com/PsychQuant/che-apple-mail-mcp/releases/tag/v2.6.0)). Marathon release: 16 issues across 8 PRs landed in binary repo. Plugin shell version-aware wrapper auto-downloads new binary on next session start.

### Security
- Binary v2.6.0 ships: id injection guard ([#50](https://github.com/PsychQuant/che-apple-mail-mcp/issues/50)), attachment path deny-list + `MAIL_MCP_ATTACHMENT_ROOTS` allow-list ([#38](https://github.com/PsychQuant/che-apple-mail-mcp/issues/38)), email address validation ([#41](https://github.com/PsychQuant/che-apple-mail-mcp/issues/41)), type-strict handler params ([#35](https://github.com/PsychQuant/che-apple-mail-mcp/issues/35)), new `SECURITY.md` ([#48](https://github.com/PsychQuant/che-apple-mail-mcp/issues/48)).

### Fixed
- Binary v2.6.0 ships: `forward_email` plain mode embeds quoted original ([#44](https://github.com/PsychQuant/che-apple-mail-mcp/issues/44)) — mirrors v2.5.0 `reply_email` fix.

## [2.10.2] - 2026-05-03

### Changed
- **Plugin shell bumped to notify binary v2.5.0** ([release notes](https://github.com/PsychQuant/che-apple-mail-mcp/releases/tag/v2.5.0)).

### Fixed
- Binary v2.5.0 ships: `reply_email` plain mode embeds quoted original ([#43](https://github.com/PsychQuant/che-apple-mail-mcp/issues/43)) via Swift-side `composeReplyPlainText` helper. RFC 3676 `> ` prefix + CRLF normalization + empty-line `>` stuffing + pre-fetch graceful degrade. Pre-fix every plain-format `reply_email` call since `b8a4a89` (initial release) silently dropped the quoted original.

## [2.10.1] - 2026-05-02

### Changed
- **Plugin shell bumped to notify binary v2.4.1** ([release notes](https://github.com/PsychQuant/che-apple-mail-mcp/releases/tag/v2.4.1)).

### Fixed
- Binary v2.4.1 ships ([#33 verify findings A+B](https://github.com/PsychQuant/che-apple-mail-mcp/issues/33)): `reply_email` `save_as_draft=true` no longer pops Mail.app reply window; `replyEmail` validates attachment paths up-front mirroring `composeEmail` / `createDraft`.

## [2.10.0] - 2026-05-02

### Added
- **Plugin shell bumped to notify binary v2.4.0 reply-as-draft mode** ([issue #33](https://github.com/PsychQuant/che-apple-mail-mcp/issues/33)). `reply_email` gains 3 optional params: `cc_additional`, `attachments`, `save_as_draft`. Unblocks workflow: reply to existing thread + add CC + attach files + save as draft for human review before sending.

## [2.9.0] - 2026-05-01

### Changed
- Apple Mail MCP server — 44+ tools, IDD-style task enforcement + NSQL confirmation + .claude/.mail/ namespace (v2.9.0)。v2.9.0: archive-mail 與 confirmation-protocol skill Step 0 強制 TaskCreate bootstrap,靜默 skip = 違規。疊加 v2.8.0 namespace、v2.7.0 NSQL confirmation、v2.6.0 thread index、v2.5.0 composing format、v2.4.0 搜尋擴展。
