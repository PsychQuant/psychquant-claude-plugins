# che-archive-lines

自動化 LINE macOS 聊天記錄的歸檔流程。

## 背景

LINE macOS 版使用 Qt 框架，其 UI 元素不支援 macOS Accessibility API，因此無法使用標準的 AppleScript 來自動化操作。此 plugin 使用座標點擊方式來實現自動化。

## 功能

- **calibrate**: 校準「⋮」選單按鈕的位置
- **save**: 自動點擊「儲存聊天」功能
- **test**: 測試點擊位置是否正確

## 安裝

### 從 Marketplace 安裝

```bash
/plugin marketplace add PsychQuant/psychquant-claude-plugins
/plugin install che-archive-lines@psychquant-claude-plugins
```

### 依賴

```bash
brew install cliclick
```

還需要在「系統設定 > 隱私權與安全性 > 輔助使用」中授權 Terminal/iTerm。

## 使用方式

指令的完整名稱是 `/che-archive-lines:archive-lines`（沒有其他指令同名時，`/archive-lines` 也可以）。這個 skill 只在你主動輸入時執行，Claude 不會自己觸發；腳本會依座標點擊 LINE 視窗、移動滑鼠，所以 skill 不預先放行任何指令：在預設權限模式下，執行腳本前 Claude Code 會詢問，你可以在詢問時選「不再詢問」；在 `bypassPermissions` 或 auto 模式下則不會詢問。

### 第一次使用

1. 開啟 LINE 並進入任一聊天視窗
2. 執行校準：

```
/che-archive-lines:archive-lines calibrate
```

3. 根據提示，將滑鼠移到聊天視窗右上角的「⋮」按鈕上，按 Enter

### 儲存聊天

```
/che-archive-lines:archive-lines save
```

執行後會：
1. 自動點擊「⋮」按鈕
2. 自動點擊「儲存聊天」選項
3. 開啟儲存對話框（需手動選擇儲存位置）

### 測試

```
/che-archive-lines:archive-lines test
```

僅點擊「⋮」按鈕，用於確認校準是否正確。

## 設定檔

校準資訊儲存在 `~/.config/che-archive-lines/config.json`：

```json
{
  "version": "1.0",
  "offset_x": -30,
  "offset_y": 100,
  "menu_offset_y": 240,
  "description": "相對於視窗右上角的偏移值",
  "calibrated_at": "2026-01-15T10:00:00Z"
}
```

## 資料來源

LINE macOS 版本機的訊息資料庫（`~/Library/Containers/jp.naver.line.mac/…/db/*.edb`）是加密的，無法直接讀取。讀得懂的資料來源只有「儲存聊天」匯出的 `.txt`，也就是這個 plugin 觸發的功能。讀取匯出檔的 LINE MCP 由 [PsychQuant/che-msg#41](https://github.com/PsychQuant/che-msg/issues/41) 追蹤。

匯出的 `.txt` 是對話雙方的逐字內容，請不要 commit 進 git remote。

## 技術原理

1. **相對座標**: 按鈕位置以視窗右上角為基準計算偏移，視窗移動或縮放時自動調整
2. **cliclick**: 使用 cliclick 工具進行滑鼠點擊
3. **osascript**: 使用 AppleScript 取得視窗位置和大小

## 限制

- 僅支援 macOS 版 LINE
- 每次只能儲存當前開啟的聊天
- 儲存對話框需手動選擇位置
- 需要 Accessibility 權限

## 故障排除

### 選單沒有打開

1. 執行 `/che-archive-lines:archive-lines test` 確認點擊位置
2. 如果點擊位置不對，重新執行 `/che-archive-lines:archive-lines calibrate`

### 權限錯誤

1. 開啟「系統設定 > 隱私權與安全性 > 輔助使用」
2. 將 Terminal 或 iTerm 加入允許清單
3. 重新啟動 Terminal

### cliclick 找不到

```bash
brew install cliclick
```

## 授權

MIT License

## 作者

Che Cheng
