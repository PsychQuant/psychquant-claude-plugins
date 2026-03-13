# Plugin 檔案格式規範

所有 plugin 設定檔的正確 schema。**寫入或修改這些檔案前必須對照本文件。**

---

## hooks.json

**位置**: `plugins/{name}/hooks/hooks.json`

### 正確格式

```json
{
  "hooks": {
    "EventName": [
      {
        "matcher": "ToolPattern",
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/scripts/my-script.sh"
          }
        ]
      }
    ]
  }
}
```

### 結構規則

```
hooks (object)
  └─ EventName (array of entries)
       └─ entry (object)
            ├─ matcher (string, optional) — 篩選 tool，如 "Write|Edit"
            └─ hooks (array of hook objects) ← 必須！
                 └─ hook (object)
                      ├─ type: "command" | "prompt" | "agent"
                      └─ command: string (type=command 時)
```

**關鍵**：每個 entry 必須包含 `hooks` 陣列，即使只有一個 hook。這是三層結構：

```
EventName → [ { hooks: [ { type, command } ] } ]
```

### 常見錯誤

#### 錯誤 1：少了 `hooks` 陣列包裝（最常見！）

```json
// ❌ 錯誤：直接把 hook object 放在 event 陣列裡
{
  "hooks": {
    "SessionStart": [
      { "type": "command", "command": "script.sh" }
    ]
  }
}

// ✅ 正確：多一層 hooks 包裝
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          { "type": "command", "command": "script.sh" }
        ]
      }
    ]
  }
}
```

**錯誤訊息**：`"expected array, received undefined" at hooks.SessionStart.0.hooks`

#### 錯誤 2：`hooks` 是 flat array 帶 `event` 欄位

```json
// ❌ 錯誤：把 hooks 當 flat list
{
  "hooks": [
    { "event": "SessionStart", "type": "command", "command": "script.sh" }
  ]
}

// ✅ 正確：hooks 是 dict，event name 是 key
{
  "hooks": {
    "SessionStart": [
      { "hooks": [{ "type": "command", "command": "script.sh" }] }
    ]
  }
}
```

#### 錯誤 3：缺少頂層 `hooks` key

```json
// ❌ 錯誤
{
  "SessionStart": [...]
}

// ✅ 正確
{
  "hooks": {
    "SessionStart": [...]
  }
}
```

### 可用事件

| Event | 觸發時機 | 常用場景 |
|-------|----------|----------|
| `PreToolUse` | tool 執行前 | 阻擋危險操作 |
| `PostToolUse` | tool 執行後 | 自動格式化 |
| `PostToolUseFailure` | tool 執行失敗後 | 錯誤日誌 |
| `SessionStart` | 對話開始 | 檢查 binary / 環境 |
| `SessionEnd` | 對話結束 | 清理 |
| `UserPromptSubmit` | 用戶送出 prompt | 輸入驗證 |
| `Stop` | Claude 嘗試停止 | 最終驗證 |
| `SubagentStart` | subagent 啟動 | |
| `SubagentStop` | subagent 停止 | |
| `PreCompact` | 壓縮對話前 | |
| `Notification` | 通知發送時 | |
| `TaskCompleted` | task 標記完成 | |
| `TeammateIdle` | agent team 待命 | |
| `PermissionRequest` | 權限對話框顯示 | |

### Hook 類型

| type | 說明 | 額外欄位 |
|------|------|----------|
| `command` | 執行 shell 命令 | `command` (string) |
| `prompt` | LLM 評估 prompt | `prompt` (string, 用 `$ARGUMENTS` 取得 context) |
| `agent` | 帶工具的 agent 驗證器 | `prompt` (string) |

### 腳本要求

- 必須有 executable 權限：`chmod +x script.sh`
- 必須有 shebang line：`#!/bin/bash` 或 `#!/usr/bin/env bash`
- 使用 `${CLAUDE_PLUGIN_ROOT}` 取代硬編碼路徑

---

## plugin.json

**位置**: `plugins/{name}/.claude-plugin/plugin.json`

### 正確格式

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

### 欄位說明

| 欄位 | 必填 | 說明 |
|------|------|------|
| `name` | 是（如有 manifest） | kebab-case，無空格，max 64 字元 |
| `version` | 建議 | semver 格式（1.0.0） |
| `description` | 建議 | 簡短功能說明 |
| `author` | 否 | `{ "name": "...", "email": "...", "url": "..." }` |
| `license` | 否 | SPDX 標識（MIT, Apache-2.0） |
| `keywords` | 否 | 發現用標籤 |
| `homepage` | 否 | 文件 URL |
| `repository` | 否 | 原始碼 URL |

### 進階欄位（自訂路徑）

```json
{
  "commands": ["./custom/cmd.md"],
  "agents": "./custom/agents/",
  "skills": "./custom/skills/",
  "hooks": "./config/hooks.json",
  "mcpServers": "./mcp-config.json",
  "lspServers": "./.lsp.json",
  "outputStyles": "./styles/"
}
```

