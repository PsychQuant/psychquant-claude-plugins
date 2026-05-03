# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

> ⚠ This file was bootstrapped by `changelog-tools:changelog-init` from the
> `plugin.json` description field. Section categorization is best-effort —
> review and refine `Added` / `Changed` / `Fixed` etc. as needed.

## [Unreleased]

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
