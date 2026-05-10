# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

> ⚠ This file was bootstrapped by `changelog-tools:changelog-init` from the
> `plugin.json` description field. Section categorization is best-effort —
> review and refine `Added` / `Changed` / `Fixed` etc. as needed.

## [Unreleased]

## [2.18.0] - 2026-05-10

### Added
- **Staleness Detection (Refs PsychQuant/che-apple-mail-mcp#76)**:wrapper 在 `exec binary` 前 atomic-write `~/bin/.CheAppleMailMCP.runtime.json` 紀錄 `{pid, started_at, version_at_spawn}`;新增 `hooks/session-start.sh`,Claude Code session 啟動時偵測 runtime state 與 `plugin.json` 的 version drift。Drift + PID alive + `command` field 含 `CheAppleMailMCP` 三條件成立 → SIGTERM(+5s grace,SIGKILL fallback)stale PID,讓 host respawn 取新 binary。
- **`hooks/session-start.sh`**(NEW,~70 行 bash)— 全 graceful-skip:`jq` / `ps` 缺、runtime file 缺、plugin.json 缺、PID 已死、PID command field 不含 `CheAppleMailMCP`(防 PID-reuse 誤殺)→ 全部 silent exit 0,never block session start。
- **`tests/test-session-start-hook.sh`**(NEW)— 6 case integration test(無 runtime file / version match / version mismatch+alive / mismatch+dead / jq missing / plugin.json missing),全部用 `exec -a CheAppleMailMCP-mock sleep` 模擬 MCP process。16/16 PASS。

### Changed
- `bin/che-apple-mail-mcp-wrapper.sh`:`exec binary` 前多一段 atomic write runtime state file;失敗 silent skip(`|| true`),never block spawn。Wrapper 既有 sidecar version-check 邏輯**不動**(remains first line of defense for spawn-time download)。

### Notes
- Plugin minor bump 2.17.0 → 2.18.0(new feature surface,additive,backward compat)。Plan 走 IDD `/idd-plan` approval gate,EnterPlanMode 已 user-approved。
- 解決今日 #72 incident 的 deployment 端 root cause:即使 binary v2.7.1 已 release + plugin shell 已 bump,user 當下 session 的 in-memory MCP 仍跑舊 v2.7.0 binary 直到 manual `kill <pid>` + 重啟 Claude Code。新 hook 把這條 staleness window 自動關掉。
- Sister issue split:[`PsychQuant/psychquant-claude-plugins#58`](https://github.com/PsychQuant/psychquant-claude-plugins/issues/58)— `plugin-tools:plugin-update` 結尾應主動警告 user(sender-side 補強),獨立 PR。
- Out-of-scope:**#77**(sidecar tracks shell version not binary version)、**#78**(server-side markdown export API)獨立評估。

## [2.17.0] - 2026-05-09

### Added
- **Workspace Layout Detection (#49)**:當 `output_dir` 既無 `$ARGUMENTS[1]` 也無 `${CONFIG_FILE}` 的 `output_dir:` 欄位給定時,probe 工作目錄按 `communications/email/` → `correspondence/emails/` → baseline default `communication/emails` 順序解析。Detection-first not prescriptive — adapt 到 user 既有 layout,不 push canonical convention。Existing user 有 explicit config 的 100% backward-compat(detection 不 fire)。
- **Sibling-archive dedup extension (#49)**:`${output_dir}` 下若有 symlinked subdirectory(transitioned-project pattern,e.g. `communications/email/application/` → `applications/completed/.../emails/`),自動讀其下 markdown 的 `message_id:` YAML frontmatter 併入 in-memory dedup set。`find -P -maxdepth 2`,read-only,never writes to symlink target。Composes with `dedup_strategy = index | both`(skip on `last_archived`)。
- **Ambiguity guard**:當 `communications/email/` 與 `correspondence/emails/` **同時存在且都有 `*.md`** 時,refuse to guess,abort with explicit pin recommendation(指 user 寫 `output_dir:` in config)。Mid-migration workspace 必須 explicit 指定避免 dedup-index split-brain。
- **Detection 透明度**:啟動時 `🔍 Detected output_dir: <path> (from layout probe)` log,以及 dedup extension 觸發時 `🔗 Extended dedup with N entries from sibling archives:` log,讓 verify / diagnose 能看到 path resolution 結果。
- **README Workspace Patterns section**(v2.17.0+):文件三種 layout、precedence(高→低:`$ARGUMENTS[1]` → config `output_dir:` → detection → default)、symlink coexistence pattern、ambiguity guard。

### Notes
- Plugin minor bump 2.16.1 → 2.17.0(new feature surface,additive,backward compat)。Plan 走 IDD `/idd-plan` approval gate,EnterPlanMode 已 user-approved 後才 chain 到 implement。
- Out-of-scope follow-ups filed:**#50** parallel `documents_dir` detection,**#51** companion-commands(`archive-mail-view` / `archive-mail-rebuild-threads` / `archive-mail-migrate`)detection consistency,Tier C' per-contact mode(deferred until N≥3 evidence)。
- Sister-bug observation during scout:v2.16.1 release(2026-05-09 commit `8089765`)沒寫 CHANGELOG entry — 屬 KAC sync drift,**留給 follow-up issue 補 backfill**(本 PR 不混進)。

## [2.16.0] - 2026-05-07

### Changed
- **Config schema rename `.md` → `.yaml` (#47)**:`.claude/.mail/config.md` (v2.8.0–v2.15.0) 改名 `.claude/.mail/config.yaml`。原因:副檔名語意 ↔ 實際內容(YAML)一致;IDE 接 yaml-lsp;新 user 不被 `.md` 暗示「要寫 markdown body」誤導。
- 三處 mental model(spec / README / awk parser)統一稱「YAML config」,排除 「frontmatter」說法(parser 對 `---` boundary 自然 tolerant,因 `^---$` 不 match `^[a-z_]+:`)。

### Added
- **Auto-migrate `.md` → `.yaml`** in `archive-mail.md` Step 1.6 + `archive-mail-migrate` command。Silent rename,user 不需動手。順序:legacy `.claude/emails.md` (v2.7.0 ↓) → `.yaml`;then `.claude/.mail/config.md` (v2.8.0–v2.15.0) → `.yaml`。
- archive-mail.md `argument-hint` frontmatter + 使用方式 section 更新 path 引用。
- CLAUDE.md schema 段標題 `.claude/.mail/config.yaml Schema (v2.16.0+ #47)` + 路徑遷移說明。
- README archive-mail 段加 v2.16.0 highlight + File Layout `.yaml` 標示。

### Deprecated
- `.claude/.mail/config.md`:仍 work 為 fallback(parser 對舊檔自動相容),**v3.0 移除**。期間文件示範一律用 `.yaml`。

### Notes
- Plugin minor bump 2.15.0 → 2.16.0(new feature surface,backward compat;default behavior 對既有 `.md` user 透過 silent migration 不 break)。
- User decision (#issuecomment-4395581948):走 YAML 路線;選 Option C 漸進過渡(雙支援期 + v3.0 強制 `.yaml`)而非 Option A 立即 break。

## [2.15.0] - 2026-05-07

### Added
- **Inline `cid:` image preservation in `/archive-mail` (#45)**:resolves dogfood gap where 「Solution? (affine repre + Iverson's law of similarity)」 thread 11 封信中 1 張 CleanShot screenshot inline-embedded via `cid:` 完全 miss(因 `list_attachments` 不回 `Content-Disposition: inline` images)。
- **Step 5.5.0** (new) parses HTML body via regex `<img\s+...src="cid:..."...alt="...">` → extracts `(cid, alt_filename)` pairs → tries `save_attachment(attachment_name=alt, save_path=<stem>/inline/<alt>)`
- **Step 5.5.5** (new) fallback: if `save_attachment` doesn't recognize inline filename (binary-side limitation), writes cross-reference note `Inline images: - (cid:XXX — filename — binary unsupported; see Mail.app)` instead of silent skip
- **`Inline images:` section** in archive markdown (separate from `Attachments:`); image syntax `![alt](path)` for direct render in markdown viewers (vs link syntax for explicit attachments)
- **Folder layout**: `correspondence/attachments/<email_stem>/inline/<filename>` — sub-folder under existing stem dir; preserves semantic distinction between user-attached files vs inline illustrations
- **Step 8a Coverage Audit** updated: split into 8a.1 explicit + 8a.2 inline; report shows `explicit N/M + inline P/Q` format
- **Step 7 report** adds inline count line (only if any inline images present)

### Notes
- Skill-side workaround only;binary `save_attachment` 是否認得 inline filename **尚未驗證**(待實測,可能需要 follow-up upstream issue)
- 既有 archives 不會 retroactive process — inline 圖片仍是占位文字,user 手動補
- Plugin minor bump 2.14.0 → 2.15.0 (new feature surface,backward compat 預設行為不變)

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
