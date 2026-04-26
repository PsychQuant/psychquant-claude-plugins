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

Plugin 修改後有 6 個環節容易漏掉：
1. 忘了更新 `marketplace.json` 中的版本號（新 plugin 忘了加 entry）
2. 忘了 commit/push 到 git remote
3. 忘了同步 marketplace cache（`claude plugin marketplace update`）
4. 忘了 update 已安裝的 plugin（`claude plugin update`）
5. 忘了重啟 Claude Code 使快取生效
6. **忘了同步 `README.md`**（版本 bump 但 README 仍在舊版、沒提新工具 / 新 skill，使用者看文件以為功能沒做完）

此 skill 自動檢查並執行所有步驟。

---

## Step 0: Bootstrap Stage Task List（強制）

**動任何事之前**先用 `TaskCreate` 建 stage-level todo list，每完成一步立即 `TaskUpdate → completed`。**靜默完成 = 違規**。

```
TaskCreate(name="detect_marketplace", description="Phase 0: 找到 plugin 所屬的 marketplace repo")
TaskCreate(name="detect_changes", description="Phase 1: 確認 plugin + git status + 最近 commits")
TaskCreate(name="check_external_deps", description="Phase 1.5: 偵測 MCP/CLI 依賴，不同步時 AskUserQuestion")
TaskCreate(name="sync_marketplace_json", description="Phase 2: 比對 plugin.json 和 marketplace.json 版本，commit+push")
TaskCreate(name="check_readme_freshness", description="Phase 2.5: 檢查 README 是否跟上版本 / 新工具，過時時 AskUserQuestion")
TaskCreate(name="marketplace_update", description="Phase 3: claude plugin marketplace update")
TaskCreate(name="plugin_install_or_update", description="Phase 4: claude plugin install/update @marketplace")
TaskCreate(name="verify_and_report", description="Phase 5: claude plugin list 驗證 + 提醒重啟")
```

**若 Phase 1.5 使用者選「順便更新」**，補加一筆：
```
TaskCreate(name="invoke_dependency_skill", description="Phase 1.5 auto-sync: 呼叫 /mcp-tools:mcp-deploy 或 /cli-tools:cli-upgrade")
```

**為什麼強制**：plugin-update 有 5 個常被漏掉的環節（marketplace.json 沒更新、沒 push、cache 沒 sync、plugin 沒 update、沒重啟），task list 讓每一步都有可見證據。

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

## Phase 1.5: External Binary Dependency Check（若有）

Plugin 如果依賴外部 binary（MCP server、CLI 工具），plugin-update 只會同步 shell
（wrapper / skill / command），**不會** 自動更新 binary。這個 phase 偵測並提示。

### Step 1: 偵測依賴類型

| 訊號 | 類型 | 判斷方式 |
|------|------|---------|
| `.mcp.json` 存在 | **MCP binary** | `ls plugins/{name}/.mcp.json` |
| `bin/*-wrapper.sh` 有 `GITHUB_REPO` | **MCP binary** | `grep -l GITHUB_REPO plugins/{name}/bin/*.sh` |
| `hooks/session-start.sh` curl GitHub API | **CLI tool** | `grep 'api.github.com.*releases' plugins/{name}/hooks/` |
| Skill / hook 引用 `~/bin/$BINARY` | **CLI tool** | `grep -rn '\$HOME/bin/\|~/bin/' plugins/{name}/{skills,hooks}/` |

### Step 2: MCP 情境 — 查 latest release 有沒有對應 asset

```bash
for wrapper in plugins/{name}/bin/*-wrapper.sh; do
    [ -f "$wrapper" ] || continue
    BINARY_NAME=$(grep '^BINARY_NAME=' "$wrapper" | head -1 | cut -d'"' -f2)
    GITHUB_REPO=$(grep '^GITHUB_REPO=' "$wrapper" | head -1 | cut -d'"' -f2)
    [ -z "$BINARY_NAME" ] && continue

    HAS_BINARY=$(curl -sL "https://api.github.com/repos/$GITHUB_REPO/releases/latest" \
        | grep '"browser_download_url"' | grep -c "/$BINARY_NAME\"" || true)

    if [ "$HAS_BINARY" = "0" ]; then
        echo "⚠️  $BINARY_NAME not in $GITHUB_REPO latest release"
        echo "   Plugin will install but wrapper auto-download will fail."
        echo "   → cd <MCP-source-repo> && /mcp-tools:mcp-deploy"
    fi
done
```

