---
name: plugin-deploy
description: |
  發布 plugin 到 Anthropic 官方 marketplace。引導準備提交所需的檔案和資訊，
  然後開啟提交頁面。
  當用戶提到「發布 plugin」「submit plugin」「上架 plugin」「deploy plugin」
  「提交到官方」時使用。
argument-hint: "[plugin-name]"
allowed-tools:
  - Read
  - Glob
  - Grep
  - Bash(open:*)
  - Bash(ls:*)
  - Bash(cat:*)
  - AskUserQuestion
---

# Plugin Deploy — 發布到官方 Marketplace

引導你準備並提交 plugin 到 Anthropic 官方 marketplace。

## 提交入口

| 平台 | URL |
|------|-----|
| Claude.ai | https://claude.ai/settings/plugins/submit |
| Console | https://platform.claude.com/plugins/submit |

任何人都可以提交，但會經過 Anthropic 審核。

## Execution Steps

### Step 1: Identify Plugin

從 `$ARGUMENTS` 取得 plugin name，找到 plugin 目錄：

```bash
# 在 marketplace repo 中找
PLUGIN_DIR=$(find . -path "*/plugins/$PLUGIN_NAME/.claude-plugin/plugin.json" -exec dirname {} \; | head -1 | sed 's|/.claude-plugin||')
```

如果找不到，問使用者。

### Step 2: Pre-flight Checklist

檢查 plugin 是否準備好提交：

| 項目 | 檢查方式 | 必要？ |
|------|---------|--------|
| plugin.json 存在 | 讀取 `.claude-plugin/plugin.json` | 必要 |
| name 是 kebab-case | 正則檢查 | 必要 |
| description 有填 | 長度 > 0 | 必要 |
| version 有填 | semver 格式 | 必要 |
| 至少一個 skill 或 command | 掃描 `skills/` 和 `commands/` | 必要 |
| README.md 存在 | 檔案存在 | 建議 |
| CLAUDE.md 存在 | 檔案存在 | 建議 |
| LICENSE 存在 | 檔案存在 | 建議 |
| 無硬編碼路徑 | grep 絕對路徑 | 建議 |
| 用 ${CLAUDE_PLUGIN_ROOT} | grep hooks/MCP 中的路徑 | 如有 hooks/MCP |

### Step 3: Present Checklist

```markdown
## Plugin Deploy Pre-flight: {plugin-name}

### 必要項目
- [x] plugin.json ✅
- [x] name: {name} ✅
- [x] description ✅
- [x] version: {version} ✅
- [x] skills: {count} 個 ✅

### 建議項目
- [x] README.md ✅
- [ ] LICENSE ❌ — 建議加上（MIT 最簡單）
- [x] CLAUDE.md ✅

### 問題
- ❌ LICENSE 缺失：建議在 plugin 根目錄加上 LICENSE 檔案

要修正問題後繼續，還是直接提交？
```

### Step 4: Fix Issues (Optional)

如果有問題，幫使用者修正：
- 缺 README.md → 從 CLAUDE.md 和 skills 自動產生
- 缺 LICENSE → 建立 MIT LICENSE
- 硬編碼路徑 → 替換成 `${CLAUDE_PLUGIN_ROOT}`

### Step 5: Prepare Submission Info

整理提交需要的資訊：

```markdown
## 提交資訊

| 欄位 | 值 |
|------|-----|
| Plugin Name | {name} |
| Description | {description} |
| Version | {version} |
| Author | {author} |
| Repository | {repo URL} |
| Skills | {list} |
| Commands | {list} |
| Category | {category} |
```

### Step 6: Open Submission Page

```bash
open "https://claude.ai/settings/plugins/submit"
```

提示使用者：
```
提交頁面已開啟。請用上面的資訊填寫表單。
提交後 Anthropic 會進行審核，通過後你的 plugin 就會出現在官方 marketplace。

注意：審核時間不確定，建議同時維護自己的 marketplace（PsychQuant）作為主要發布管道。
```

## Notes

- 官方 marketplace 有審核流程，時間不確定
- 自己的 marketplace（如 PsychQuant）不需要審核，push 即生效
- 兩者可以並行：自己的 marketplace 是主要管道，官方是額外曝光
- 提交後如果被拒，可以根據回饋修改後重新提交
