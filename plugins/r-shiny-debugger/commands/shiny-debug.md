---
description: 功能測試導向的 R Shiny App Debug，整合前端 (agent-browser) 與後端 (R console)
argument-hint: [測試描述]
---

# R Shiny Debugger

功能測試導向的 R Shiny App Debug 工具。採用 **Log-First** 原則：每進入一個新狀態，先檢查 R log 確認沒有錯誤，才繼續下一步。發現錯誤時立即修復程式碼。

## 使用方式

- `/shiny-debug` — 互動模式，列出 UI 元素後詢問測試目標
- `/shiny-debug 上傳後圖表更新` — 直接測試指定功能

## 核心原則：Log-First

```
每一步操作後：
  1. 讀取 R log（tail + grep error/warning）
  2. log 乾淨？ → 繼續下一步
  3. log 有錯誤？ → 停止測試 → 分析錯誤 → 修改程式 → 重啟 App → 從頭重新驗證
```

**絕不跳過 log 檢查。** 前端看起來正常不代表後端沒問題。

---

## 執行步驟

### Step 1: 檢查前置需求

```bash
which agent-browser || echo "請先安裝: npm install -g agent-browser && agent-browser install"
which R || echo "請先安裝 R"
```

### Step 2: 偵測 Shiny App

```bash
ls app.R ui.R server.R 2>/dev/null
```

- `app.R` 存在 → 單檔模式
- `ui.R` + `server.R` → 雙檔模式
- 都沒有 → 詢問用戶 app 路徑

如果專案有 `.claude/rules/` 目錄，讀取測試相關的 rule 檔案（如 `08-shiny-testing.md`），取得專案特定的 port、密碼、檢查項目等設定。

### Step 3: 啟動 App（背景執行）

```bash
mkdir -p .shiny-debug

# 清除舊 log
rm -f .shiny-debug/shiny.log

# 檢查 port
lsof -i :3838 | grep LISTEN && echo "Port 3838 被占用"

# 啟動
Rscript -e "shiny::runApp('.', port=3838, launch.browser=FALSE)" 2>&1 | tee .shiny-debug/shiny.log &

# 等待啟動
for i in {1..30}; do
  grep -q "Listening on http" .shiny-debug/shiny.log 2>/dev/null && break
  sleep 1
done
```

### Step 3.1: 🔍 Log 檢查 — App 啟動後

**必須在開啟瀏覽器之前執行。**

```bash
# 檢查啟動過程中的錯誤
grep -iE "^Error|^Warning.*Error|subscript out of bounds|could not find function|cannot open|fatal" .shiny-debug/shiny.log
```

