---
name: plugin-deploy
description: |
  發布 plugin 到自己的 marketplace（pre-flight check + version bump + commit + push + sync）。
  完整的發布流程，確保 plugin 品質和 marketplace 同步。
  當用戶提到「發布 plugin」「deploy plugin」「上架」「release plugin」時使用。
argument-hint: "[plugin-name]"
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash(git:*)
  - Bash(gh:*)
  - Bash(ls:*)
  - Bash(cat:*)
  - Bash(claude:*)
  - AskUserQuestion
---

# Plugin Deploy — 發布到自己的 Marketplace

完整的 plugin 發布流程：品質檢查 → 版本號 → marketplace 同步 → commit → push → reload。

## Execution Steps

### Step 1: Identify Plugin

從 `$ARGUMENTS` 取得 plugin name，找到 plugin 目錄：

```bash
MARKETPLACE_ROOT="找到 marketplace repo 根目錄"
PLUGIN_DIR="$MARKETPLACE_ROOT/plugins/$PLUGIN_NAME"
```

如果找不到，問使用者。

### Step 2: Pre-flight Checklist

檢查 plugin 是否準備好發布：

| 項目 | 檢查方式 | 必要？ |
|------|---------|--------|
| plugin.json 存在 | 讀取 `.claude-plugin/plugin.json` | 必要 |
| name 是 kebab-case | 正則檢查 | 必要 |
| description 有填 | 長度 > 0 | 必要 |
| version 有填 | semver 格式 | 必要 |
| 至少一個 skill 或 command | 掃描 `skills/` 和 `commands/` | 必要 |
| 每個 SKILL.md 有 description | 讀取 frontmatter | 必要 |
| README.md 存在 | 檔案存在 | 建議 |
| CLAUDE.md 存在 | 檔案存在 | 建議 |
| 無硬編碼絕對路徑 | grep `/Users/` 等 | 建議 |
| hooks 用 ${CLAUDE_PLUGIN_ROOT} | grep hooks 中的路徑 | 如有 hooks |

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
- [ ] LICENSE ❌
- [x] CLAUDE.md ✅

### 問題
{列出需要修正的項目}

要修正問題後繼續，還是直接發布？
```

### Step 4: Fix Issues (Optional)

如果有問題，幫使用者修正：
- 缺 README.md → 從 CLAUDE.md 和 skills 自動產生
- 缺 LICENSE → 建立 MIT LICENSE
- 硬編碼路徑 → 提示修正

### Step 5: Version Bump

問使用者版本號要怎麼升：

```
目前版本：{current_version}

1. Patch（{x.y.z+1}）— bug fix、小修正
2. Minor（{x.y+1.0}）— 新功能、新 skill
3. Major（{x+1.0.0}）— 破壞性變更
4. 自訂版本號
```

更新兩個地方的版本號：
1. `plugins/{name}/.claude-plugin/plugin.json` 的 `version`
2. `.claude-plugin/marketplace.json` 中對應 plugin 的 `version`

### Step 6: Update marketplace.json

確認 marketplace.json 中的 plugin entry 資訊是最新的：
- version 已更新
- description 與 plugin.json 一致
- 如果是新 plugin，確認 entry 已存在

### Step 7: Commit & Push

```bash
cd "$MARKETPLACE_ROOT"
git add "plugins/{plugin-name}" ".claude-plugin/marketplace.json"
git commit -m "release: {plugin-name} v{new_version} — {簡述變更}"
git push origin main
```

### Step 8: Sync & Reload

```bash
# 同步 marketplace cache
claude plugin marketplace update {marketplace-name}

# 更新已安裝的 plugin
claude plugin update {plugin-name}
```

### Step 9: Verify

```bash
# 確認版本正確
claude plugin list | grep {plugin-name}
```

提示使用者：
```
{plugin-name} v{new_version} 已發布！

- marketplace.json ✅ 已更新
- git push ✅ 已推送
- plugin cache ✅ 已同步
- 安裝版本 ✅ 已更新

其他使用者可透過以下指令安裝/更新：
  /plugin marketplace update {marketplace-name}
  /plugin install {plugin-name}@{marketplace-name}
```

## Notes

- 這個 skill 發布到**自己的 marketplace**（如 PsychQuant），push 即生效，不需要審核
- 如果未來要提交到 Anthropic 官方 marketplace，目前只接受企業級合作夥伴
- 發布前建議先用 `claude --plugin-dir` 本地測試
