# che-plugin-devtools — 開發工具鏈獨立 marketplace 設計

- **日期**：2026-07-30
- **狀態**：設計已定案，遷移機制與 cutover 待執行
- **來源 repo**：`psychquant-claude-plugins`（HEAD `cfb8849`）

---

## 1. 動機

把 plugin 開發工具鏈從 `psychquant-claude-plugins` 抽出，獨立成新 marketplace `che-plugin-devtools`。使用者確認的動機（五項全選）：

1. **對外可分享性** — psychquant 混了大量私人 MCP（apple-mail、telegram、zotero、things…），別人只想要「plugin 開發工具組」時無從下手
2. **共享 rules 去重** — `tool-readme-sync.md` 被複製三份
3. **降低 marketplace.json 噪音** — 32 個 entry，改一個 plugin 就要動同一個 json
4. **解 dogfooding 迴圈** — plugin-tools 管理的正是它自己所在的 marketplace
5. **讓它比較容易更新**

---

## 2. 現況盤點

### 2.1 涉及的 plugin

| Plugin | 版本 | Skills | 職責 |
|---|---|---|---|
| `plugin-tools` | 1.18.0 | 6 | plugin create/deploy/update/health/debug/upgrade |
| `mcp-tools` | 1.16.0 | 14 | MCP server 全生命週期 |
| `cli-tools` | 1.1.2 | 4 | CLI binary new-app/deploy/install/upgrade |
| `doc-tools` | 0.2.0 | 3 | CHANGELOG init/migrate/validate + doc-update Stop hook |
| `doc-guardian` | 1.0.2 | 1 | CLAUDE.md reminder + changelog check + wiki sync check |

前四個在 `psychquant-claude-plugins`；`doc-guardian` 在 `che-local-plugins`（本地目錄 marketplace）。

### 2.2 跨 plugin 依賴（實測 call graph）

```
  plugin-tools ─────→ mcp-tools      (mcp-deploy 被引用 19 次)
       ↑    │              │
       │    └──→ cli-tools │
       └───────────────────┘          ← mcp-tools 反向呼叫 plugin-tools

  doc-tools                            ← 0 次跨呼叫
```

被跨 plugin 呼叫最多的 skill：`mcp-deploy`(19)、`mcp-sign-pipeline`(6)、`mcp-upgrade`(5)、`mcp-debug`(5)、`mcp-clone`(5)、`plugin-update`(3)、`cli-upgrade`(3)。

**掃過全部 32 個 `plugin.json`，沒有任何一個有依賴宣告欄位**（`dependencies` / `requires` / `peerPlugins` 皆無）。Claude Code 沒有 plugin 依賴機制。

### 2.3 三份 drift 的 rules

`tool-readme-sync.md` 存在於三個 plugin，**md5 全不相同**：

| 位置 | 行數 | md5 |
|---|---|---|
| plugin-tools | 141 | `8348f73a…` |
| mcp-tools | 156 | `85040e3b…` |
| cli-tools | 177 | `b3049168…` |

不是複製品，是同一條規則已各自演化的三個分支。

### 2.4 硬編碼 marketplace 路徑（5 處）

```
plugin-tools/skills/plugin-health/SKILL.md:192   cd /Users/che/Developer/psychquant-claude-plugins
plugin-tools/skills/plugin-debug/SKILL.md:58     SRC=".../psychquant-claude-plugins/plugins/$PLUGIN_NAME"
plugin-tools/skills/plugin-upgrade/SKILL.md:68   MARKETPLACE_ROOT="/Users/che/Developer/psychquant-claude-plugins"
plugin-tools/skills/plugin-create/SKILL.md:79    # 預設：/Users/che/Developer/psychquant-claude-plugins
plugin-tools/rules/tool-readme-sync.md:116       PLUGIN_COUNT=$(ls -d .../psychquant-claude-plugins/plugins/*/ | wc -l)
```

`plugin-update/SKILL.md:70` 已有正確做法——一張 marketplace registry 表格（列了 `psychquant-claude-plugins` + `che-local-plugins`）。

### 2.5 現存 live bug：double-fire

`~/.claude/settings.json` 中兩者皆啟用：

```
doc-guardian@che-local-plugins        = True
doc-tools@psychquant-claude-plugins   = True
```

`doc-tools` v0.2.0 宣稱移除了 user-level 的 `~/.claude/hooks/changelog-update.sh` 以避免 double-fire，但 **`doc-guardian` plugin 自己的 `hooks.json` 仍註冊同一支 `changelog-update.sh` 的 Stop hook 且啟用中**。目前每次 Stop，`changelog-update.sh` 與 `doc-update-guard.sh` 兩支都在跑同一個檢查。

---

## 3. 設計決策

### 3.1 Marketplace 命名：`che-plugin-devtools`

repo 名 `che-plugin-devtools`。（先前候選 `che-claude-plugins` 較貼合既有 `<scope>-claude-plugins` 慣例，使用者選定前者。）