### Step 3: CLI 情境 — 比對本機 binary 和 latest release 版本

```bash
# 從 session-start.sh 抓 GitHub repo
GFH_REPO=$(grep -oE '[A-Za-z0-9_-]+/[A-Za-z0-9_-]+' plugins/{name}/hooks/session-start.sh | head -1)
BINARY_NAME=$(basename $(grep -oE '\$HOME/bin/[A-Za-z0-9_-]+' plugins/{name}/hooks/session-start.sh | head -1))

LOCAL_VERSION=$("$HOME/bin/$BINARY_NAME" version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
LATEST_VERSION=$(curl -sL "https://api.github.com/repos/$GFH_REPO/releases/latest" \
    | grep '"tag_name"' | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')

if [ "$LOCAL_VERSION" != "$LATEST_VERSION" ]; then
    echo "⚠️  $BINARY_NAME local v$LOCAL_VERSION, latest v$LATEST_VERSION"
    echo "   → /cli-tools:cli-upgrade $BINARY_NAME"
fi
```

### Step 4: 行為決策 — AskUserQuestion 主動同步

偵測到依賴且不同步時，**主動問使用者要不要一起更新**，不只是 warn。
plugin-update 是日常同步操作——連帶更新底層 binary 通常是想要的行為。

**AskUserQuestion 格式**：

```
question: "此 plugin 依賴 $BINARY（$BINARY_TYPE），目前本機/release 不同步。要順便更新 binary 嗎？"
options:
  - "順便更新" — 自動觸發底層 skill（MCP → mcp-deploy / CLI → cli-upgrade）
  - "只更新 plugin shell" — 略過 binary，只跑 marketplace.json sync + reload
  - "中止" — 停止 plugin-update，讓我手動處理
```

**若使用者選「順便更新」**：

| 依賴類型 | 自動觸發 | 時機 |
|---------|---------|------|
| MCP binary | `/mcp-tools:mcp-deploy` | 在此 phase 內執行，完成後才繼續 Phase 2 |
| CLI tool | `/cli-tools:cli-upgrade $BINARY` | 同上 |

**狀況表**：

| 狀況 | 動作 |
|------|------|
| 無依賴（純 skill / rule plugin） | 跳過此 phase |
| 有依賴且已同步 | 顯示 ✅，繼續 Phase 2 |
| 有依賴但不同步 | **AskUserQuestion**：要順便更新 binary 嗎？ |

**為什麼 plugin-update 是 prompt-then-sync 而 plugin-deploy 是 block**：

| Skill | 觸發頻率 | 行為 | 理由 |
|-------|---------|------|------|
| `plugin-deploy` Step 2.5 | 偶爾（發版時）| **BLOCK** | Release 沒 binary = 新使用者裝 plugin 就壞，不能放過 |
| `plugin-update` Phase 1.5 | 頻繁（日常同步）| **ASK + AUTO-SYNC** | 開發者通常想要一次更新完，但要尊重「只改 shell 不動 binary」的情境 |

### Step 5: 執行 auto-sync（若使用者選擇）

**MCP 情境**：

```bash
# 找到 MCP source repo（通常在 ~/Developer/ 下）
MCP_SOURCE=$(find ~/Developer -maxdepth 3 -name "Package.swift" -exec grep -l "$BINARY_NAME" {} \; | head -1 | xargs dirname 2>/dev/null)

if [ -n "$MCP_SOURCE" ]; then
    cd "$MCP_SOURCE"
    # 呼叫 mcp-deploy skill（建議用 Skill tool，不是 shell）
    echo "Invoking /mcp-tools:mcp-deploy in $MCP_SOURCE..."
    # Skill invocation: Skill(skill="mcp-tools:mcp-deploy")
else
    echo "MCP source repo not found. Please run /mcp-tools:mcp-deploy manually from the MCP repo."
fi
```

**CLI 情境**：

```bash
# cli-upgrade 已知如何找 repo（從 ~/bin/$BINARY 偵測）
# Skill invocation: Skill(skill="cli-tools:cli-upgrade", args="$BINARY_NAME")
```

完成後回到 Phase 2 繼續 marketplace.json sync。

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

## Phase 2.5: README Freshness Check

