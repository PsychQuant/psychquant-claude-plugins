---
name: which-better
description: |
  找出最適合任務的工具，不限於已安裝的。先掃本機，再上網搜尋更好的替代方案，
  比較優劣，並提供安裝指令。
  當用戶說「有沒有更好的工具」「best tool for」「推薦工具」「有什麼替代方案」時觸發。
argument-hint: "[task description]"
allowed-tools:
  - Bash(claude:*)
---

# Which Better — 全面工具探索

不只看已安裝的，還上網搜尋有沒有更好的選擇。

## vs which

| | which | which-better |
|--|-------|-------------|
| 範圍 | 只看已安裝的 | 已安裝 + 網路搜尋 |
| 速度 | 快（1 次 claude -p） | 較慢（需要 web search） |
| 用途 | 「我有什麼可以用」 | 「什麼是最好的選擇」 |

## Execution

### Step 1: 掃描本機

跟 `which` 一樣，先掃 PATH 和 R packages：

```bash
ALL_CMDS=$(ls /usr/bin /usr/local/bin /opt/homebrew/bin ~/bin ~/.local/bin ~/go/bin ~/.cargo/bin 2>/dev/null | sort -u | tr '\n' ', ')
R_PKGS=$(Rscript -e "cat(installed.packages()[,'Package'], sep=', ')" 2>/dev/null)
```

### Step 2: 呼叫 claude -p（有 WebSearch + WebFetch 能力）

```bash
claude -p "任務：$ARGUMENTS

你的工作分三步：

## 第一步：盤點已有的

掃描所有可用工具（MCP tools、Skills、Commands、Agents、Hooks、LSP、CLI），
列出已經可以用來完成這個任務的工具。

本機 PATH 中所有可用指令：
$ALL_CMDS

R packages：$R_PKGS

## 第二步：上網搜尋更好的替代方案

從以下來源搜尋更好的工具：

A. Curated lists（用 WebFetch 直接讀）：
- MCP servers: https://api.anthropic.com/mcp-registry/v0/servers?limit=100
- awesome-mcp-servers: https://github.com/punkpeye/awesome-mcp-servers
- Claude plugins: https://github.com/anthropics/claude-plugins-official
- awesome-cli-apps: https://github.com/agarrharr/awesome-cli-apps

B. WebSearch（補充搜尋）：
- '{task} best tool 2025/2026'
- '{task} alternative to {已找到的工具名}'
- 'awesome {相關領域} github'
- 'mcp server {task}'
- 'claude code plugin {task}'

搜尋目標：
- 有沒有更快、更強、更新的替代品
- 有沒有專門為這個任務設計的工具（而非通用工具）
- 有沒有現成的 MCP server 可以 claude mcp add
- 有沒有 Claude Code plugin 可以 /plugin install

## 第三步：比較並推薦

輸出格式：

### 已安裝的工具
| 工具 | 類型 | 用途 |
|------|------|------|

### 建議安裝的更好替代方案
| 工具 | 為什麼更好 | 安裝指令 |
|------|-----------|---------|

對每個建議的工具說明：
1. 比現有工具好在哪裡（速度？功能？維護活躍度？）
2. 安裝指令（brew install / npm install -g / pip install / cargo install）
3. 如果是 MCP server：claude mcp add 指令
4. 如果是 Claude Code plugin：/plugin install 指令

### 結論
一句話推薦：做這件事最好的工具組合是什麼。
" --output-format text --max-turns 10
```

### Step 3: 輸出

直接把 `claude -p` 的回傳顯示給使用者。

如果使用者想安裝某個推薦的工具，直接執行安裝指令。
