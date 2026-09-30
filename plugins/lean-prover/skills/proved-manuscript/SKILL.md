---
name: proved-manuscript
description: |
  把使用定理卡（theorem cards）的專案中「Lean 已證明完」的命題，整理成一份整合版文件，
  並產出證明前沿報告。文件只收 `card-graph --lean` 判定為 proved、且相依都已定義或已收錄的定理；
  前沿報告分兩層：有 Lean 敘述但未證明、還沒有 Lean 敘述。
  當用戶說「整合版 manuscript」「只收證明完的命題」「證明前沿」「proved manuscript」
  「哪些命題已經證明」「證明到哪」時觸發。
argument-hint: "[lean_package_root] [--manuscript main.tex] [--graph graph.json] [--out dir]"
---

# Proved Manuscript

由 Lean 檢查過的卡片圖，產生兩個檔案：

| 檔案 | 內容 |
|------|------|
| `PROVED_MANUSCRIPT.tex` | 只含證明完的定理（加上它們用到的定義），依相依順序，陳述取自論文原文 |
| `FRONTIER.md` | 證明前沿：有 Lean 敘述但未證明、還沒有 Lean 敘述、證明完但被擋住的 |

`proved` 是收錄的必要條件，不是充分條件：還要至少一個證明模組的前提都是定義或已收錄的定理（相依封閉）。不靠人判斷；卡片證明完且前提都已收錄，下次執行自動加入，否則列在 `FRONTIER.md` 的「Proved but held back」並寫明在等哪些前提。

## 規則

1. **只認 Lean 檢查過的圖。** 圖的 `check` 欄位必須是 `lean`。沒帶 `--lean` 的圖是文字掃描的結果，不算證明狀態，腳本會拒絕（exit 2）。
2. **沒有 `card-graph` 就停下來**，說明缺什麼，不退回文字掃描、不自己掃 `.lean` 檔。
3. **不重新判斷證明。** 這個 skill 不改卡片、不改稿件、不改 Lean 檔，只寫自己的兩個輸出檔。
4. **陳述取自稿件。** 每個定理用卡片 `block` 標籤在稿件中找到的定理環境，證明不收。找不到環境時退回卡片的 `natural` 文字，並標註「statement from card text」。

## 步驟

### Step 1: 定位專案

找到含 `lakefile.toml` 的目錄（引數為空就從當前目錄往上找），確認有 `cards/` 目錄。函式庫前綴取 `lakefile.toml` 第一個 `[[lean_lib]]` 的 `name`。

稿件主檔：用 `--manuscript`；沒給時，在套件根目錄往上兩層的 `manuscript/` 找恰好一個含 `\documentclass` 的 `.tex`，找不到或有多個就問使用者。

### Step 2: 取得 Lean 檢查過的圖

用兩個明確的變數：`GRAPH`（實際使用的圖檔）與 `CARD_GRAPH`（實際執行的執行檔）。

有 `--graph` 就令 `GRAPH` 為該檔，先確認它的 `check` 是 `lean`，然後跳到 Step 3。否則：

```bash
# LEANIST_PROJECTS = the umbrella folder (~/Developer/Leanist-projects); the tools repo is Leanist-tools inside it
CARD_GRAPH=$(command -v card-graph)
[ -z "$CARD_GRAPH" ] && for c in "$LEANIST_PROJECTS/Leanist-tools/.build/release/card-graph" "$LEANIST_PROJECTS/Leanist-tools/.build/debug/card-graph"; do
  [ -x "$c" ] && CARD_GRAPH=$c && break
done
[ -n "$CARD_GRAPH" ] || { echo "找不到 card-graph；請在 Leanist-tools 執行 swift build --product card-graph"; exit 1; }
WORK=$(mktemp -d "${TMPDIR:-/tmp}/proved-manuscript.XXXXXX")
GRAPH="$WORK/graph.json"
"$CARD_GRAPH" <package-root> --library <Prefix> --lean > "$GRAPH" || { echo "card-graph 失敗，不產生文件"; exit 1; }
```

找不到就停下來，不退回文字掃描。

**先告訴使用者**：`--lean` 會建置整個函式庫，冷快取時可能要很久（Mathlib 全建）；已建置過的專案通常一到兩分鐘。

### Step 3: 產生文件

```bash
python3 "$CLAUDE_PLUGIN_ROOT/scripts/proved_manuscript.py" \
  --graph "$GRAPH" --cards <package-root>/cards \
  --manuscript <main.tex> --out <out-dir>
```

`--out` 預設是套件根目錄。腳本印出「N of M theorem cards included (K proved)」與兩個檔案路徑。

退出碼：0 成功；1 輸入問題（缺卡片、圖裡有不存在的前提、稿件缺 `\input` 檔、相依循環、`--check` 發現過期）；2 圖不是 Lean 檢查過的。

### Step 4: 檢查與回報

1. 用 `xelatex` 編譯 `PROVED_MANUSCRIPT.tex` 兩次，確認沒有錯誤。
2. 回報：收錄幾個、總共幾個定理卡、兩個檔案路徑、被擋住的定理（若有）。
3. 提醒兩件事：
   - 文件裡的定理與引用編號是這份文件自己的，不是稿件的；每個條目附稿件標籤。
   - 證明之間沒有互相引用的邊時，這份文件只是幾個彼此無關的結果，前沿報告也會高估（沒有證明模組的 open 卡片一律算「就緒」），報告中已註明。

## 檢查是否過期

```bash
python3 "$CLAUDE_PLUGIN_ROOT/scripts/proved_manuscript.py" --graph "$GRAPH" --cards <cards> --manuscript <main.tex> --out <out-dir> --check
```

輸出與磁碟上的檔案不同時 exit 1 並印出過期的檔名。輸出沒有時間戳，同樣輸入一定得到同樣輸出。

## 相關

- `/lean-prover:status`：以 `sorry` 數量回報進度（不認得卡片）。
- 設計與規格：`openspec/changes/lean-prover-proved-book/`（或歸檔後的 `openspec/specs/proved-manuscript-generation/`）。
