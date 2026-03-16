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

### Step 1: 掃描本機所有可執行指令

直接掃 `$PATH` 裡所有 bin 目錄 — 不管是 brew、apt、npm、pip、cargo、手動裝的，全部一次掃到。
典型的電腦約 1000-2000 個指令，~4K tokens，對 `claude -p` 不是負擔。

```bash
# 掃描 PATH 裡所有可執行指令（一行搞定，涵蓋所有 package manager）
ALL_CMDS=$(ls /usr/bin /usr/local/bin /opt/homebrew/bin ~/bin ~/.local/bin ~/go/bin ~/.cargo/bin 2>/dev/null | sort -u | tr '\n' ', ')

# R packages（如果有裝）
R_PKGS=$(Rscript -e "cat(installed.packages()[,'Package'], sep=', ')" 2>/dev/null)
```

### Step 2: 呼叫 claude -p

```bash
claude -p "任務：$ARGUMENTS

請掃描你所有可用的工具，列出完成這個任務可能會用到的。

掃描範圍：
1. MCP tools（mcp__* 開頭的工具）
2. Skills（plugin 提供的 /plugin-name:skill-name）
3. Commands（slash commands）
4. Agents（可呼叫的 sub-agents）
5. Hooks（這個任務可能會觸發哪些 PreToolUse / PostToolUse / Stop hooks）
6. LSP servers（如果任務涉及特定語言的程式碼）
7. CLI 工具（從下方已安裝清單中挑選相關的）

本機 PATH 中所有可用指令：
$ALL_CMDS

R packages（如果有）：$R_PKGS

輸出格式（markdown 表格）：
| 工具名稱 | 類型 | 用途 |
|----------|------|------|

類型用：MCP / Skill / Command / Agent / Hook / LSP / CLI
對於 Hooks，說明什麼操作會觸發它、觸發後會發生什麼。
對於 CLI，只列跟任務相關的，不用全部列出。
如果你不確定某個 CLI 工具的用途，可以用 Bash 跑 '<tool> --help | head -5' 確認。" --output-format text --max-turns 3
```

### Step 3: 輸出

直接把 `claude -p` 的回傳顯示給使用者。
