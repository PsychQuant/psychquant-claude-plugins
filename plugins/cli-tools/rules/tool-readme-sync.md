# CLI Command Surface ↔ README 同步紀律

當 CLI 工具的 subcommand / flag / 參數語義變動時，**必須**在同一個 commit（或同一個 release 週期內）更新 README。

## 為什麼

CLI 的 README 通常包含三種資訊，都容易過時：

| 區塊 | 容易過時原因 |
|------|------------|
| Usage / Subcommand 列表 | 新增子命令、或把舊命令 deprecate 了 |
| Flag / 參數說明 | flag 改名、預設值翻轉、required → optional |
| 範例命令（複製貼上用的） | 語法變動後範例直接失效 |

使用者習慣複製範例當入門。範例失效 → 使用者第一次跑就報錯 → 信心損失。

## 觸發條件

1. **新增子命令** — 新的 `mytool xxx` 出現
2. **移除 / deprecate 子命令** — BREAKING，CHANGELOG 也要寫
3. **重命名子命令** — 舊名別名是否保留？README 要說清楚
4. **新增 / 移除 flag** — 每個 flag 都是 public contract
5. **Flag 預設值翻轉** — 例如 `--format` 從 `json` 翻成 `text`（隱性 BREAKING）
6. **位置參數順序 / 數量改變** — 影響所有 shell 呼叫
7. **外部依賴改變** — 如需要 `playwright` CLI、`ffmpeg` 等

純實作重構（internal function 改名、效能優化但 flag 不變）不需改 README。

## 必要的 README 改動範圍

| 改動 | README 連動 |
|------|------------|
| 加 subcommand | Usage 表格 + Examples section |
| 改 flag | Flag 說明表 + 所有用到該 flag 的範例 |
| 預設值翻轉 | 在「Migration / Breaking Changes」註記，避免使用者踩坑 |
| 新增依賴（playwright 等） | Prerequisites / Installation 區塊 |
| 新增輸出格式（`--to pdf`） | Format matrix 或「Supported Formats」表 |

## 範例 Walk-through（參考 macdoc）

macdoc CLI 有 `convert --to <fmt>` 這個 single entry point，對應一張 16-row format matrix。每新增一條轉換路由：

```swift
// MacDoc+Convert.swift 的 switch
case ("tex", .docx): try convertTexToDocx(inputURL)   // ← 新加的
```

同一個 PR 必須：

1. 更新 `convert-entry-point.md` 規則的 16 → 17 條路由列表
2. 更新 README 的 Format matrix 加上 `tex → docx` 那行
3. 更新 `textutil-compat.md` 的對照表（如果新 format 有 textutil 對應）
4. CHANGELOG 加 entry

**檢查方式**：grep README 中的 format 清單對照 `switch` 實作，應該一一對應。

## Deploy 前的自我檢查

`cli-deploy` skill 跑完**前**做這個檢查：

```bash
# 抓 CLI 實際支援的 subcommand 清單
ACTUAL=$(./mytool --help 2>&1 | grep -oE '^  [a-z-]+' | sort -u)

# 抓 README 裡文件化的 subcommand
DOCUMENTED=$(grep -oE 'mytool [a-z-]+' README.md | awk '{print $2}' | sort -u)

# diff
diff <(echo "$ACTUAL") <(echo "$DOCUMENTED") || echo "⚠️ README 與 --help 不一致"
```

Flag 層級：

```bash
./mytool subcmd --help 2>&1 | grep -oE '^  --[a-z-]+' | while read flag; do
  grep -q "\`$flag\`" README.md || echo "⚠️ Flag $flag 未在 README 出現"
done
```

## 當 README 已累積落差時的補救

1. **跑 `--help` 做 ground truth dump**，逐一 diff README
2. 檢查 Examples section 的每一條命令，實際執行看看是否還能跑
3. 若 repo 有 E2E test，檢查 test 裡的指令與 README 是否一致（通常 test 才是最新）
4. 雙語 README 記得同步

## 例外

- 純 bug fix（flag / subcommand / 預設值都沒動）→ CHANGELOG 即可
- 未上架 release 的 development build → README 可延後；但 tag 前必須齊

## 和其他 skill 的關係

- `cli-deploy` Step 2.6 檢查 README/--help 一致性，不一致時 **BLOCK** 發布
- `cli-upgrade` 建議加新 flag 時，會提醒「README `Flags` 表格要加 1 行」
- `cli-new-app` scaffold 直接產出含 Usage + Examples + Flags 三區塊的 README 骨架

## TL;DR

**改了 `--help` 輸出，就改 README；`--help` 和 README 不一致就不要發 release。**
