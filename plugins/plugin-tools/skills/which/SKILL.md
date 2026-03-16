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

### Step 1: 掃描本機 CLI 工具

在呼叫 `claude -p` 前，收集這台電腦實際安裝的 CLI 工具。
每個指令都用 `2>/dev/null` — 沒裝的 package manager 會回傳空字串，不影響流程。

```bash
# Package managers（每台電腦不同，有什麼掃什麼）
BREW_LIST=$(brew list --formula 2>/dev/null | tr '\n' ', ')
APT_LIST=$(dpkg --get-selections 2>/dev/null | awk '{print $1}' | tr '\n' ', ')
NPM_GLOBAL=$(npm -g ls --depth=0 --parseable 2>/dev/null | xargs -I{} basename {} | tail -n +2 | tr '\n' ', ')
PIP_LIST=$(pip3 list --format=freeze 2>/dev/null | cut -d= -f1 | tr '\n' ', ')
CARGO_LIST=$(cargo install --list 2>/dev/null | grep -E '^\S' | awk '{print $1}' | tr '\n' ', ')

# Executables in common paths
BIN_TOOLS=$(ls ~/bin /usr/local/bin ~/.local/bin 2>/dev/null | sort -u | tr '\n' ', ')

# Language-specific（有裝才掃）
R_PKGS=$(Rscript -e "cat(installed.packages()[,'Package'], sep=', ')" 2>/dev/null)
GO_TOOLS=$(ls ~/go/bin 2>/dev/null | tr '\n' ', ')

# 組合成清單（跳過空的）
CLI_INVENTORY=""
[ -n "$BREW_LIST" ] && CLI_INVENTORY="${CLI_INVENTORY}\n- Homebrew: $BREW_LIST"
[ -n "$APT_LIST" ] && CLI_INVENTORY="${CLI_INVENTORY}\n- apt: $APT_LIST"
[ -n "$NPM_GLOBAL" ] && CLI_INVENTORY="${CLI_INVENTORY}\n- npm global: $NPM_GLOBAL"
[ -n "$PIP_LIST" ] && CLI_INVENTORY="${CLI_INVENTORY}\n- pip: $PIP_LIST"
[ -n "$CARGO_LIST" ] && CLI_INVENTORY="${CLI_INVENTORY}\n- cargo: $CARGO_LIST"
[ -n "$BIN_TOOLS" ] && CLI_INVENTORY="${CLI_INVENTORY}\n- bin paths: $BIN_TOOLS"
[ -n "$R_PKGS" ] && CLI_INVENTORY="${CLI_INVENTORY}\n- R packages: $R_PKGS"
[ -n "$GO_TOOLS" ] && CLI_INVENTORY="${CLI_INVENTORY}\n- Go tools: $GO_TOOLS"
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

本機已安裝的 CLI 工具（自動偵測，只顯示有安裝的 package manager）：
$CLI_INVENTORY

輸出格式（markdown 表格）：
| 工具名稱 | 類型 | 用途 |
|----------|------|------|

類型用：MCP / Skill / Command / Agent / Hook / LSP / CLI
對於 Hooks，說明什麼操作會觸發它、觸發後會發生什麼。
對於 CLI，只列跟任務相關的，不用全部列出。" --output-format text --max-turns 1
```

### Step 3: 輸出

直接把 `claude -p` 的回傳顯示給使用者。
