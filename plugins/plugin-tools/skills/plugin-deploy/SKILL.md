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

### Step 0: Bootstrap Stage Task List（強制）

**動任何事之前**先用 `TaskCreate` 建 stage-level todo list：

```
TaskCreate(name="identify_plugin", description="Step 1: 從 $ARGUMENTS 找 plugin 目錄")
TaskCreate(name="preflight_checks", description="Step 2: 跑必要 + 建議項目檢查")
TaskCreate(name="mcp_binary_check", description="Step 2.5: 若是 MCP plugin，驗證 binary 在 GitHub Release 裡（不在則 BLOCK）")
TaskCreate(name="present_checklist", description="Step 3: 顯示結果，讓使用者決定繼續或修問題")
TaskCreate(name="fix_issues", description="Step 4: 若使用者選修問題，處理 README/LICENSE/hooks 等")
TaskCreate(name="version_bump", description="Step 5: patch/minor/major bump plugin.json + marketplace.json")
TaskCreate(name="update_marketplace_json", description="Step 6: 同步 marketplace.json 確認 version / description")
TaskCreate(name="commit_and_push", description="Step 7: git add + commit + push")
TaskCreate(name="sync_and_reload", description="Step 8: claude plugin marketplace update + plugin update")
TaskCreate(name="verify", description="Step 9: claude plugin list 驗證版本")
```

完成每一步立即 `TaskUpdate → completed`。**靜默完成 = 違規**。

**為什麼強制**：plugin-deploy 有 9 個步驟，MCP plugin 還要加 Step 2.5 blocker check。沒 task list 容易漏 Step 2.5（會導致新使用者裝了 plugin 但 wrapper 下載不到 binary）。

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
| **MCP binary 已發布到 release** | 見 Step 2.5 | **MCP plugin 必要** |

### Step 2.5: MCP Binary Check（MCP plugin 必跑）

如果 plugin 包含 MCP server wrapper（透過 `.mcp.json` + `bin/*-wrapper.sh`），**必須**驗證 wrapper 所引用的 binary 已發布到 GitHub Release，否則使用者裝新版 plugin 也拿不到對應的 binary。

**歷史脈絡**：plugin version bump 只更新 wrapper + marketplace.json，不會自動 trigger MCP binary 的 rebuild + release。若此步沒做好，使用者端會出現「plugin 顯示 vX.Y.Z，但跑的是舊 binary」的詭異狀態。

```bash
# 1. 偵測是否為 MCP plugin
MCP_JSON="$PLUGIN_DIR/.mcp.json"
if [ ! -f "$MCP_JSON" ]; then
    echo "Not an MCP plugin — skip Step 2.5"
    IS_MCP_PLUGIN=false
else
    IS_MCP_PLUGIN=true
fi

# 2. 若是 MCP plugin，掃 bin/ 下的 wrapper 抓 BINARY_NAME + GITHUB_REPO
if [ "$IS_MCP_PLUGIN" = "true" ]; then
    MCP_STALE=false
    for wrapper in "$PLUGIN_DIR/bin/"*wrapper.sh; do
        [ -f "$wrapper" ] || continue
        BINARY_NAME=$(grep '^BINARY_NAME=' "$wrapper" | head -1 | cut -d'"' -f2)
        GITHUB_REPO=$(grep '^GITHUB_REPO=' "$wrapper" | head -1 | cut -d'"' -f2)
        [ -z "$BINARY_NAME" ] && continue
        [ -z "$GITHUB_REPO" ] && continue

        # 3. 查詢該 repo 的 latest release 是否含對應 binary asset
        HAS_BINARY=$(curl -sL "https://api.github.com/repos/$GITHUB_REPO/releases/latest" \
            | grep '"browser_download_url"' | grep -c "/$BINARY_NAME\"" || true)

        if [ "$HAS_BINARY" = "0" ]; then
            echo "❌ BLOCKER: $BINARY_NAME not found in latest release of $GITHUB_REPO"
            echo "   Wrapper will fail to auto-download. Run mcp-deploy first:"
            echo "   cd <MCP-source-repo> && /mcp-tools:mcp-deploy"
            MCP_STALE=true
        else
            echo "✅ $BINARY_NAME present in $GITHUB_REPO latest release"
        fi
    done

    # 4. 如果有任何 binary 不在 release → BLOCK deploy
    if [ "$MCP_STALE" = "true" ]; then
        echo ""
        echo "Plugin deploy blocked — MCP binary release is out of sync."
        echo "Fix: run /mcp-tools:mcp-deploy from the MCP source repo first."
        exit 1
    fi
fi
```

**用 AskUserQuestion 再確認 binary 是否為當前 source code 版本**：

```
question: "Release 有 $BINARY_NAME，但可能是舊版。source code 從那次 release 後有改動嗎？"
options:
  - "沒改動，release 是最新"
  - "有改動但先 deploy plugin，之後再發 binary"
  - "有改動，我先去跑 /mcp-tools:mcp-deploy 更新 binary"
```

**為什麼是 BLOCKER 而非 warning**：
| 狀況 | 後果 |
|------|------|
| Release 沒 binary | 使用者裝新版 plugin → wrapper auto-download 失敗 → 整個 plugin 無法使用 |
| Release 有 binary 但過時 | 使用者裝新版 plugin → 跑舊 binary → 新功能宣告了但跑不出來 |

第一種是 hard failure（使用者完全 blocked），必須 block；第二種是 silent failure（使用者困惑但能跑），可以 warn。

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

## MCP plugin 的依賴

若此 plugin 含 `.mcp.json` + `bin/*-wrapper.sh`，屬於 **binary-based MCP plugin**：

- Wrapper 執行時會自動從 GitHub Release 下載 binary
- Plugin version bump **不等於** binary 會自動更新
- 必須先在 MCP source repo 跑 `/mcp-tools:mcp-deploy` 發 binary release，才能跑 `plugin-deploy`

詳見 [rules/mcp-binary-distribution.md](../../rules/mcp-binary-distribution.md) 的「plugin-deploy ↔ mcp-deploy 依賴關係」。Step 2.5 會自動偵測並 block 不同步的情況。
