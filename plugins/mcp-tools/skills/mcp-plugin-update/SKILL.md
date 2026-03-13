---
name: mcp-plugin-update
description: 更新 Plugin 到最新版本（marketplace 同步 + plugin update + 安裝檢查）。當修改了 plugin 原始碼後需要同步、或用戶提到「更新 plugin」、「同步 plugin」、「plugin 沒生效」時使用。
argument-hint: [plugin-name]
allowed-tools:
  - Bash(git:*)
  - Bash(claude:*)
  - Bash(ls:*)
  - Read
  - Grep
  - Glob
  - AskUserQuestion
---

# Plugin Update — 同步與更新流程

修改 plugin 原始碼後，確保變更生效的完整流程。

## 為什麼需要這個？

Plugin 修改後有 4 個環節容易漏掉：
1. 忘了 commit/push 到 git remote
2. 忘了同步 marketplace index
3. 忘了 update 已安裝的 plugin
4. 忘了重啟 Claude Code 使快取生效

此 skill 自動檢查並執行所有步驟。

---

## Phase 1: 偵測變更

### Step 1: 確定 Plugin

如果用戶指定了 plugin 名稱，直接使用。否則：

```bash
# 從最近 git 變更推斷
cd /Users/che/Developer/psychquant-claude-plugins
git diff --name-only HEAD~3 | grep '^plugins/' | cut -d/ -f2 | sort -u
```

列出最近變更的 plugin，請用戶確認要更新哪些。

### Step 2: 檢查 Git 狀態

```bash
cd /Users/che/Developer/psychquant-claude-plugins
git status --short -- plugins/{plugin_name}/
```

- 如果有未提交變更 → 提醒用戶先 commit + push
- 如果已 commit 但未 push → 提醒 `git push`
- 如果已 push → 繼續下一步

```bash
# 檢查是否需要 push
git log origin/main..HEAD --oneline
```

---

## Phase 2: 同步 Marketplace

### Step 1: 更新 marketplace index

```bash
claude plugin marketplace update psychquant-claude-plugins
```

這會從 git remote 拉最新的 plugin manifest。

如果 plugin 來自其他 marketplace（如 `che-local-plugins`），改用：
```bash
claude plugin marketplace update {marketplace_name}
```

### Step 2: 驗證版本

```bash
# 確認 marketplace 已看到新版本
claude plugin list 2>&1 | grep -A3 "{plugin_name}"
```

---

## Phase 3: 更新已安裝的 Plugin

### Step 1: 更新 plugin

```bash
claude plugin update {plugin_name}
```

如果 plugin 尚未安裝：
```bash
claude plugin install {plugin_name}
```

### Step 2: 安裝新 Plugin（如果是新建的）

檢查 plugin 是否已在安裝清單中：
```bash
claude plugin list 2>&1 | grep "{plugin_name}"
```

如果不在，安裝它：
```bash
claude plugin install {plugin_name}@{marketplace_name}
```

---

## Phase 4: 驗證與提醒

### Step 1: 確認狀態

```bash
claude plugin list 2>&1 | grep -A5 "{plugin_name}"
```

檢查：
- Version 是否已更新
- Status 是否 `✔ enabled`
- 是否有載入錯誤

### Step 2: 提醒重啟

告訴用戶：

> 更新完成。請重啟 Claude Code（退出再重新開啟）讓變更完全生效。
> 或者在下次啟動新對話時，新版 plugin 就會自動載入。

---

## 批次更新

如果多個 plugin 需要更新，一次完成：

```bash
# 同步 marketplace（只需一次）
claude plugin marketplace update psychquant-claude-plugins

# 逐一更新
claude plugin update plugin-a
claude plugin update plugin-b
claude plugin update plugin-c
```

---

## 常見問題

### Plugin 更新後 skill 沒變？
Claude Code 有快取機制。需要重啟才能載入新版 skill 內容。

### `failed to load` 錯誤？
通常是 hooks.json 格式問題。檢查 hooks.json 是否符合最新 schema：
```bash
claude plugin validate /path/to/plugin
```

### marketplace update 沒看到新版本？
確認已 push 到 remote：
```bash
cd /Users/che/Developer/psychquant-claude-plugins
git log origin/main..HEAD --oneline
```
如果有未推送的 commit，先 `git push`。
