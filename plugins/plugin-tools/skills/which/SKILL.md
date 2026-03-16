---
name: which
description: |
  找出當前任務可能用到的工具。啟動一個獨立的 claude -p 掃描所有可用的
  MCP tools、skills、commands、agents、hooks、LSP、CLI，回傳工具清單。
  不佔主 session context。
  當用戶說「該用什麼工具」「有什麼工具可以用」「which tool」「找工具」時觸發。
argument-hint: "[task description]"
allowed-tools:
  - Bash(claude:*)
  - Bash(ls:*)
  - Bash(echo:*)
  - Bash(tr:*)
  - Bash(sort:*)
  - Bash(head:*)
  - Bash(wc:*)
  - Bash(command:*)
  - Bash(cut:*)
  - Bash(sed:*)
  - Bash(Rscript:*)
  - Bash(pip3:*)
---

# Which — 工具探索

用獨立的 `claude -p` 掃描所有可用工具，找出完成任務可能需要的。

## 為什麼用 claude -p？

- 主 session 不需要掃描 200+ 工具的完整描述
- `claude -p` 啟動時自動載入所有已安裝的 MCP servers、plugins（含 skills、commands、agents）
- 回傳結果只有幾行文字，不佔主 session context

## claude -p 自動載入的東西

| 類型 | 來源 |
|------|------|
| MCP tools | ~/.claude.json + .mcp.json + plugin .mcp.json |
| Skills | 所有已安裝 plugin 的 skills/ |
| Commands | 所有已安裝 plugin 的 commands/ |
| Agents | 所有已安裝 plugin 的 agents/ |
| Hooks | 所有已安裝 plugin 的 hooks/ |
| LSP servers | plugin 的 .lsp.json |

不需要手動餵清單，claude -p 自己就看得到。
只有 CLI 和語言 packages 需要額外掃描餵進去。

## Execution

### Step 1: 掃描本機 CLI 工具

```bash
# 動態讀 $PATH，不硬編碼目錄
# Empty PATH segments (leading/trailing :) mean current directory
ALL_CMDS=$(echo "$PATH" | tr ':' '\n' | sed 's/^$/./' | while read dir; do ls "$dir" 2>/dev/null; done | sort -u | tr '\n' ', ')

# 語言 packages（先偵測有沒有裝，有才掃；截斷避免塞爆 prompt）
R_PKGS=$(command -v Rscript >/dev/null 2>&1 && Rscript -e "cat(installed.packages()[,'Package'], sep=', ')" 2>/dev/null)
PY_PKGS=$(command -v pip3 >/dev/null 2>&1 && pip3 list --format=freeze 2>/dev/null | cut -d= -f1 | head -200 | tr '\n' ', ')
```

### Step 2: 呼叫 claude -p

```bash
claude -p "任務：$ARGUMENTS

請掃描你所有可用的工具，列出完成這個任務可能會用到的。
用繁體中文回答。

掃描範圍：
1. MCP tools（mcp__* 開頭的工具）
2. Skills（plugin 提供的 /plugin-name:skill-name）
3. Commands（slash commands）
4. Agents（可呼叫的 sub-agents）
5. Hooks（這個任務可能會觸發哪些 hooks，說明觸發條件和效果）
6. LSP servers（如果任務涉及特定語言的程式碼）
7. CLI 工具（從下方已安裝清單中挑選相關的）

本機 PATH 中所有可用指令：
$ALL_CMDS

${R_PKGS:+R packages: $R_PKGS}
${PY_PKGS:+Python packages (top 200): $PY_PKGS}

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
