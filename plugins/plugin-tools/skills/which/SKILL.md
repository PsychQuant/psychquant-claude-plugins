---
name: which
description: |
  找出當前任務可能用到的工具。啟動一個獨立的 claude -p 掃描所有可用的
  MCP tools、skills、commands、agents、plugins，回傳工具清單。
  不佔主 session context。
  當用戶說「該用什麼工具」「有什麼工具可以用」「which tool」「找工具」時觸發。
argument-hint: "[task description]"
allowed-tools:
  - Bash(claude:*)
---

# Which — 工具探索

用獨立的 `claude -p` 掃描所有可用工具，找出完成任務可能需要的。

## 為什麼用 claude -p？

- 主 session 不需要掃描 200+ 工具的完整描述
- `claude -p` 啟動時自動載入所有已安裝的 MCP servers、plugins（含 skills、commands、agents）
- 回傳結果只有幾行文字，不佔主 session context

## claude -p 啟動時自動載入的東西

| 類型 | 來源 |
|------|------|
| MCP tools | ~/.claude.json + .mcp.json + plugin 的 .mcp.json |
| Skills | 所有已安裝 plugin 的 skills/ |
| Commands | 所有已安裝 plugin 的 commands/ |
| Agents | 所有已安裝 plugin 的 agents/ |
| LSP servers | plugin 的 .lsp.json |

所以 claude -p 看得到所有已安裝的東西，不需要手動餵清單。

## Execution

```bash
claude -p "任務：$ARGUMENTS

請掃描你所有可用的工具，列出完成這個任務可能會用到的。
掃描範圍包括：
1. MCP tools（mcp__* 開頭的工具）
2. Skills（plugin 提供的 /plugin-name:skill-name）
3. Commands（slash commands）
4. Agents（可呼叫的 sub-agents）
5. Hooks（這個任務可能會觸發哪些 PreToolUse / PostToolUse / Stop hooks）
6. LSP servers（如果任務涉及特定語言的程式碼）
7. CLI 工具（如果你知道有適合這個任務的 CLI 也一併列出）

輸出格式（markdown 表格）：
| 工具名稱 | 類型 | 用途 |
|----------|------|------|

類型用：MCP / Skill / Command / Agent / Hook / LSP / CLI
對於 Hooks，說明什麼操作會觸發它、觸發後會發生什麼。" --output-format text --max-turns 1
```

直接把 `claude -p` 的回傳顯示給使用者。