**附帶修正**：`che-claude-config/rules/common-plugins.md:68` 目前指向不存在的 `../../che-claude-plugins/plugins/plugin-tools/rules/mcp-binary-distribution.md`——這條連結一直是壞的，遷移時一併修正指向新 repo。

### 3.2 切成兩個 plugin，邊界由 call graph 決定

| 新 plugin | 來源 | 理由 |
|---|---|---|
| **`devtools`** | plugin-tools + mcp-tools + cli-tools | 三者形成循環依賴（plugin-tools ↔ mcp-tools 雙向），不可分割 |
| **`doc-guardian`** | doc-tools + 舊 doc-guardian | 0 跨呼叫，真正獨立；對不寫 plugin 的人也有價值 |

**為什麼不維持四個**：Claude Code 沒有 plugin 依賴宣告機制（§2.2）。使用者只裝 `plugin-tools` 而未裝 `mcp-tools` 時，`/plugin-tools:plugin-update` 走到 dependency-aware orchestration 呼叫 `/mcp-tools:mcp-deploy` 會直接找不到 skill，**且沒有任何機制事先警告**。「分成三個讓使用者可以只裝需要的」在此 call graph 下是假選項——能選，但選了會壞。

**為什麼不併成一個**：`doc-tools` 是唯一 0 跨呼叫的，把它綁進 devtools 沒有依賴上的理由，且會排除「只想要 CHANGELOG 紀律、不寫 plugin」的使用者。

**context 成本澄清**：Claude Code 會把所有已安裝 plugin 的 skill description 列進 context。四個都裝 vs 合併成一個，總量完全相同。context 不是切分粒度的考量因素。

**skill 名衝突檢查（已驗證）**：三個來源 plugin 的 skill 名分別為 `plugin-*`(6) / `mcp-*`(14) / `cli-*`(4)，前綴天然分開，**零衝突**。24 個 skill 目錄可直接並置於 `plugins/devtools/skills/`，無需改名。

**版本策略**：`devtools` 是新的 plugin identity，版本從 **v1.0.0** 起算，CHANGELOG 首個 entry 記載三個前身的最終版本（plugin-tools 1.18.0 / mcp-tools 1.16.0 / cli-tools 1.1.2）。與 §3.3 的 `doc-guardian` v2.0.0 不對稱是刻意的——後者延續既有名字與身份，前者是新名字。

### 3.3 `doc-guardian` 命名與合併

合併後沿用 `doc-guardian` 這個名字，淘汰 `doc-tools`。

合併後職責：

| 來源 | 職責 | 型態 |
|---|---|---|
| doc-tools | CHANGELOG KAC 1.1.0 格式 + 三方同步驗證 | 3 skills |
| doc-tools | 改 code 沒更新文件 → 擋 turn-end | Stop hook |
| doc-guardian | commit 有架構變更 → 提醒更新 CLAUDE.md | PostToolUse hook |
| doc-guardian | changelog 更新了 wiki 沒同步 → 擋 | Stop hook |

四者共同分母是「守著文件不落後於 code」——`guardian`（稽核與擋）比 `-tools`（處理文件的工具）精確。且可與鄰近命名區分：`docflow` = 文件版本流、`document-skills` = 文件格式處理、`doc-guardian` = 文件紀律守門。`doc-tools` 的 keywords 中原本就列有 `doc-guardian`。

`che-local-plugins` 的 `doc-guardian` 於 cutover 時移除，同時解掉 §2.5 的 double-fire。

版本：合併後發 **v2.0.0**（breaking——來源 marketplace 改變、hook 集合改變）。

### 3.4 合併時必須處理：hook 的硬編碼專案假設

舊 doc-guardian 兩支 hook 寫死了特定專案結構：

```bash
# claude-md-reminder.sh — 某個 Next.js + R 專案的形狀
grep -cE '^web/(app|components|lib)/'
grep -cE '^r_pkg/'
grep -cE '(_targets\.R|vercel\.json|schema\.sql)'

# sync-wiki-check.sh — 假設專案用 changelog/ 目錄 + GitHub Wiki 攤平同步
grep '^changelog/'
```

搬進來後會對所有 repo 生效。在沒有 `web/` 或 `r_pkg/` 的 repo 它們是啞的（不誤擋，但也無作用）；真正的問題是判準寫死在 shell 裡，別的專案想用得改 code。

`doc-tools` 已建好三層 config 注入：`<repo>/.claude/doc-tools.json` → `~/.cache/doc-tools/config.json` → 內建預設，外加 `~/.cache/doc-tools/disabled` kill switch。**合併時把這兩支 hook 的判準遷到這套 config，不要原樣搬**。config key 命名隨 plugin 更名同步（`doc-tools.json` → `doc-guardian.json`，保留舊檔名為 fallback 一個版本）。

### 3.5 rules drift：搬家階段不合併

三份 `tool-readme-sync.md` 改檔名並存於 `devtools/rules/`，**內容一個 byte 不動**：

```
plugins/devtools/rules/
├── tool-readme-sync-plugin.md   # 141 行，位元不變
├── tool-readme-sync-mcp.md      # 156 行，位元不變
├── tool-readme-sync-cli.md      # 177 行，位元不變
├── mcp-binary-distribution.md
└── skill-description-budget.md
```

