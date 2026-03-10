# CLAUDE.md

This file provides guidance to Claude Code when working with this plugin marketplace.

## 專案概覽

這是 Che Cheng 的個人 Claude Code Plugin Marketplace，專注於學術研究與生產力工具。

## 目錄結構

```
psychquant-claude-plugins/
├── .claude-plugin/
│   └── marketplace.json         # Marketplace 元數據
├── plugins/
│   ├── che-apple-mail-mcp/      # Apple Mail MCP + 歸檔
│   ├── che-archive-lines/       # LINE 聊天記錄歸檔
│   ├── che-bot-toolkit/         # Bot 開發工具集
│   ├── codex-batch/             # Codex CLI 批次生成
│   ├── che-dropbox-ignore/      # Dropbox 同步排除管理
│   ├── che-duckdb-mcp/          # DuckDB 資料庫操作
│   ├── che-ical-mcp/            # macOS 行事曆 & 提醒事項
│   ├── che-things-mcp/          # Things 3 任務管理
│   ├── che-word-mcp/            # Word 文件處理
│   ├── che-xcode-mcp/           # Xcode / App Store Connect
│   ├── ai-docs-guide/           # Claude Code + OpenAI 文檔查詢
│   ├── claude-config-guide/     # [deprecated] → ai-docs-guide
│   ├── claude-switch/           # Claude Code 模型切換
│   ├── mcp-tools/               # MCP Server 開發工具集
│   ├── postgresql-guide/        # PostgreSQL 文檔查詢
│   └── r-shiny-debugger/        # R Shiny Debug 工具
└── README.md
```

## Plugins 說明

### archive-mail (v2.0.0)

**用途**: 歸檔 Apple Mail 郵件到 Markdown 檔案

**依賴**:
- `apple-mail` MCP server（工具前綴：`mcp__apple-mail__*`）

**使用**:
```bash
/archive-mail d06227105@ntu.edu.tw
/archive-mail d06227105@ntu.edu.tw communication/emails
```

**功能**:
- 搜尋指定聯絡人的收/發郵件
- 轉換為 Markdown 格式，含元數據表格
- Message-ID 去重，避免重複歸檔
- AI 自動提取重點摘要和待辦事項

### r-shiny-debugger (v1.0.0)

**用途**: 功能測試導向的 R Shiny App Debug 工具

**依賴**:
- `agent-browser` CLI 工具（全域安裝）
- R 和 Rscript

**使用**:
```bash
/shiny-debug                           # 互動模式
/shiny-debug 上傳 CSV 後圖表會更新      # 口頭描述測試
/shiny-debug --file                    # 執行 .shiny-tests.yaml
/shiny-debug --file test_upload        # 執行指定測試案例
```

**功能**:
- 自動啟動 Shiny app 並監控 R console
- 使用 agent-browser 進行前端互動
- 支援口頭描述的功能測試
- 支援 `.shiny-tests.yaml` 定義測試案例
- 同時觀察前端 UI 變化和後端 R 輸出

### che-archive-lines (v1.0.0)

**用途**: 自動化 LINE macOS 聊天記錄的歸檔

**依賴**:
- `cliclick` CLI 工具（`brew install cliclick`）
- LINE macOS 已安裝並登入
- Accessibility 權限

**使用**:
```bash
/archive-lines calibrate   # 第一次使用：校準按鈕位置
/archive-lines save        # 自動儲存當前聊天
/archive-lines test        # 測試點擊位置
```

**功能**:
- 自動化 LINE 的「儲存聊天」功能
- 使用相對座標，視窗移動時自動調整
- 設定儲存在 `~/.config/che-archive-lines/config.json`

**技術說明**:
- LINE 使用 Qt 框架，不支援 macOS Accessibility API
- 使用 cliclick 進行座標點擊自動化

### ai-docs-guide (v1.0.0)

**用途**: Auto-triggered Skills，自動 WebFetch Claude Code 和 OpenAI 官方文檔

**Skills**:
- `claude-docs-guide` — Claude Code CLI 設定（MCP、settings、hooks、skills）、Claude API/SDK
- `openai-docs-guide` — OpenAI API（Responses API、Chat Completions、models）、Agents SDK、Realtime API

**背景**:
- OpenAI Docs MCP 的 `fetch_openai_doc` tool 壞掉（server-side bug），所有 URL 回 404
- 此 plugin 繞過壞掉的 MCP fetch，直接 WebFetch `https://developers.openai.com/docs/...`
- 取代了舊的 `claude-config-guide` plugin

### che-dropbox-ignore (scaffold)

**用途**: 管理 Dropbox 同步排除，自動對指定路徑設定 `com.dropbox.ignored` xattr 標記

**背景**:
- Dropbox CloudStorage 路徑下的檔案會經過 macOS File Provider
- `.git` 目錄、`.xcodeproj` 內部狀態檔等不需要同步
- `xattr -w com.dropbox.ignored 1 <path>` 可排除同步，但需要手動管理

**預計功能**:
- 掃描專案目錄，自動找出應排除同步的路徑（`.git`、build artifacts 等）
- 對目標設定 `com.dropbox.ignored` xattr
- 提供 hook 在工具操作後自動維護排除設定

**狀態**: 目錄已建立，功能待開發

---

## MCP 依賴說明

### apple-mail MCP

**全域設定位置**: `~/.claude/settings.json`

**設定格式**:
```json
{
  "mcpServers": {
    "apple-mail": {
      "command": "path/to/apple-mail-mcp"
    }
  }
}
```

**工具命名規則**:
- MCP 工具前綴格式：`mcp__{server-key}__`
- 範例：`mcp__apple-mail__search_emails`

**在 plugin 中聲明依賴**:
```yaml
---
allowed-tools: mcp__apple-mail__*, Bash(mkdir:*), Read, Write, Glob
---
```

## 開發指南

### 新增 / 更新 Plugin

1. 在 `plugins/` 下建立目錄
2. 建立 `.claude-plugin/plugin.json`
3. 建立 `commands/` 目錄和命令檔案
4. **必須** 同步更新 `.claude-plugin/marketplace.json`（版本號 + 描述）

> **重要**：每次修改任何 plugin 的版本、描述、或新增/移除 command 時，**都必須同步更新 `.claude-plugin/marketplace.json`** 中對應的 entry。marketplace.json 是 Marketplace 的索引，不同步會導致使用者看到過時的資訊。

### Plugin 結構範本

```
plugins/new-plugin/
├── .claude-plugin/
│   └── plugin.json           # 必須
├── commands/
│   └── command-name.md       # 至少一個命令
└── README.md                 # 建議
```

### plugin.json 範本

```json
{
  "name": "plugin-name",
  "version": "1.0.0",
  "description": "簡短說明",
  "author": { "name": "Che Cheng" },
  "license": "MIT",
  "keywords": ["keyword1", "keyword2"]
}
```

### 命令檔案 Frontmatter

```yaml
---
description: 命令的簡短說明
argument-hint: <必填參數> [可選參數]
allowed-tools: Tool1, Tool2, mcp__server__*
---
```

## 安裝方式

```bash
# 添加 Marketplace
/plugin marketplace add PsychQuant/psychquant-claude-plugins

# 安裝 Plugin
/plugin install archive-mail@PsychQuant/psychquant-claude-plugins
/plugin install r-shiny-debugger@PsychQuant/psychquant-claude-plugins
```

---

最後更新: 2026-02-14
維護者: Che Cheng
