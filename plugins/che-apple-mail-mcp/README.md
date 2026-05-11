# che-apple-mail-mcp

macOS Apple Mail MCP server with native AppleScript integration.

## Features

- List accounts, mailboxes, and emails
- Search emails with UTF-8 support (Swift-layer filtering)
- Read, reply, forward emails
- Manage drafts, attachments, rules
- Flag, move, delete operations
- VIP senders and signatures

## Commands

### `/archive-mail` — 歸檔郵件到 Markdown

把指定聯絡人的 Apple Mail 郵件批次歸檔為 Markdown 檔案，自動去重。v2.7.0+ 預設套用 4-phase NSQL confirmation protocol（filter 模糊先 disambiguate、bulk 結果先 preview + flag false positives、destructive op 必 confirm），v2.9.0+ 強制 `TaskCreate` 10 個 stage tasks 確保每 phase 不被靜默 skip。

```bash
# Zero-arg mode (v2.12.0+, v2.16.0+ reads .yaml) — reads .claude/.mail/config.yaml
/archive-mail

# Explicit filter mode (always available)
/archive-mail some@example.com
/archive-mail some@example.com communications
```

**v2.12.0–v2.17.0 highlights**:

- **v2.17.0** (#49) — Workspace Layout Detection + sibling-archive dedup:當 `output_dir` 既無命令列也無 config 給定時,probe `communications/email/` → `correspondence/emails/` → default,detect 到既有 layout 自動 adapt(detection-first,not prescriptive)。`${output_dir}` 下 symlink 到歷史 archive(transitioned-project pattern,e.g. chchen_lab `email/application/`)時,讀其下 markdown 的 `message_id:` frontmatter 併入 dedup,避免被 forward 回的舊 thread re-archive。Read-only,讀既有 explicit `output_dir:` config 的 workspace 行為 100% 不變。詳見下方 [Workspace Patterns](#workspace-patterns-v2170)。
- **v2.15.0** (#45) — Inline `cid:` 圖片保留路徑:從 HTML body 解析 `<img src="cid:..." alt="...">` → save 到 `attachments/<stem>/inline/<filename>`,Markdown 加獨立 `Inline images:` section(`![]()` syntax 直接 render),Step 8a Coverage Audit 拆 explicit + inline 兩部分。修掉 dogfood gap:archive 「Solution? (affine repre + Iverson)」 thread CleanShot screenshot 全 miss
- **v2.14.0** (#18) — Opt-in `dedup_strategy` config:`index`(預設) | `last_archived`(輕量,以 ISO date 作 date_from) | `both`(雙 dedup);零 breaking,既有 archive 走 default
- **v2.13.0** (#17) — Markdown template default 簡化:預設 `Subject/From/To/Date` 多行 header + body,對應 tatsuma 50 個歷史檔。User 想要原 4-section 模板:`enrichment: summary+todos`
- **v2.16.0** (#47) — Config schema rename:`.claude/.mail/config.md` → `.claude/.mail/config.yaml`(副檔名 ↔ 內容語意一致;legacy `.md` 仍 fallback,v3.0 移除)。auto-migrate 在 archive-mail / archive-mail-migrate 觸發,user 不需動手
- **v2.12.0** (#13/#21) — Zero-arg mode:`/archive-mail` 不帶參數從 `.claude/.mail/config.yaml`(legacy `.md` fallback)讀 `filters` / `output_dir` / `last_archived` / `exclude_mailboxes`;`argument-hint` 改 `[email-filter]` 反映可選性

#### Workspace Patterns (v2.17.0+)

archive-mail 不假設一個 canonical layout——adapt 到 user 的既有 folder 配置。三種主要 pattern:

| Pattern | Folder shape | When detection picks it |
|---------|--------------|--------------------------|
| **Nested channel layout** | `<workspace>/communications/email/` | `communications/email/` 存在;為「multi-channel comms」(email + future chat / letters / etc.) 預留結構。Forward direction(per kiki830621/chchen-lab 2026-05-08+) |
| **Legacy correspondence layout** | `<workspace>/correspondence/emails/` | 上面不存在但 `correspondence/emails/` 存在。pre-v2.17 既有 user convention,detection 認得不需要 migrate |
| **Baseline default** | `<workspace>/communication/emails/` | 兩者皆無;archive-mail 自己建這個 dir 並使用 |

**Precedence**(高 → 低):

1. 命令列 `$ARGUMENTS[1]` (`/archive-mail <filter> <output_dir>`)
2. `${CONFIG_FILE}` (`.claude/.mail/config.yaml`) 的 `output_dir:` 欄位
3. **Workspace Layout Detection**(本節 v2.17.0+ 新增)
4. Baseline default `communication/emails`

**Pin convention via explicit config**:若想 lock 一個 layout(例如 `psychophysic_representations` 走 `correspondence/emails`),在 config 寫:

```yaml
# .claude/.mail/config.yaml
output_dir: correspondence/emails
filters:
  - someone@example.com
```

已 explicit-pin 的 workspace 行為不變;zero-config 且 `communications/email/` 與 `correspondence/emails/` 同時存在含 `*.md` 的 mid-migration workspace 會被 ambiguity guard flag,要求 explicit pin(避免半實作狀態的 dedup-index split-brain)。

**Symlink coexistence**(transitioned-project pattern):

```
chchen_lab/
└── communications/email/
    ├── 2026-05-09_subject.md       ← live archive (archive-mail 寫入)
    ├── 2026-05-08_subject.md       ← live archive
    └── application/                ← SYMLINK → ../../applications/completed/.../emails/
        ├── 2026-04-29_old.md       ← 19 historical md files (read-only,never written)
        └── ...
```

archive-mail v2.17.0+ 會:

1. **掃 symlink subdirectories**:`find -P "${output_dir}" -maxdepth 1 -type l`
2. **讀其下 markdown 的 `message_id:` YAML frontmatter**:`find -P "$symlink_dir/" -maxdepth 2 -name "*.md"` → `head -30` → `awk` extract
3. **併入 in-memory dedup set**:Step 4 dedup logic 排除既有 + extended 的 Message-ID 集合
4. **絕不寫入 symlink target**:read-only by contract

**Ambiguity guard**:當 `communications/email/` 與 `correspondence/emails/` **同時存在且都有 `*.md` 檔**(mid-migration 異常情境),archive-mail abort with explicit error,要求 pin `output_dir:` in config。Empty-dir-as-marker 不算 ambiguity(常見於剛建好新 layout、還沒第一次 archive 的 workspace)。

**Diagnose 與 verify 哪個 path 在用**:archive-mail 啟動會印 detection 結果:

- `🔍 Detected output_dir: communications/email (from layout probe)` ← Probe 1 hit
- `🔍 Detected output_dir: correspondence/emails (legacy layout probe)` ← Probe 2 hit
- `🔗 Extended dedup with N entries from sibling archives:` ← Step 2.1 dedup extension fired
- (silent) ← detection didn't fire because explicit config / `$ARGUMENTS[1]` won

詳細 detection algorithm + edge cases 見 [`commands/archive-mail.md`](commands/archive-mail.md) §Step 1 Workspace Layout Detection 與 §Step 2.1 Sibling-archive dedup extension。

每封 md 帶 YAML frontmatter（`message_id` / `thread_key` / `in_reply_to` / `date` / `sender` / `direction`），並同步維護 `email_index.json`（Message-ID 去重）與 `threads.json`（thread 關係索引），v2.8.0+ 收斂到 `.claude/.mail/state/archives/{slug}/`。

詳細 spec 見 [`commands/archive-mail.md`](commands/archive-mail.md)。完整 changelog 見 [`CHANGELOG.md`](CHANGELOG.md)。

### `/archive-mail-view` — 生成 thread 聚合視圖（v2.6.0+）

```bash
/archive-mail-view "SE manuscript 10xx-2025"
/archive-mail-view "SE manuscript" communications
```

讀 `threads.json` + per-email md，依時序聚合成一個 thread 視圖檔（存在 `.threads/` 子目錄）。視圖是 derived 資料，原始 md 不變，可重複生成。

### `/archive-mail-rebuild-threads` — 從 md 重建 thread 索引（v2.6.0+）

```bash
/archive-mail-rebuild-threads
/archive-mail-rebuild-threads communications
```

掃所有 md 的 YAML frontmatter 重建 `threads.json`。用在索引損壞、手動改過 thread_key、或舊 archive 升級後的 sanity check。

### `/archive-mail-migrate` — 收斂 indices + config 到 namespace（v2.8.0+）

```bash
/archive-mail-migrate --dry-run    # 預覽
/archive-mail-migrate              # 執行
```

把散在各個 archive directory 的 `.email_index.json`、`.threads.json` 以及 `.claude/emails.md` 集中搬到 `.claude/.mail/` namespace（學 IDD 的 `.claude/.idd/` pattern）。`/archive-mail`、`view`、`rebuild-threads` 也會 silent auto-migrate；這個 command 是想一次 batch migrate 所有 archive targets 時用。

## Skills (v2.7.0+)

3 個 skills 由 `/archive-mail` 內部觸發，也可被其他工作流引用：

- **`confirmation-protocol`** — NSQL-style 4-phase workflow（disambiguation → search preview → operation confirmation → execute or iterate）。v2.9.0+ Bootstrap 強制 `TaskCreate` 4 個 phase tasks，靜默 skip = 違規
- **`email-search-disambiguation`** — 處理模糊 filter（中文人名「陳老師」、相對時間「最近」、通用 scope「全部」），列候選讓 user 選定
- **`bulk-operation-preview`** — ≥ 5 封 emails 的 preview format，含 false-positive flagging（✓/⚠/⚠⚠/❓）

## File Layout — `.claude/.mail/` Namespace (v2.8.0+)

學 IDD `.claude/.idd/` 的 namespace 收斂 pattern。Config + state 集中，archive markdown 保持原位：

```
{cwd}/
├── .claude/.mail/                              ← namespace root
│   ├── config.yaml                             ← YAML(filters / aliases / attachment routing) — v2.16.0+;legacy .md fallback 至 v3.0
│   └── state/archives/{slug}/                  ← per-archive-target indices
│       ├── email_index.json                    ← Message-ID 去重
│       └── threads.json                        ← thread 關係索引
├── communications/emails/                      ← archive markdown 目的地（不變）
└── correspondence/attachments/                 ← attachments（不變）
```

從 v2.7.0 ↓ 升級會 silent auto-migrate（archive-mail / view / rebuild-threads 跑時都會 detect 舊位置並搬遷）。也可主動跑 `/archive-mail-migrate` 一次完成。

## Installation

### Option 1: From Release (Recommended)

```bash
# Download latest release
curl -L https://github.com/kiki830621/che-apple-mail-mcp/releases/latest/download/CheAppleMailMCP -o ~/bin/CheAppleMailMCP
chmod +x ~/bin/CheAppleMailMCP
```

### Option 2: Build from Source

```bash
cd /path/to/che-apple-mail-mcp
swift build -c release
cp .build/release/CheAppleMailMCP ~/bin/
```

## Usage Notes

### i18n Best Practices

This MCP follows internationalization best practices:

1. **Use `list_mailboxes` first** to discover available mailbox names for your locale
2. **Standard English names** (`INBOX`, `Drafts`, `Sent`) will try AppleScript system properties
3. **Localized names** (e.g., `收件匣`) should be used exactly as returned by `list_mailboxes`

### Example Workflow

```
# Step 1: Discover mailboxes
list_mailboxes(account="your@email.com")
# Returns: 收件匣, 草稿, 寄件備份, ...

# Step 2: Use exact name
search_emails(account="your@email.com", mailbox="收件匣", query="keyword")
```

## Permissions Required

- **Full Disk Access** or **Mail** permission in System Settings > Privacy & Security
- Grant access when prompted on first run

## Source Code

https://github.com/kiki830621/che-apple-mail-mcp

## Version History

- **v2.19.1–v2.19.5 shell + binary v2.8.1–v2.8.5 patch series**（2026-05-11）— **markdown rendering richness + sanitize_links hardening + cleanup**。 串連發布的 5 個 patch:
  - **v2.19.5 / binary v2.8.5** — nested markdown lists ([#16](https://github.com/PsychQuant/che-apple-mail-mcp/issues/16)) + markdown tables with alignment ([#17](https://github.com/PsychQuant/che-apple-mail-mcp/issues/17)) + malformed multipart handler fallback ([#26](https://github.com/PsychQuant/che-apple-mail-mcp/issues/26)) + `list_emails` SQLite fast-path 3× IPC reduction ([#89](https://github.com/PsychQuant/che-apple-mail-mcp/issues/89))。swift test → 342 (+29 since v2.8.0 series began)
  - **v2.19.4 / binary v2.8.4** — `crossValidateAttachments` helper extracted + 6 filter tests ([#28](https://github.com/PsychQuant/che-apple-mail-mcp/issues/28)) + code fence language hint ([#22](https://github.com/PsychQuant/che-apple-mail-mcp/issues/22) Item D)
  - **v2.19.3 / binary v2.8.3** — chore cluster: 4 dead AppleScript declarations removed ([#82](https://github.com/PsychQuant/che-apple-mail-mcp/issues/82)),3 deprecated `text(_:metadata:)` calls migrated ([#83](https://github.com/PsychQuant/che-apple-mail-mcp/issues/83)),31 lenient `XCTAssertTrue` retrofitted to `assertOrdered` ([#84](https://github.com/PsychQuant/che-apple-mail-mcp/issues/84))
  - **v2.19.2 / binary v2.8.2** — `sanitize_links` hardening grab-bag ([#87](https://github.com/PsychQuant/che-apple-mail-mcp/issues/87)):allowlist tripwire、6 bypass-class regression tests、`htmlEscape` defense-in-depth on `href`、empty-scheme schema docs、payload-scaling latency test
  - **v2.19.1 / binary v2.8.1** — `sanitize_links` schema description consistency across `create_draft`/`reply_email`/`forward_email`/`compose_email` ([#86](https://github.com/PsychQuant/che-apple-mail-mcp/issues/86)) — fixes tool-selecting LLM blindspot
- **v2.19.0 shell + binary v2.8.0**（2026-05-11）— **`sanitize_links` security feature + formal spec coverage** ([release notes](https://github.com/PsychQuant/che-apple-mail-mcp/releases/tag/v2.8.0)). Opt-in URL scheme allowlist for markdown mode ([#19](https://github.com/PsychQuant/che-apple-mail-mcp/issues/19)) defends against `[click](javascript:alert('xss'))` and `data:`/`file:`/`vbscript:` URLs via closed allowlist `{http, https, mailto, tel}`; default `false` preserves backwards compat. Formal `openspec/specs/message-composition/spec.md` Requirement+Scenarios codifying the contract + builder-layer wiring contract tests ([#85](https://github.com/PsychQuant/che-apple-mail-mcp/issues/85)) pinning `sanitizeLinks` forwarding across the 4 script-builder functions. Cluster A hygiene: dead spec scenario delete + count-free CHANGELOG + `assertOrdered` helper ([#20](https://github.com/PsychQuant/che-apple-mail-mcp/issues/20)); reply/forward AppleScript-html-denial docs ([#21](https://github.com/PsychQuant/che-apple-mail-mcp/issues/21)); `list_attachments_batch` SQLite+.emlx cross-validation parity ([#25](https://github.com/PsychQuant/che-apple-mail-mcp/issues/25)); `attachmentNames` <200ms latency budget test ([#27](https://github.com/PsychQuant/che-apple-mail-mcp/issues/27)) + parity invariant ([#32](https://github.com/PsychQuant/che-apple-mail-mcp/issues/32)). `extractHTMLBody` base64+UTF-8-QP decoding fixes ([#73](https://github.com/PsychQuant/che-apple-mail-mcp/issues/73)). 48 tools (was 47). swift test → 313/0/8 (was 309).
- **v2.18.1 shell + binary v2.7.2**（2026-05-10）— **wrapper sidecar tracks actual binary tag** ([#77](https://github.com/PsychQuant/che-apple-mail-mcp/issues/77))。`plugin.json` adds explicit `binary_version` field disambiguating from plugin shell `version`;wrapper writes actual downloaded binary tag (parsed from GitHub release URL) to sidecar,讓 silent skip of binary-only releases 不再發生。Binary v2.7.2 ships #71 fallback parity + cluster #61-64 hardening。
- **v2.18.0 shell + binary v2.7.1**（2026-05-10）— **Staleness Detection** ([#76](https://github.com/PsychQuant/che-apple-mail-mcp/issues/76))。Wrapper atomic-writes `~/bin/.CheAppleMailMCP.runtime.json` 紀錄 `{pid, started_at, version_at_spawn}`;新 `hooks/session-start.sh` 偵測 plugin.json 版本 drift,SIGTERM (+5s grace + SIGKILL fallback) stale MCP PID 讓 host respawn。Sister issue [psychquant-claude-plugins#58](https://github.com/PsychQuant/psychquant-claude-plugins/issues/58) split 為 plugin-update warning。
- **v2.10.3 shell + binary v2.6.0**（2026-05-03）— **Marathon release: 16 issues across 8 PRs** ([release notes](https://github.com/PsychQuant/che-apple-mail-mcp/releases/tag/v2.6.0))。安全強化:id 注入防護 ([#50](https://github.com/PsychQuant/che-apple-mail-mcp/issues/50))、附件路徑 deny-list + opt-in `MAIL_MCP_ATTACHMENT_ROOTS` allow-list ([#38](https://github.com/PsychQuant/che-apple-mail-mcp/issues/38))、email 地址驗證 ([#41](https://github.com/PsychQuant/che-apple-mail-mcp/issues/41))、type-strict handler params ([#35](https://github.com/PsychQuant/che-apple-mail-mcp/issues/35))、新 SECURITY.md ([#48](https://github.com/PsychQuant/che-apple-mail-mcp/issues/48))。Bug fix:`forward_email` plain mode 也嵌入 quoted original ([#44](https://github.com/PsychQuant/che-apple-mail-mcp/issues/44))。Quality:cc_additional case-insensitive dedup ([#34](https://github.com/PsychQuant/che-apple-mail-mcp/issues/34))、schema test type assertions ([#42](https://github.com/PsychQuant/che-apple-mail-mcp/issues/42))、indent cleanup ([#39](https://github.com/PsychQuant/che-apple-mail-mcp/issues/39))、README updates ([#36](https://github.com/PsychQuant/che-apple-mail-mcp/issues/36))、large-thread script size tests ([#49](https://github.com/PsychQuant/che-apple-mail-mcp/issues/49))。Tests:gated integration tests for reply runtime ([#37 + #45](https://github.com/PsychQuant/che-apple-mail-mcp/issues/37))。Smoke matrix templates ([#46 + #47](https://github.com/PsychQuant/che-apple-mail-mcp/issues/46))。**279 tests pass** (+45 from 234)。
- **v2.10.2 shell + binary v2.5.0**（2026-05-03）— **Reply quoted-original fix** ([issue #43](https://github.com/PsychQuant/che-apple-mail-mcp/issues/43))。`reply_email` plain mode 終於把 quoted original 嵌入 draft body — 自 `b8a4a89`（initial release）以來每次 plain reply 都靜默 drop 掉 quoted original，因為 AppleScript `& content` 對 freshly-created outgoing message 讀為空。改用 Swift-side `composeReplyPlainText` helper 預先 fetch + RFC 3676 `> ` prefix 組合 quoted body。Round-1 hardening 涵蓋 CRLF/CR normalization、trailing newline trim、空行 stuffing（`>` 不含 trailing space）、pre-fetch 失敗 graceful degrade。**Wire-output 行為改變**：plain reply body 從 `<user reply>` 變成 `<user reply>\n\n> <quoted lines>`。HTML branch 不變（原本就走對的 architecture）。234 tests pass。Follow-ups #44–#50 已開。
- **v2.10.1 shell + binary v2.4.1**（2026-05-02）— **Save-as-draft popup + path validation fix** ([issue #33 verify findings A+B](https://github.com/PsychQuant/che-apple-mail-mcp/issues/33))。`reply_email` `save_as_draft=true` 不再彈出 Mail.app 視窗（windowClause 改成條件式 with/without opening window），`replyEmail` 加 `validateFilePaths` 鏡像 composeEmail / createDraft 行為。
- **v2.10.0 shell + binary v2.4.0**（2026-05-02）— **Reply-as-draft mode** ([issue #33](https://github.com/PsychQuant/che-apple-mail-mcp/issues/33))。`reply_email` 新增 3 個 optional params：
  - `cc_additional: string[]` — 在 `reply_all` 算出的 CC 之外再加 recipient
  - `attachments: string[]` — POSIX 絕對路徑檔案附件
  - `save_as_draft: boolean` — 存草稿不寄出（預設 false 保 backward compat）

  Unblocks 工作流：reply 一個既存 thread + 加 CC + 附 PDF + 存草稿等手動審。AppleScript native `reply` verb returns `outgoing message`，後續 `save` vs `send` 條件式分流。Backward compatible — 既有 callers 不變。
- **v2.9.0**（2026-05-01）— **Task enforcement**：學 IDD 的 Step 0 Bootstrap Stage Task List 鐵律。`/archive-mail` 強制 `TaskCreate` 10 個 stage tasks，`confirmation-protocol` skill 強制 4 個 phase tasks，靜默 skip = 違規。把 v2.7.0 spec-level confirmation 升級到 enforce-level
- **v2.8.0**（2026-05-01）— **`.claude/.mail/` namespace**：學 IDD 的 `.claude/.idd/` pattern 收斂 config + state。新增 `/archive-mail-migrate`。archive-mail / view / rebuild-threads 都加 auto-migrate。Backward compatible
- **v2.7.0**（2026-05-01）— **NSQL confirmation protocol**：加 3 skills（confirmation-protocol / email-search-disambiguation / bulk-operation-preview）+ 2 rules + CLAUDE.md。archive-mail 預設套用 4-phase confirmation workflow。Backward compatible
- **v2.6.0** — archive-mail YAML frontmatter + threads.json + view/rebuild commands
- **v2.5.0** — composing tools format 參數
- **v2.4.0** — search expansion + Coverage Audit
- **v2.3.0** — attachment auto-download + 分流