版本 bump 後，`README.md` 常常被遺忘。這個 phase 在 marketplace sync 之前做最後一道檢查：**使用者看到的文件有沒有跟上程式碼**。

### 為什麼要做這步

`plugin.json` / `marketplace.json` 的版本升了，但 README 還寫著舊工具數量、舊 feature 列表——使用者從 marketplace 裝 plugin 看到的是 stale README，會以為新功能沒做完。這不是 hard failure（plugin 還是能跑），但是 silent UX failure（使用者困惑）。

### Step 1: Staleness 偵測

掃 `plugins/{plugin_name}/README.md`，**六個訊號任一命中 = 可疑 stale**。
新增的信號 4-6 是 v1.15.0 從跨 28 plugin 大規模 audit 中萃取的盲點 —
舊三信號漏掉「tool count drift / component inventory drift / multi-version
catch-up gap」這三類常見 staleness。

```bash
PLUGIN_DIR="{marketplace_repo_path}/plugins/{plugin_name}"
README="$PLUGIN_DIR/README.md"
NEW_VERSION=$(python3 -c "import json; print(json.load(open('$PLUGIN_DIR/.claude-plugin/plugin.json'))['version'])")

# README 是否有任何版本追蹤標記（給 Suppression A 用）
HAS_VERSION_SECTION=false
if grep -qE '## (Version|Changelog)|# Changelog|v[0-9]+\.[0-9]+' "$README" 2>/dev/null; then
    HAS_VERSION_SECTION=true
fi

# 信號 1: README 沒出現新版本字串
if [ "$HAS_VERSION_SECTION" = "true" ] && ! grep -q "v$NEW_VERSION\|$NEW_VERSION" "$README" 2>/dev/null; then
    echo "⚠️  signal-1: README has version markers but doesn't mention v$NEW_VERSION"
    STALE_README=true
fi

# 信號 2: README 最後一次修改早於 plugin.json / skills / hooks 最近修改
# 套用兩個 suppression 避免誤判：
#   A. README 完全沒有版本追蹤內容 → mtime drift 沒意義（純 skill plugin / glue plugin）
#   B. 所有「比 README 新的 commits」都是 wrapper-only / marketplace.json sync 等
#      不影響使用者可見 surface 的 plumbing 改動 → 不算 stale
README_MTIME=$(git log -1 --format=%ct -- "$PLUGIN_DIR/README.md" 2>/dev/null)
CODE_MTIME=$(git log -1 --format=%ct -- "$PLUGIN_DIR/.claude-plugin/plugin.json" "$PLUGIN_DIR/skills" "$PLUGIN_DIR/hooks" "$PLUGIN_DIR/agents" "$PLUGIN_DIR/rules" "$PLUGIN_DIR/commands" 2>/dev/null)
if [ -n "$README_MTIME" ] && [ -n "$CODE_MTIME" ] && [ "$README_MTIME" -lt "$CODE_MTIME" ]; then
    if [ "$HAS_VERSION_SECTION" = "false" ]; then
        # Suppression A — 沒版本追蹤標記，mtime drift 沒意義
        :
    else
        # Suppression B — 過濾掉純 wrapper / marketplace 同步 commits
        # 找出 README mtime 之後、touch 此 plugin 的所有 commits
        SUBSTANTIVE_COMMITS=$(git log --since="@$README_MTIME" --format='%s' \
            -- "$PLUGIN_DIR/" 2>/dev/null | \
            grep -vE '^(fix|chore|docs)\(.*\): (add version-aware auto-download|sync marketplace\.json|update repo URLs|bump.*version|wrapper)' | \
            grep -vE 'wrapper.sh\b|marketplace\.json sync|plugin\.json version' | \
            head -5)
        if [ -n "$SUBSTANTIVE_COMMITS" ]; then
            echo "⚠️  signal-2: README older than substantive code changes:"
            echo "$SUBSTANTIVE_COMMITS" | sed 's/^/      /'
            STALE_README=true
        fi
    fi
fi

# 信號 3: 若有 CHANGELOG.md，檢查最新 entry 是否已出現在 README
CHANGELOG="$PLUGIN_DIR/CHANGELOG.md"
if [ -f "$CHANGELOG" ]; then
    LATEST_CL_VERSION=$(grep -oE '^## \[?[0-9]+\.[0-9]+\.[0-9]+\]?' "$CHANGELOG" | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
    if [ -n "$LATEST_CL_VERSION" ] && ! grep -q "$LATEST_CL_VERSION" "$README"; then
        echo "⚠️  signal-3: CHANGELOG latest v$LATEST_CL_VERSION not in README"
        STALE_README=true
    fi
fi

# 信號 4: Component inventory drift（v1.15.0 新增；港自 plugin-deploy）
# 實際 skills / agents / commands 是否都在 README 提到。
# 漏掉 = 使用者看 README 不知道有這個 skill。
ACTUAL_SKILLS=$(ls "$PLUGIN_DIR/skills/" 2>/dev/null | sort)
ACTUAL_AGENTS=$(find "$PLUGIN_DIR/agents/" -maxdepth 1 -name '*.md' 2>/dev/null | xargs -n1 basename -s .md 2>/dev/null | sort)
ACTUAL_COMMANDS=$(find "$PLUGIN_DIR/commands/" -maxdepth 1 -name '*.md' 2>/dev/null | xargs -n1 basename -s .md 2>/dev/null | sort)
MISSING_COMPONENTS=()
# 認可的引用格式（任一命中即視為「README 提到這個 component」）：
#   `name`              — backtick-quoted reference
#   /name               — bare slash command form
#   /plugin-name:name   — plugin-namespace form (typical in installed clients)
#   @name               — agent reference
#   - **name**          — markdown bold list entry
for s in $ACTUAL_SKILLS; do
    grep -qE "\`$s\`|/${s}\b|/[a-z0-9_-]+:${s}\b|^- \*\*$s\*\*" "$README" 2>/dev/null || MISSING_COMPONENTS+=("skill:$s")
done
for a in $ACTUAL_AGENTS; do
    grep -qE "\`$a\`|@$a\b|/[a-z0-9_-]+:${a}\b|^- \*\*$a\*\*" "$README" 2>/dev/null || MISSING_COMPONENTS+=("agent:$a")
done
for c in $ACTUAL_COMMANDS; do
    grep -qE "/${c}\b|\`/${c}\`|/[a-z0-9_-]+:${c}\b" "$README" 2>/dev/null || MISSING_COMPONENTS+=("command:$c")
done
if [ ${#MISSING_COMPONENTS[@]} -gt 0 ]; then
    echo "⚠️  signal-4: README missing ${#MISSING_COMPONENTS[@]} components: ${MISSING_COMPONENTS[*]}"
    STALE_README=true
fi

# 信號 5: Tool count drift（v1.15.0 新增）
# README 多半會在標題寫「(N tools)」「N MCP Tools」「Tool 數量: N」。
# 把這個 N 抓出來跟 plugin.json description 中宣稱的 tool 數比對。
# README 落後最容易在這露餡（che-ical-mcp v0.8.2 → v1.7.2 README 寫 20 tools 實際 28）。
DESC=$(python3 -c "import json; print(json.load(open('$PLUGIN_DIR/.claude-plugin/plugin.json')).get('description', ''))")
DESC_TOOLS=$(echo "$DESC" | grep -oE '[0-9]+ ?(?:個 )?(?:MCP )?(?:tools|工具)' | head -1 | grep -oE '^[0-9]+')
README_TOOLS=$(grep -oE 'Available Tools \([0-9]+\)|\([0-9]+ (?:MCP )?tools\)|\*\*[0-9]+ MCP Tools\*\*|[0-9]+ 個工具' "$README" 2>/dev/null | grep -oE '[0-9]+' | head -1)
if [ -n "$DESC_TOOLS" ] && [ -n "$README_TOOLS" ] && [ "$DESC_TOOLS" != "$README_TOOLS" ]; then
    echo "⚠️  signal-5: README tool count ($README_TOOLS) != plugin.json description ($DESC_TOOLS)"
    STALE_README=true
fi

# 信號 6: Version history multi-version gap（v1.15.0 新增）
# 如果 README 有 Version History 表格，掃「最近 90 天」的 git log 找出 bump commits，
# 確保表格涵蓋這段時間出貨的版本 — 不只是「latest 有沒有」（信號 1）而是「中間是否漏版本」。
# 範圍只看 90 天避免 major rewrite（plugin v1.x → v2.x README 改寫）誤觸發。
if grep -q '## Version History\|### Changelog' "$README" 2>/dev/null; then
    SHIPPED_VERSIONS=$(git log --since="90 days ago" --format='%s' -- "$PLUGIN_DIR/" 2>/dev/null | \
        grep -oE 'v?[0-9]+\.[0-9]+\.[0-9]+' | sort -uV | tail -8)
    MISSING_VERSIONS=()
    for v in $SHIPPED_VERSIONS; do
        v_clean=${v#v}
        grep -q "$v_clean\|v$v_clean" "$README" 2>/dev/null || MISSING_VERSIONS+=("$v_clean")
    done
    # 進一步限制：只計算「同 major 版本」的 missing（避免 major rewrite 誤判）
    CURRENT_MAJOR=$(echo "$NEW_VERSION" | cut -d. -f1)
    SAME_MAJOR_MISSING=()
    for v in "${MISSING_VERSIONS[@]}"; do
        v_major=$(echo "$v" | cut -d. -f1)
        [ "$v_major" = "$CURRENT_MAJOR" ] && SAME_MAJOR_MISSING+=("$v")
    done
    if [ ${#SAME_MAJOR_MISSING[@]} -gt 1 ]; then
        # 容忍漏 1 個（可能是 patch/internal），漏 2+ 個就明顯 stale
        echo "⚠️  signal-6: README Version History missing ${#SAME_MAJOR_MISSING[@]} same-major versions: ${SAME_MAJOR_MISSING[*]}"
        STALE_README=true
    fi
fi
```

