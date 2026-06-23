---
description: 抓取並分析 Posit Connect Cloud 部署後的 runtime log（lag / crash 診斷）。Connect Cloud 無 API，只能 browser 自動化 — 收 safari-browser（簡單主路）+ agent-browser（network 進階）兩條路徑
argument-hint: [公司名，如 QEF_DESIGN]
---

# Connect Cloud Logs

抓取 **Posit Connect Cloud**（SaaS，`connect.posit.cloud`）部署後的後端 runtime log，診斷部署後才出現的 **lag / crash / 資料異常** bug。

> 這是 `/shiny-debug`（local app）的 **remote 部署版**。local Shiny log 在 `.shiny-debug/shiny.log`；Connect Cloud 的等價物是 web UI 的 **Logs 面板**（你截圖底部那塊），本 command 把它自動化。

---

## ⚠️ 核心事實（2026-06-23 spike 驗證）

| 事實 | 來源 |
|------|------|
| **Connect Cloud 沒有 programmatic log API / CLI / API key** | 官方 `docs.posit.co/connect-cloud` system 文件確認 |
| 網路上的 `CONNECT_API_KEY` / `connectapi` R package / `curl` 抓 log / `usermanager` CLI **全是 self-hosted Posit Connect**，**不適用** Cloud SaaS | 兩個是不同產品 |
| Cloud log **只能從 web UI 的 Logs 面板看** → 只能 browser 自動化 | — |
| Logs 面板是 **React virtualized list** — DOM 只渲染 viewport 內幾行（~12 行），要滾動累積才抓得到完整 log | spike 觀察 |
| Metrics（CPU / 記憶體 / 連線曲線）是**圖**，只能 `screenshot`，**讀不到數值** | spike 觀察 |
| 敏感欄位（Port / Database / User / password）已被 `***REDACTED***` | Connect Cloud 安全功能，正常 |

**所以 lag bug 診斷**：lag 通常**不跳紅字**，重點看 metrics 曲線 + log timestamp gap（哪兩行之間 gap 異常大）。必要時在 R code 嫌疑處埋 `message(Sys.time(), " ...")` 再 redeploy。

---

## 兩條路徑（按情境選）

| | **Path A: safari-browser**（主路、推薦） | **Path B: agent-browser**（進階） |
|---|---|---|
| 何時用 | 快速看 log、spot-check、不需要 network | 要看 **network**（lag = 慢 XHR）、要背景 headless |
| 登入持久 | ✅ 真實 Safari，cookie 天然持久，登一次永久 | ⚠️ 需 `state save/load`（見下方「auth 設定」） |
| 干擾 | 用到 Safari 視窗（`--url` lock 控） | 不干擾（但 instance 模型 fragile） |
| 平台 | macOS only | 跨平台 |
| 看 network | ❌ | ✅ `agent-browser network` |

**預設走 Path A。** 只有要看 network request timing（診斷某個 API/DB call 慢）才用 Path B。

---

## Step 0：前置 + 取得 content URL

```bash
which safari-browser || echo "Path A 需要 safari-browser"
which agent-browser  || echo "Path B 需要 agent-browser"
```

取得目標公司的 Connect Cloud content。優先讀 `.claude/companies.yaml`（每公司的 deployed URL + metadata）：

```bash
# 從 l4_enterprise 專案根目錄
grep -iE "url|connect|content" .claude/companies.yaml 2>/dev/null
```

- Connect Cloud **主控台**（看 log 的管理介面）：`https://connect.posit.cloud/`
- 已知 live app URL 範例：MAMBA = `https://kyleyhl-ai-martech-l4-mamba.share.connect.posit.cloud/`
- `$ARGUMENTS` 給了公司名（如 `QEF_DESIGN`）→ 用它對應 content

---

## Path A：safari-browser（主路）

### A1. 開主控台 + 登入（一次性，cookie 持久）