判斷：
- **無錯誤** → 繼續 Step 4
- **有錯誤** → 進入 [錯誤修復流程](#錯誤修復流程)

同時記錄關鍵初始化訊息供後續比對：
```bash
# 記錄重要的初始化訊息（翻譯、資料庫、元件）
grep -iE "\[Translation\]|\[DB\]|INITIALIZE|PROFILE" .shiny-debug/shiny.log
```

### Step 4: 開啟瀏覽器

```bash
agent-browser open http://localhost:3838 --headed
```

### Step 4.1: 🔍 Log 檢查 — 頁面載入後

```bash
# 後端：新產生的錯誤
grep -iE "^Error|^Warning.*Error|subscript out of bounds" .shiny-debug/shiny.log | tail -5

# 前端：JS 錯誤
agent-browser errors
```

判斷：
- **無錯誤** → 取得 UI snapshot，繼續 Step 5
- **有錯誤** → 進入 [錯誤修復流程](#錯誤修復流程)

無錯誤時才取 snapshot：
```bash
agent-browser snapshot -i
```

### Step 5: 確認測試目標

如果用戶提供了 `$ARGUMENTS`，解析測試描述並規劃步驟。

如果沒有，詢問：
```
你想測試什麼功能？
- "上傳 CSV 後圖表應該更新"
- "空輸入時不應該 crash"
- 或直接操作："click @e3"
```

### Step 6: 執行測試（Log-First 迴圈）

對每一個測試步驟，都遵循以下順序：

```
┌─────────────────────────────────────────┐
│  1. 執行操作（click / fill / navigate） │
│  2. 等待（agent-browser wait 1000-3000）│
│  3. 🔍 檢查 R log                      │
│  4. 🔍 檢查前端 errors                 │
│  5. log 乾淨？→ 記錄 ✅，下一步        │
│     log 有錯？→ 進入錯誤修復流程        │
└─────────────────────────────────────────┘
```

**可用操作：**

| 操作 | 命令 |
|------|------|
| 點擊 | `agent-browser click @ref` |
| 輸入 | `agent-browser fill @ref "text"` |
| 選擇 | `agent-browser select @ref "value"` |
| 上傳 | `agent-browser upload @ref /path/file` |
| 等待 | `agent-browser wait 1000` |
| 截圖 | `agent-browser screenshot path.png` |
| 快照 | `agent-browser snapshot -i` |

**每步驟後的 Log 檢查（不可省略）：**

```bash
# 後端 log（必做）
tail -20 .shiny-debug/shiny.log
grep -iE "^Error|^Warning.*Error|subscript|not found|cannot open" .shiny-debug/shiny.log | tail -5

# 前端 errors（必做）
agent-browser errors
```

### Step 7: 輸出報告

**成功：**
```
═══════════════════════════════════════════
測試: 上傳 CSV 後圖表會更新

1. ✅ App 啟動 → [log] 無錯誤
2. ✅ 頁面載入 → [log] 無錯誤
3. ✅ 上傳 test.csv → [log] "Uploaded"
4. ✅ 選擇欄位 → [log] "Rendering"
5. ✅ 圖表已更新 → [log] 無錯誤

結果: ✅ 通過
═══════════════════════════════════════════
```

**失敗後修復：**
```
═══════════════════════════════════════════
測試: 驗證 UI 翻譯

1. ✅ App 啟動 → [log] 無錯誤
2. ❌ 登入 → [log] Error: subscript out of bounds
   🔧 修復: fn_translation.R — named vector 改用 %in% names()
3. 🔄 重啟 App
4. ✅ App 啟動 → [log] 無錯誤
5. ✅ 登入 → [log] 無錯誤
6. ✅ Dashboard 載入 → "平台"、"產品線" 顯示中文

修復數: 1
結果: ✅ 通過（修復後）
═══════════════════════════════════════════
```

### Step 7.5: 產生 E2E 腳本（可選）

測試報告輸出後，詢問用戶：
```
要從這次 debug session 產生 E2E 測試腳本嗎？（shinytest2）
```

如果用戶同意，根據 debug session 中的操作步驟，產生 shinytest2 腳本。

#### 前置條件

1. **檢查 E2E 基礎設施是否存在**：
```bash
ls scripts/global_scripts/98_test/e2e/_setup.R 2>/dev/null
ls scripts/global_scripts/98_test/e2e/helpers/fn_e2e_app_driver.R 2>/dev/null
```

如果不存在，告知用戶需要先建立 E2E 基礎設施，並跳過此步驟。

2. **讀取現有 E2E helpers** 以了解可用的 assertion 函數：
```bash
cat scripts/global_scripts/98_test/e2e/helpers/fn_e2e_assertions.R
```

#### 操作對應表

將 debug session 中的 agent-browser 操作轉換為 shinytest2 API：

| Debug 操作 | shinytest2 對應 |
|------------|----------------|
| 登入（fill password + click submit） | `create_logged_in_app()`（helper 已封裝） |
| 切換 tab（click sidebar item） | `app$set_inputs(sidebar_menu = "tabName")` |
| 填入 input（fill @ref "value"） | `app$set_inputs(\`input-id\` = "value")` |
| 點擊按鈕（click @ref） | `app$click("input-id")` |
| 檢查 log 無錯誤 | `assert_no_r_errors(app, context = "描述")` |
| 檢查 tab 載入正常 | `assert_tab_loads(app, "tabName")` |
| 驗證 AI 按鈕可用 | `assert_ai_button_works(app, "tabName", "module_id")` |
| 等待 | `app$wait_for_idle(timeout = 10000)` + `Sys.sleep(N)` |

**優先使用既有 helper**：如果操作對應到 `assert_tab_loads()` 或 `assert_ai_button_works()`，直接用 helper 而不是拆成底層操作。

#### 腳本模板

```r
# E2E Test: {場景名稱}
# Level: L{級別} ({級別名稱})
# Generated from /shiny-debug session on {日期}
#
# Principles: TD_R007 (E2E testing)

test_that("{場景描述}", {
  app <- create_logged_in_app()
  on.exit(stop_app_safely(app), add = TRUE)

  # Verify login worked
  assert_logged_in(app)

  # --- 以下根據 debug session 操作產生 ---

  # {步驟 1 描述}
  {shinytest2 操作}
  app$wait_for_idle(timeout = 10000)
  assert_no_r_errors(app, context = "{步驟 1 描述}")

  # {步驟 2 描述}
  {shinytest2 操作}
  app$wait_for_idle(timeout = 10000)
  assert_no_r_errors(app, context = "{步驟 2 描述}")

  # ... 更多步驟
})
```

#### 測試級別判斷

根據 debug session 的操作類型自動判斷級別：

| 操作內容 | 級別 | 理由 |
|----------|------|------|
| 只有登入 + 首頁載入 | L1 Smoke | 最基本驗證 |
| Tab 切換、無 R 錯誤 | L2 Navigation | 導航正常性 |
| 元件互動、資料篩選、KPI 檢查 | L3 Functional | 功能正確性 |
| 截圖比對 | L4 Visual | 視覺一致性 |

#### 命名與放置

- 檔名：`test-{場景名}.R`（kebab-case，與既有檔案一致）
- 位置：`scripts/global_scripts/98_test/e2e/test-{場景名}.R`
- 如果該檔案已存在，詢問用戶：覆蓋 or 追加 test_that block

#### 產生後驗證

```bash
# 確認語法正確
Rscript -e "parse('scripts/global_scripts/98_test/e2e/test-{場景名}.R'); cat('PARSE OK\n')"
```

---

### Step 8: 清理

詢問用戶：
1. 繼續測試 → 回到 Step 5
2. 產生 E2E 腳本 → 回到 Step 7.5
3. 結束

```bash
agent-browser close
pkill -f "shiny::runApp"
```

---

## 錯誤修復流程

當 Log 檢查發現錯誤時，依照以下流程處理：

### 1. 分析錯誤

```bash
# 完整錯誤上下文
grep -B2 -A5 -iE "^Error|^Warning.*Error" .shiny-debug/shiny.log | tail -20
```

### 2. 定位問題程式碼

根據錯誤訊息找到對應的 R 檔案和行號。常見模式：

| 錯誤訊息 | 可能原因 | 常見位置 |
|-----------|----------|----------|
| `subscript out of bounds` | `[[key]]` 存取不存在的 key | 翻譯函數、config 讀取 |
| `could not find function` | 函數未 source 或套件未載入 | 初始化區塊 |
| `Column not found` | 資料表 schema 不符 | 元件 server 函數 |
| `cannot open connection` | 資料庫/檔案路徑錯誤 | 連線區塊 |
| `Error in source()` | 找不到被 source 的檔案 | 路徑設定 |

### 3. 修復程式碼

直接修改有問題的 R 檔案。修復時同時改善錯誤訊息的明確度：

```r
# 不好：只知道失敗
result <- some_operation(data)

# 好：知道是哪個元件、什麼輸入出問題
tryCatch({
  result <- some_operation(data)
}, error = function(e) {
  message("[ComponentName] Failed: ", e$message)
  message("[ComponentName] Input: class=", class(data), " nrow=", NROW(data))
})
```

### 4. 驗證修復

```bash
# R parse check
Rscript -e "parse('path/to/modified_file.R')"
```

### 5. 重啟 App 並從頭測試

```bash
agent-browser close
pkill -f "shiny::runApp"
rm -f .shiny-debug/shiny.log

# 重新啟動（回到 Step 3）
Rscript -e "shiny::runApp('.', port=3838, launch.browser=FALSE)" 2>&1 | tee .shiny-debug/shiny.log &
```

**重要：修復後必須從 Step 3 重新開始，不能只跳到出錯的步驟。** 因為修改可能影響初始化流程。

---

## 測試檔案（可選）

如果有 `.shiny-tests.yaml`：

```yaml
tests:
  - name: test_upload
    description: "上傳後圖表更新"
    steps:
      - action: upload
        target: fileInput
        file: test.csv
      - action: verify
        expect:
          backend_log: "Rendering"
```

## 常見問題

**App 啟動失敗：**
```bash
cat .shiny-debug/shiny.log
```

**Port 被占用：**
```bash
kill $(lsof -t -i:3838)
```

**找不到元素：**
```bash
agent-browser snapshot -i
```

**Log 太長找不到重點：**
```bash
# 只看 Error 和 Warning 行
grep -n -iE "^Error|^Warning" .shiny-debug/shiny.log

# 看最近 50 行
tail -50 .shiny-debug/shiny.log
```
