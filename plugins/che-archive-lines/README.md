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
/plugin install che-archive-lines@PsychQuant/psychquant-claude-plugins
```

### 手動安裝

將此目錄複製到 `~/.claude/plugins/che-archive-lines/`

### 依賴

```bash
brew install cliclick
```

還需要在「系統設定 > 隱私權與安全性 > 輔助使用」中授權 Terminal/iTerm。

## 使用方式

### 第一次使用

1. 開啟 LINE 並進入任一聊天視窗
2. 執行校準：

```
/archive-lines calibrate
```

3. 根據提示，將滑鼠移到聊天視窗右上角的「⋮」按鈕上，按 Enter

### 儲存聊天

```
/archive-lines save
```

執行後會：
1. 自動點擊「⋮」按鈕
2. 自動點擊「儲存聊天」選項
3. 開啟儲存對話框（需手動選擇儲存位置）

### 測試

```
/archive-lines test
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

1. 執行 `/archive-lines test` 確認點擊位置
2. 如果點擊位置不對，重新執行 `/archive-lines calibrate`

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
