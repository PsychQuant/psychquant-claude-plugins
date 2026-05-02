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
# Explicit filter mode (available now)
/archive-mail some@example.com
/archive-mail some@example.com communications
```

> **Roadmap — zero-arg mode (not yet implemented, tracked in #13)**
> Planned: `/archive-mail` (no args) will read `.claude/.mail/config.md` frontmatter for
> filters / output_dir / last_archived / exclude_mailboxes. Do **not** call it
> without args today — it requires a filter parameter.

每封 md 帶 YAML frontmatter（`message_id` / `thread_key` / `in_reply_to` / `date` / `sender` / `direction`），並同步維護 `email_index.json`（Message-ID 去重）與 `threads.json`（thread 關係索引），v2.8.0+ 收斂到 `.claude/.mail/state/archives/{slug}/`。

詳細 spec 見 [`commands/archive-mail.md`](commands/archive-mail.md)。

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
│   ├── config.md                               ← YAML frontmatter（filters / aliases / attachment routing）
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
