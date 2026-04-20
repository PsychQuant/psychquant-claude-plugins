# che-apple-notes-mcp — CLAUDE.md

## Purpose

macOS Apple Notes MCP plugin. Wraps the [CheAppleNotesMCP](https://github.com/PsychQuant/che-apple-notes-mcp) binary via auto-download wrapper. Uses **SQLite fast read + AppleScript safe write** dual-track architecture (same pattern as `che-apple-mail-mcp`).

## Components

### MCP Tools (18)

| Category | Tools | Backend |
|----------|-------|---------|
| Folders | `list_folders`, `create_folder`, `update_folder`, `delete_folder` | SQLite read / AS write |
| Notes | `list_notes`, `list_notes_quick`, `get_note`, `create_note`, `update_note`, `delete_note`, `move_note` | SQLite read / AS write |
| Search | `search_notes` | SQLite (FDA required) |
| Batch | `create_notes_batch`, `move_notes_batch`, `delete_notes_batch` | AS write |
| Undo/Redo | `undo`, `redo`, `undo_history` | AS write + in-memory stack |

MCP namespace: `mcp__che-apple-notes-mcp__<tool>`.

### Skills

| Skill | 用途 |
|-------|------|
| `notes-management` | 工作流指南：tool 分類、body 雙軌規格、account disambiguation、常見 workflow、v0.1.0 已知限制 |

### Slash Commands

| Command | 用途 |
|---------|------|
| `/che-apple-notes-mcp:new-note` | 從自然語言建 note |
| `/che-apple-notes-mcp:search-notes` | 關鍵字搜尋 + 結果摘要 |
| `/che-apple-notes-mcp:list-folders` | 列出所有 folder（按帳號分組） |

### Hooks

| Hook | 用途 |
|------|------|
| `SessionStart → check-mcp.sh` | 啟動時檢查 `~/bin/CheAppleNotesMCP` 是否安裝、版本是否最新；缺的話提示下載指令 |

## Binary Dependency

這是 binary-based plugin：`.mcp.json` 指向 `bin/che-apple-notes-mcp-wrapper.sh`，wrapper 會 auto-download `CheAppleNotesMCP` binary 到 `~/bin/`。

- Binary repo: [`PsychQuant/che-apple-notes-mcp`](https://github.com/PsychQuant/che-apple-notes-mcp)
- Binary name: `CheAppleNotesMCP`
- Release asset naming: asset filename must contain `CheAppleNotesMCP`

### Plugin vs Binary Version Sync

| 改動類型 | 處理 |
|----------|------|
| 改 plugin shell（commands、skill、hooks、wrapper） | `/plugin-tools:plugin-update che-apple-notes-mcp` |
| 改 binary source（tool 新增、bug fix） | 先 `/mcp-tools:mcp-deploy` 到 binary repo → 發 GitHub Release → 再跑 `plugin-update` |
| 同時改兩邊 | `plugin-update`（v1.11+ 會 detect 依賴不同步並 prompt 連動 mcp-deploy） |

## Permissions

Plugin 跑在使用者層級，需要兩個 TCC 權限：

| 權限 | 觸發時機 | 缺的話 |
|------|----------|--------|
| Automation → Notes.app | 第一次呼叫任何 write tool 或 `--setup` | 無法 create/update/delete |
| Full Disk Access（FDA） | SQLite 快讀 | Read 自動 fallback 到 AppleScript（慢 50–500×，但 `search_notes` 和 `list_notes_quick` 會 error，因為需 SQLite） |

**FDA 無法程式觸發對話框**。使用者要手動去 System Settings → Privacy & Security → Full Disk Access 把 `~/bin/CheAppleNotesMCP` 加進去。

## Development

- Update after plugin-shell changes: `/plugin-tools:plugin-update che-apple-notes-mcp`
- Full release (binary + plugin): `/plugin-tools:plugin-deploy che-apple-notes-mcp`
- Binary source edits: go to `che-mcps/che-apple-notes-mcp/` then `/mcp-tools:mcp-deploy`
- Health check: `/plugin-tools:plugin-health`

## v0.1.0 Known Limits（寫進 README，使用者會看到）

- Locked notes: body AES-encrypted，只回 metadata
- Pin/unpin 寫入：AS 不支援
- Attachment 寫入：不支援（讀 metadata OK）
- Body HTML from SQLite：降級為 plaintext（protobuf attribute runs 待 v0.2.0）
- 1 MB body 上限
- macOS 13/14/15 測過；未來 macOS 若改 protobuf schema 需升級 decoder
