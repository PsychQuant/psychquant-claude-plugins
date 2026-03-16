---
name: which
description: |
  找出當前任務最適合的工具。啟動一個獨立的 claude -p 掃描所有可用的
  MCP tools、skills、commands，回傳最相關的工具清單。
  不佔主 session context。
  當用戶說「該用什麼工具」「有什麼工具可以用」「which tool」「找工具」時觸發。
argument-hint: "[task description]"
allowed-tools:
  - Bash(claude:*)
---

# Which — 工具探索

用獨立的 `claude -p` 掃描所有可用工具，找出最適合當前任務的。

## 為什麼用 claude -p？

- 主 session 不需要載入 200+ 工具的完整描述
- `claude -p` 啟動時自動載入所有 MCP servers + plugins
- 回傳結果只有幾行文字，不佔主 session context

## Execution

```bash
claude -p "任務：$ARGUMENTS

請掃描你所有可用的工具（MCP tools、skills、slash commands），列出完成這個任務可能會用到的工具。

輸出格式（markdown 表格）：
| 工具名稱 | 類型 | 用途 |
|----------|------|------|

類型用：MCP / Skill / Command / CLI" --output-format text --max-turns 1
```

直接把 `claude -p` 的回傳顯示給使用者。
