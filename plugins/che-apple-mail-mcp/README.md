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

**v2.12.0–v2.15.0 highlights**:

- **v2.15.0** (#45) — Inline `cid:` 圖片保留路徑:從 HTML body 解析 `<img src="cid:..." alt="...">` → save 到 `attachments/<stem>/inline/<filename>`,Markdown 加獨立 `Inline images:` section(`![]()` syntax 直接 render),Step 8a Coverage Audit 拆 explicit + inline 兩部分。修掉 dogfood gap:archive 「Solution? (affine repre + Iverson)」 thread CleanShot screenshot 全 miss
- **v2.14.0** (#18) — Opt-in `dedup_strategy` config:`index`(預設) | `last_archived`(輕量,以 ISO date 作 date_from) | `both`(雙 dedup);零 breaking,既有 archive 走 default
- **v2.13.0** (#17) — Markdown template default 簡化:預設 `Subject/From/To/Date` 多行 header + body,對應 tatsuma 50 個歷史檔。User 想要原 4-section 模板:`enrichment: summary+todos`
- **v2.16.0** (#47) — Config schema rename:`.claude/.mail/config.md` → `.claude/.mail/config.yaml`(副檔名 ↔ 內容語意一致;legacy `.md` 仍 fallback,v3.0 移除)。auto-migrate 在 archive-mail / archive-mail-migrate 觸發,user 不需動手
- **v2.12.0** (#13/#21) — Zero-arg mode:`/archive-mail` 不帶參數從 `.claude/.mail/config.yaml`(legacy `.md` fallback)讀 `filters` / `output_dir` / `last_archived` / `exclude_mailboxes`;`argument-hint` 改 `[email-filter]` 反映可選性

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
