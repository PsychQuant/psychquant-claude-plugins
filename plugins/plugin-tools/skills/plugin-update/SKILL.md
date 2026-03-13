---
name: plugin-update
description: 更新 Plugin 到最新版本（marketplace.json 同步 + marketplace update + plugin update + 安裝檢查）。當修改了任何 plugin 原始碼後需要同步、或用戶提到「更新 plugin」、「同步 plugin」、「plugin 沒生效」、「reload plugins」時使用。
argument-hint: [plugin-name]
allowed-tools:
  - Bash(git:*)
  - Bash(claude:*)
  - Bash(ls:*)
  - Bash(cat:*)
  - Bash(python3:*)
  - Read
  - Edit
  - Grep
  - Glob
  - AskUserQuestion
---

# Plugin Update — 同步與更新流程

修改 plugin 原始碼後，確保變更生效的完整流程。

## 為什麼需要這個？

Plugin 修改後有 5 個環節容易漏掉：
1. 忘了更新 `marketplace.json` 中的版本號（新 plugin 忘了加 entry）
2. 忘了 commit/push 到 git remote
3. 忘了同步 marketplace cache（`claude plugin marketplace update`）
4. 忘了 update 已安裝的 plugin（`claude plugin update`）
5. 忘了重啟 Claude Code 使快取生效

此 skill 自動檢查並執行所有步驟。

---

## Phase 0: 偵測 Marketplace

先確定 plugin 所在的 marketplace repo。

### 已知的 marketplace

| Marketplace | 路徑 | 類型 |
|-------------|------|------|
| `psychquant-claude-plugins` | `/Users/che/Developer/psychquant-claude-plugins` | Git (GitHub) |
| `che-local-plugins` | `/Users/che/Library/CloudStorage/Dropbox/che_workspace/projects/che-claude-config/che-local-plugins` | 本地目錄 |

根據用戶指定的 plugin 名稱，從上面的 marketplace 中找到對應的 repo 路徑。

```bash
# 列出所有 marketplace
claude plugin marketplace list 2>&1
```

---

## Phase 1: 偵測變更

### Step 1: 確定 Plugin

如果用戶指定了 plugin 名稱，直接使用。否則從 git 推斷：

```bash
cd {marketplace_repo_path}
git diff --name-only HEAD~3 | grep '^plugins/' | cut -d/ -f2 | sort -u
```

列出最近變更的 plugin，請用戶確認要更新哪些。

### Step 2: 檢查 Git 狀態

```bash
cd {marketplace_repo_path}
git status --short -- plugins/{plugin_name}/
```

- 如果有未提交變更 → 提醒用戶先 commit + push
- 如果已 commit 但未 push → 提醒 `git push`
- 如果已 push → 繼續下一步

```bash
git log origin/main..HEAD --oneline
```

---

## Phase 2: 更新 marketplace.json（關鍵！）

`marketplace.json` 位於 `{marketplace_repo_path}/.claude-plugin/marketplace.json`，是 marketplace 的 plugin index。
**如果這個檔案沒更新，`claude plugin marketplace update` 不會看到新版本。**

### Step 1: 列出 marketplace 中所有 plugin 版本

```bash
cd {marketplace_repo_path}
cat .claude-plugin/marketplace.json | python3 -c "
import json, sys
data = json.load(sys.stdin)
for p in data['plugins']:
    print(f\"  {p['name']}: {p['version']}\")
"
```

### Step 2: 對比 plugin.json 的實際版本

```bash
cat plugins/{plugin_name}/.claude-plugin/plugin.json | python3 -c "
import json, sys
d = json.load(sys.stdin)
print(f\"plugin.json: {d['version']}\")
"
```

如果 marketplace.json 的版本落後 plugin.json，用 Edit 工具更新 marketplace.json。

### Step 3: 新 Plugin 需加入 entry

如果是全新的 plugin（不在 marketplace.json 中），需要在 `plugins` 陣列加入新 entry：

```json
{
  "name": "{plugin_name}",
  "version": "1.0.0",
  "description": "{description}",
  "author": { "name": "Che Cheng" },
  "source": "./plugins/{plugin_name}",
  "category": "{category}"
}
```

category 常用值：`development`、`productivity`、`creative`

### Step 4: Commit + Push marketplace.json

marketplace.json 的變更也需要 commit + push，才能被 `marketplace update` 抓到。

```bash
cd {marketplace_repo_path}
git add .claude-plugin/marketplace.json
git commit -m "chore: update marketplace.json for {plugin_name} v{version}"
git push
```

---

## Phase 3: 同步 Marketplace Cache

### Step 1: 更新 marketplace cache

```bash
claude plugin marketplace update {marketplace_name}
```

這會從 source（git remote 或本地目錄）重新拉取 plugin index。

### Step 2: 驗證

```bash
claude plugin list 2>&1 | grep -A3 "{plugin_name}"
```

---

## Phase 4: 更新已安裝的 Plugin

### 注意：必須加 `@marketplace_name` 後綴

```bash
# 已安裝 → 更新
claude plugin update {plugin_name}@{marketplace_name}

# 未安裝 → 安裝
claude plugin install {plugin_name}@{marketplace_name}
```

先檢查是否已安裝：
```bash
claude plugin list 2>&1 | grep "{plugin_name}"
```

---

## Phase 5: 驗證與提醒

### Step 1: 確認最終狀態

```bash
claude plugin list 2>&1 | grep -A5 "{plugin_name}"
```

檢查：
- Version 是否已更新到目標版本
- Status 是否 `✔ enabled`
- 是否有 `failed to load` 錯誤

### Step 2: 提醒重啟

> 更新完成。請重啟 Claude Code（退出再重新開啟）讓變更完全生效。
> 或者在下次啟動新對話時，新版 plugin 就會自動載入。

---

## 批次更新

多個 plugin 需要更新時：

```bash
# 1. 同步 marketplace（只需一次）
claude plugin marketplace update {marketplace_name}

# 2. 逐一更新（需加 @marketplace 後綴）
claude plugin update plugin-a@{marketplace_name}
claude plugin update plugin-b@{marketplace_name}
```

---

## 常見問題

### Plugin 更新後 skill 沒變？
Claude Code 有快取機制。需要重啟才能載入新版 skill 內容。

### `failed to load` 錯誤？
通常是 hooks.json 格式問題：
```bash
claude plugin validate {marketplace_repo_path}/plugins/{plugin_name}
```

### `marketplace update` 沒看到新版本？
1. 確認 `marketplace.json` 的版本號已更新
2. 確認已 push 到 remote：
```bash
cd {marketplace_repo_path}
git log origin/main..HEAD --oneline
```

### `plugin update` 找不到 plugin？
需要加 `@marketplace_name` 後綴：
```bash
# 錯誤
claude plugin update my-plugin
# 正確
claude plugin update my-plugin@psychquant-claude-plugins
```
