# Che's Claude Code Plugins

個人 Claude Code Plugin Marketplace，專注於學術研究與生產力工具。

## 安裝

```bash
# 添加 Marketplace
/plugin marketplace add PsychQuant/psychquant-claude-plugins

# 安裝 Plugin
/plugin install mcp-tools@PsychQuant/psychquant-claude-plugins
/plugin install che-things-mcp@PsychQuant/psychquant-claude-plugins
/plugin install che-ical-mcp@PsychQuant/psychquant-claude-plugins
```

## Plugins

| Plugin | 說明 | MCP Tools |
|--------|------|-----------|
| **che-things-mcp** | Things 3 任務管理 | 47 |
| **che-ical-mcp** | macOS 行事曆 & 提醒事項 | 20 |
| **che-apple-mail-mcp** | Apple Mail 郵件管理 + 歸檔 | 60+ |
| **che-word-mcp** | Word 文件處理 | 104 |
| **che-duckdb-mcp** | DuckDB 資料庫操作 | 14 |
| **mcp-tools** | MCP Server 開發工具集 | - |
| **r-shiny-debugger** | R Shiny App 功能測試 | - |
| **ai-docs-guide** | Claude Code + OpenAI 文檔查詢助手 | - |
| **claude-config-guide** | ~~Claude Code 設定查詢~~ (已被 ai-docs-guide 取代) | - |
| **postgresql-guide** | PostgreSQL 文檔查詢助手 | - |
| **che-dropbox-ignore** | Dropbox 同步排除管理 | - |
| **claude-switch** | Claude Code 模型切換 | - |
| **che-bot-toolkit** | Bot 開發工具集 | - |
| **che-xcode-mcp** | Xcode / App Store Connect | 80+ |

---

## MCP Server Plugins

### che-things-mcp

Things 3 任務管理，提供完整的 GTD 工作流程支援。

**需求**: [CheThingsMCP](https://github.com/kiki830621/che-things-mcp/releases) binary

```bash
# 快速指令
/today                    # 今日任務
/inbox                    # 收件匣
/quick-task Buy milk      # 快速建立任務
/projects                 # 專案總覽
/upcoming                 # 即將到來
```

| 功能分類 | 說明 |
|----------|------|
| List Access | Inbox, Today, Upcoming, Anytime, Someday, Logbook |
| Task CRUD | 建立、更新、完成、刪除、搜尋任務 |
| Project/Area | 專案與區域管理 |
| Tags | 標籤管理（支援階層） |
| Batch Ops | 批次建立、完成、刪除、移動、更新 |
| Checklist | 子項目清單管理 |

---

### che-ical-mcp

macOS 原生行事曆與提醒事項整合，使用 EventKit 框架。

**需求**: [CheICalMCP](https://github.com/kiki830621/che-ical-mcp/releases) binary

```bash
# 快速指令
/today                           # 今日行程
/week                            # 本週總覽
/quick-event Meeting at 2pm      # 快速建立事件
/remind Call mom tomorrow        # 快速建立提醒
```

| 功能分類 | 說明 |
|----------|------|
| Calendars | 列出、建立、刪除行事曆 |
| Events | 事件 CRUD、搜尋、衝突檢查 |
| Reminders | 提醒事項 CRUD |
| Batch Ops | 批次建立、移動、刪除事件 |
| Utilities | 重複事件偵測、事件複製 |

---

### che-apple-mail-mcp

Apple Mail 郵件管理，透過 AppleScript 原生整合。

**需求**: [CheAppleMailMCP](https://github.com/kiki830621/che-apple-mail-mcp/releases) binary

```bash
# 郵件歸檔
/che-apple-mail-mcp:archive-mail d06227105@ntu.edu.tw
/che-apple-mail-mcp:archive-mail d06227105@ntu.edu.tw communication/emails
```

| 功能分類 | 說明 |
|----------|------|
| Mailboxes | 列出帳號、信箱 |
| Emails | 搜尋、讀取、回覆、轉寄 |
| Drafts | 草稿管理 |
| Archive | 歸檔郵件到 Markdown |
| Rules | 郵件規則管理 |

---

## Skill Plugins

### mcp-tools

MCP Server 開發必備工具，提供完整的除錯與測試流程。

```bash
/mcp-tools:diagnose che-ical-mcp   # 連線診斷
/mcp-tools:debug che-ical-mcp      # 功能除錯
/mcp-tools:test che-ical-mcp       # 完整測試
/mcp-tools:new-mcp-app             # 建立新 MCP 專案
/mcp-tools:mcp-deploy              # 部署 MCP Server
```

| Command | 用途 |
|---------|------|
| `diagnose` | 確認 MCP Server 連線正常 |
| `debug` | 診斷功能問題（權限、框架特定） |
| `test` | 驗證所有 tools 正常運作 |
| `new-mcp-app` | 互動式建立新 MCP 專案 |
| `mcp-deploy` | 編譯、打包、發布 GitHub Release |
| `mcp-upgrade` | 分析專案並提供升級建議 |
| `mcp-install` | 從 GitHub Release 下載安裝 |
| `mcpb-sync` | Binary 一致性同步（Swift） |

---

### r-shiny-debugger

整合前端 (agent-browser) 與後端 (R console) 的 R Shiny App 功能測試。

```bash
/shiny-debug
/shiny-debug 上傳 CSV 後圖表會更新
```

---

### ai-docs-guide

Claude Code + OpenAI 文檔查詢助手。整合兩個 Auto-triggered Skills，自動根據問題類型 WebFetch 對應官方文檔。

**包含 Skills**:
- `claude-docs-guide` — Claude Code CLI / API / SDK 文檔
- `openai-docs-guide` — OpenAI API / SDK / Models 文檔

**特點**: 繞過 OpenAI Docs MCP 壞掉的 `fetch_openai_doc` tool，直接 WebFetch 官方文檔 URL。

---

### claude-config-guide (deprecated)

> **已被 `ai-docs-guide` 取代**。功能完全包含在 `ai-docs-guide` 的 `claude-docs-guide` skill 中。

## License

MIT