**設計理由速覽**：

| 信號 | 解決的 false negative | 觀察來源 |
|------|---------------------|---------|
| 1 (legacy) | README 整個版本記錄沒同步 | 原始版本 |
| 2 (legacy + suppressions) | mtime drift；現避免誤判 wrapper-only 改動 | 大規模 audit 發現 4/11 是 false positive |
| 3 (legacy) | CHANGELOG bump 但 README 沒同步 | 原始版本 |
| 4 (new) | 新增的 skill / agent / command 沒寫進 README | issue-driven-dev：5 個 skill 列表，實際 10 個 |
| 5 (new) | README 寫的工具數比實際少 | che-ical-mcp：寫 20 工具，實際 28 |
| 6 (new) | Version History 表格漏中間 N 個版本 | che-duckdb-mcp：v2.0 → v2.2.1 中間漏 4 版 |

### Step 2: 行為決策 — AskUserQuestion

偵測到 stale 時，**不要直接繼續**。用 AskUserQuestion 讓使用者決定：

```
question: "README.md 看起來沒跟上 v$NEW_VERSION（沒提到新版本 / 新工具 / 比程式碼舊）。要怎麼處理？"
options:
  - "更新 README" — 我會讀 CHANGELOG + recent commits 幫忙起草，你審閱後 commit
  - "已經沒問題" — README 其實是對的（純內部重構、不對外新增 surface），繼續 deploy
  - "先略過，稍後手動處理" — 繼續 deploy 但留一條 warning 在最終 report
```