```bash
LOCK=(--url connect.posit.cloud)
safari-browser open "https://connect.posit.cloud/" "${LOCK[@]}"
```

> **Tab lock 紀律（CRITICAL）**：一律用 bash array `LOCK=(--url connect.posit.cloud)` + `"${LOCK[@]}"`。
> **不要**寫 `LOCK="--url x"` + 未引號 `$LOCK` — zsh 不 word-split，會報 `Unknown option`（Claude Code Bash 跑在 zsh）。

若未登入 → **請使用者在 Safari 手動完成 OAuth 登入**（不能代點）。Safari cookie 持久，之後不用再登。

### A2. 導航到 content 的 Logs 面板

```bash
# snapshot 找 content 連結（refs 是 per-snapshot 臨時值，每次重新取）
safari-browser snapshot -i "${LOCK[@]}"
# 點進目標 content（ref 依 snapshot 結果）
safari-browser click @eN "${LOCK[@]}"
safari-browser wait 3000 "${LOCK[@]}"
```

開 Logs 面板：右側欄 Logs 圖示，或按 `~` 鍵：

```bash
safari-browser press "~" "${LOCK[@]}"   # 或 click Logs icon 的 ref
safari-browser wait 2000 "${LOCK[@]}"
```

### A3. 抓 log（處理 virtualized list）

⚠️ **virtualized list 只渲染 viewport 內幾行**。要抓完整 log 必須**往上滾 + 累積去重**，不能一次 snapshot 就當抓全（那是 silent truncation）：

```bash
# 先抓當前可見
safari-browser snapshot "${LOCK[@]}" > /tmp/cclog_0.txt
# 往上滾載入更早的 log，逐段抓（N 依需要的歷史長度）
for i in 1 2 3 4 5; do
  safari-browser scroll up 600 "${LOCK[@]}"
  safari-browser wait 800 "${LOCK[@]}"
  safari-browser snapshot "${LOCK[@]}" > /tmp/cclog_$i.txt
done
# 合併去重（時間戳開頭的行）
cat /tmp/cclog_*.txt | sort -u > /tmp/cclog_merged.txt
```

> 🔧 **首次實機微調**：scroll 像素（600）+ 圈數（5）依該 content log 長度調。確認合併後**最舊那行的時間戳**有涵蓋到你要看的時段，否則加圈數。

### A4. 抓 metrics（lag 診斷關鍵）

```bash
safari-browser screenshot /tmp/cc_metrics.png "${LOCK[@]}"
```

讀截圖看 **CPU / 記憶體 / 連線曲線**哪個時間點飆高 — lag 多半在這裡，不在 log 文字。

---

## Path B：agent-browser（進階，看 network）

### ⭐ auth 設定（spike 最核心 — 必讀，否則一定踩雷）

agent-browser 的 3 個 auth 概念**不要混淆**：

| 機制 | 用途 | 雷 |
|------|------|----|
| `state save ./auth.json` / `--state ./auth.json` | **跨 headed→headless 的橋**（登入存檔，headless 載入） | flag 前置 |
| `AGENT_BROWSER_SESSION_NAME=<name>` env | auth state auto-save/restore by name | 只管 auth，**不選 instance** |
| `AGENT_BROWSER_SESSION=<name>` env | 選 **instance**（isolated session） | 跟上面是**不同** env |
| `--persist` / `--no-isolated` | 固定 profile dir | ⚠️ **這版單獨用會 `Unknown command`**，別賴它 |

**致命雷（spike 卡 10+ 步的主因）**：
> **agent-browser 的 headed 和 headless 是不同 browser instance**，`session list` 還不一定追蹤 headed 的。所以 `--headed open` 的視窗，跟後續無 flag 的 `snapshot`/`get url` **連到不同 instance** → 一直連錯、抓到 about:blank 或別的殘留 tab。

**正解 = `state save/load` 橋接**（官方 `skills get core --full` line 218-221）：