自訂路徑是**追加**而非取代預設目錄。

---

## marketplace.json

**位置**: `.claude-plugin/marketplace.json`（repo 根目錄）

### 正確格式

```json
{
  "$schema": "https://anthropic.com/claude-code/marketplace.schema.json",
  "name": "marketplace-name",
  "description": "Marketplace 說明",
  "owner": {
    "name": "Author",
    "email": "author@example.com"
  },
  "homepage": "https://github.com/...",
  "plugins": [
    {
      "name": "plugin-name",
      "version": "1.0.0",
      "description": "說明",
      "author": { "name": "Author" },
      "source": "./plugins/plugin-name",
      "category": "development"
    }
  ]
}
```

### 版本同步規則

- `marketplace.json` 的 `version` 和 `plugins/{name}/.claude-plugin/plugin.json` 的 `version` **必須一致**
- 如果兩邊都有設定，`plugin.json` 優先
- 建議只在一個地方設定版本（避免不同步）
- **新 plugin 必須手動加入 `plugins` 陣列**，不會自動偵測

### category 常用值

`development` | `productivity` | `creative`

### 重要提醒

修改 plugin 但沒 bump `marketplace.json` 的版本 → `claude plugin update` 會說 "already at latest" → cache 不會更新 → 修復不會生效。

如果已經發生這種情況，用 uninstall + reinstall 強制刷新 cache：
```bash
claude plugin uninstall {name}
claude plugin install {name}@{marketplace}
```

---

## .mcp.json

**位置**: `plugins/{name}/.mcp.json`

### 正確格式

```json
{
  "mcpServers": {
    "server-name": {
      "command": "${CLAUDE_PLUGIN_ROOT}/bin/wrapper.sh",
      "args": ["--flag", "value"],
      "env": {
        "KEY": "value"
      }
    }
  }
}
```

### 注意事項

- 所有路徑使用 `${CLAUDE_PLUGIN_ROOT}`，不要硬編碼
- `command` 指向的 binary/script 必須有 executable 權限
- plugin 安裝後是從 cache 執行，不能用 `../` 引用 plugin 外的檔案

---

## .lsp.json

**位置**: `plugins/{name}/.lsp.json`

### 正確格式

```json
{
  "language-id": {
    "command": "binary-name",
    "args": ["serve"],
    "extensionToLanguage": {
      ".ext": "language-id"
    }
  }
}
```

### 必填欄位

- `command` — LSP binary（必須在 PATH 中）
- `extensionToLanguage` — 副檔名 → 語言 ID 對應

---

## SKILL.md

**位置**: `plugins/{name}/skills/{skill-name}/SKILL.md`

### Frontmatter 格式

```yaml
---
name: skill-name
description: 說明（Claude 用此判斷何時自動觸發）
argument-hint: <required> [optional]
allowed-tools:
  - Read
  - Bash(git:*)
  - mcp__server__*
disable-model-invocation: true
user-invocable: true
context: fork
agent: Explore
model: haiku
---

# Skill 內容（Markdown）
```

### Frontmatter 欄位

| 欄位 | 預設 | 說明 |
|------|------|------|
| `name` | 目錄名 | 顯示名稱，也是 `/skill-name` |
| `description` | 第一段 | Claude 自動觸發的依據 |
| `argument-hint` | — | autocomplete 提示 |
| `allowed-tools` | — | 允許的工具（不需 permission） |
| `disable-model-invocation` | false | true = 只能用戶手動觸發 |
| `user-invocable` | true | false = 不出現在 `/` 選單 |
| `context` | — | `fork` = 在 subagent 中執行 |
| `agent` | general-purpose | context: fork 時使用哪個 agent |
| `model` | — | 指定模型 |

### 變數替換

| 變數 | 說明 |
|------|------|
| `$ARGUMENTS` | 所有傳入參數 |
| `$ARGUMENTS[N]` 或 `$N` | 第 N 個參數（0-based） |
| `${CLAUDE_SESSION_ID}` | 當前 session ID |
| `${CLAUDE_SKILL_DIR}` | SKILL.md 所在目錄 |

### 動態注入

`` !`command` `` — 在 skill 載入前執行 shell command，輸出取代 placeholder。

---

## 目錄結構規則

```
plugin-root/
├── .claude-plugin/
│   └── plugin.json        ← 只有 manifest 在這裡
├── skills/                ← 在 root，不在 .claude-plugin/ 裡
│   └── skill-name/
│       └── SKILL.md
├── agents/                ← 在 root
├── hooks/                 ← 在 root
│   └── hooks.json
├── .mcp.json              ← 在 root
├── .lsp.json              ← 在 root
└── bin/                   ← 在 root
```

**絕對不要**把 skills/、commands/、hooks/、agents/ 放進 `.claude-plugin/` 目錄。

---

最後更新: 2026-03-14