**理由**：合併三份 drift 需要逐條判斷「哪一份寫法才對、哪些差異是刻意的（cli 與 mcp 的 README 結構本來就不同）」——那是內容判斷，不是搬家動作。若搬家時順手合併，出問題會分不清是搬壞了還是合併合錯了。搬家階段的驗證條件必須維持清楚：**行為完全一樣**。

去重列為搬完後的第一個 issue。

### 3.6 硬編碼路徑改走 registry

§2.4 那 5 處**不改成指向 `che-plugin-devtools`**。devtools 搬走後仍要管理 psychquant 剩下的 28 個 plugin——工具住哪裡與工具管哪裡是兩回事。

正確修法：在 `plugin-update/SKILL.md:70` 的 registry 表格加一行 `che-plugin-devtools`，並把 5 處硬編碼改成走 registry 查詢。搬家因此順帶修掉一個既有設計缺陷（單一 marketplace 假設）。

---

## 4. 遷移機制

**推薦：直接 copy，不保留 git history。**

理由：
- 目錄要合併（plugin-tools / mcp-tools / cli-tools → 單一 `devtools/`），`git filter-repo` 需要 path rename mapping，複雜度與收益不成比例
- 版本歷史已由各 plugin 的 `CHANGELOG.md` 記錄（`doc-tools` 正是為此存在）
- 舊 history 在 `psychquant-claude-plugins` 永久可查，該 repo 不會刪除

新 repo 的 README 與各 plugin CHANGELOG 標註：「v2.0.0 之前的 commit history 見 `psychquant-claude-plugins`，遷移基準 commit `cfb8849`」。

若之後確定需要 history，可補做 `git filter-repo --path plugins/<name>` 逐一 split 後 merge 進來——不阻塞本次遷移。

---

## 5. Cutover 步驟

1. 建立 `che-plugin-devtools` repo（GitHub），寫 `.claude-plugin/marketplace.json`（2 個 entry）
2. Copy `plugin-tools` / `mcp-tools` / `cli-tools` → `plugins/devtools/`，skills 直接並置；rules 依 §3.5 改檔名
3. Copy `doc-tools` → `plugins/doc-guardian/`，併入舊 doc-guardian 的兩支 hook，判準遷至 config（§3.4）
4. 修 §2.4 的 5 處硬編碼 → registry 查詢；registry 表格加 `che-plugin-devtools` 一行
5. push + `claude plugin marketplace add`
6. 安裝新的：`devtools@che-plugin-devtools`、`doc-guardian@che-plugin-devtools`
7. 移除舊的：四個 `@psychquant-claude-plugins` + `doc-guardian@che-local-plugins`
8. `psychquant-claude-plugins`：`marketplace.json` 移除 4 個 entry、刪 `plugins/` 下四個目錄（32 → 28）
9. `che-local-plugins`：移除 `doc-guardian`
10. 修 `che-claude-config/rules/common-plugins.md:68` 的壞連結（§3.1）

### Bootstrap 順序（dogfooding chicken-and-egg）

步驟 1–5 必須**手動**完成——此時 `devtools` 尚未安裝於新 marketplace，無法用 `/devtools:plugin-deploy` 發布自己。步驟 6 之後，devtools 即可用來管理自己與其他 marketplace，迴圈解除。

---

## 6. 驗證條件

搬家的成功條件是**行為完全一樣**，任何差異都是搬家 bug：

- `/devtools:plugin-health` 能掃到 psychquant（28）+ sinica（2）+ che-plugin-devtools（2）三個 marketplace，不再假設單一路徑
- `/devtools:plugin-update <某 psychquant plugin>` 完整跑通，Phase 1.5 的 dependency-aware orchestration 能呼叫到同 plugin 內的 `mcp-deploy`
- `/doc-guardian:changelog-validate` 對既有 plugin 產生與遷移前相同的 exit code
- **double-fire 消失**：Stop 時只有一支 doc-update 檢查執行（§2.5）
- `claude plugin validate` 對兩個新 plugin 皆通過

---

## 7. 已知未決 / 後續 issue

| # | 項目 | 說明 |
|---|---|---|
| 1 | rules 三份 drift 統一 | §3.5，搬完後第一個 issue。需逐條判斷哪些差異是刻意的 |
| 2 | `doc-guardian` hook 判準 config 化 | §3.4 的遷移品質，可能需要一輪實測調整 |
| 3 | git history 是否補做 | §4，非阻塞 |
| 4 | `devtools` 內部 24 skills 的 description budget | 合併後 skill 數量集中，需檢查是否觸發 `skill-description-budget.md` 的上限紀律 |
| 5 | `create-plugin` → `plugin-create` 引用錯誤 | 既有 bug，與遷移無關：`plugin-create/SKILL.md` 第 31、32、266 行把自己的呼叫寫成 `/plugin-tools:create-plugin`，但實際 skill 目錄是 `plugin-create`（名字順序顛倒，該指令不存在）。遷移時順手修，改為 `/devtools:plugin-create` |