```bash
# === 一次性：headed 登入 → 存 auth ===
agent-browser --headed open "https://connect.posit.cloud/"
# 使用者在彈出視窗手動 OAuth 登入（headless 會 OAuth Invalid request，必須 headed）
agent-browser --headed state save ~/.agent-browser-posit-auth.json   # 從登入的 headed instance 存

# === 之後每次：headless 載入 auth ===
agent-browser --state ~/.agent-browser-posit-auth.json open "https://connect.posit.cloud/content/<id>"
agent-browser --state ~/.agent-browser-posit-auth.json snapshot -i
```

> auth 過期 → 重跑「一次性」段落重存。flag（`--headed` / `--state`）**一律前置**於 command。

### B1-B3. 導航 / 抓 log / metrics

同 Path A 的 A2-A4，但命令是 `agent-browser`（帶 `--state`），且：

```bash
# Path B 獨有：看 network（lag = 慢 XHR / DB call）
agent-browser --state ~/.agent-browser-posit-auth.json network
```

找耗時最長的 request — 那常是 lag 的真兇（慢 query、慢 OpenAI call、慢 Supabase round-trip）。

---

## Step 9：分析 log + 輸出

```bash
# error / warning
grep -iE "error|warning|fail|exception|cannot|timeout" /tmp/cclog_merged.txt

# timestamp gap（找哪兩行之間 gap 大 = 那段慢）— 人工掃時間戳，或：
awk '{print $1, $2}' /tmp/cclog_merged.txt   # 看連續行的時間戳差
```

**輸出格式：**

```
═══════════════════════════════════════════
Connect Cloud Log — QEF_DESIGN
路徑: Path A (safari-browser)

抓取範圍: 21:48:54 ~ 21:49:00（6 秒，N 圈滾動）
─────────────────────────────────────────
🔴 Error/Warning: （無 / 列出）
⏱  最大 timestamp gap: 21:48:57→21:49:00（3s，連 Supabase PostgreSQL）
📊 Metrics（截圖 /tmp/cc_metrics.png）: CPU 在 21:49 飆至 X%
─────────────────────────────────────────
診斷: lag 來自 Supabase 連線 round-trip（3s）
建議: 在 dbConnectAppData() 前後埋 message(Sys.time()) 確認 / 考慮連線池
═══════════════════════════════════════════
```

---

## 踩雷速查

| 症狀 | 原因 | 解 |
|------|------|----|
| agent-browser snapshot 抓到 about:blank / 別的 tab | headed/headless 不同 instance | 用 `--state` 一致載入，flag 前置 |
| `Unknown command: --persist` | `--persist` 單獨用的 parser 雷 | 改用 `--state` / `AGENT_BROWSER_SESSION_NAME` |
| log 只有 ~12 行，抓不到更早 | virtualized list 只渲染 viewport | A3 的滾動累積 + 去重 |
| safari `Unknown option` | `$LOCK` 沒引號（zsh 不 word-split） | bash array `"${LOCK[@]}"` |
| `Could not connect to Safari` | Safari 沒開 | 先 `safari-browser open` 或手動開 Safari |
| metrics 讀不到數值 | 是圖不是文字 | `screenshot` 後讀圖 |
| OAuth Invalid request | headless 開 OAuth 頁 | 登入那刻必須 `--headed` |

---

## 跟 `/shiny-debug` 的關係

| 情境 | 工具 |
|------|------|
| Local dev app（`localhost:3838`）log | `/shiny-debug`（讀 `.shiny-debug/shiny.log`） |
| **部署後 Connect Cloud runtime log** | **本 command** |
| Live app 前端 UI 驗證（不看 log） | `safari-browser` 直接調用（見 `08-shiny-testing.md`） |

部署後 lag/crash bug 的標準流程：本 command 抓 Connect Cloud log → 定位慢的那段 → 回 local 用 `/shiny-debug` 重現 + 修 → redeploy。