| 選項 | 行為 |
|------|------|
| 更新 README | Read CHANGELOG.md + `git log --oneline -n 10 -- plugins/{name}/` → 提出 README diff → 使用者確認後 Edit + commit + push |
| 已經沒問題 | 繼續 Phase 3，不記 warning |
| 先略過 | 繼續 Phase 3，**Phase 5 最終 report 要顯眼標註** README 待補 |

### 狀況表

| 狀況 | 動作 |
|------|------|
| README 不存在 | 跳過（plugin-deploy 才會強制補） |
| README 存在且 fresh（六個信號都通過）| 顯示 ✅，繼續 Phase 3 |
| README 存在但 stale | **AskUserQuestion**（三選項） |
| 只有 signal-2 命中且 Suppression A/B 啟動 | 視為 fresh（避免誤判 wrapper-only / no-version-section plugins） |

### 為什麼是 ASK 而不是 BLOCK

| Skill | 觸發頻率 | README 行為 | 理由 |
|-------|---------|-----------|------|
| `plugin-update` Phase 2.5 | 頻繁（日常同步）| **ASK** | 有時純修 typo / hook / internal refactor，不需要動 README |
| `plugin-deploy` Step 2 | 偶爾（發版時）| **列入 checklist 並 offer 修復** | 正式發布時使用者第一眼看 README，stale 就是差的第一印象 |

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
