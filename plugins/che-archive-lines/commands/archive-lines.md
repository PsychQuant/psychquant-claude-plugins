---
description: 自動儲存 LINE macOS 聊天記錄
argument-hint: [calibrate|save|test|help]
allowed-tools: Bash(*), Read, Write, Glob
---

# Archive Lines

自動化 LINE macOS 的「儲存聊天」功能。

## 使用方式

```
/archive-lines calibrate   # 第一次使用：校準按鈕位置
/archive-lines save        # 自動儲存當前聊天
/archive-lines test        # 測試點擊位置
/archive-lines help        # 顯示說明
```

## 執行步驟

### Step 1: 解析參數

從 `$ARGUMENTS` 取得操作類型：
- `calibrate`: 校準模式
- `save`: 儲存模式
- `test`: 測試模式
- `help` 或空白: 顯示說明

### Step 2: 取得腳本路徑

```bash
SCRIPT_DIR="$(dirname "$(dirname "$0")")/scripts"
SCRIPT="$SCRIPT_DIR/line-save-chat.sh"
```

如果使用 plugin 安裝，腳本路徑為：
```
~/.claude/plugins/che-archive-lines/scripts/line-save-chat.sh
```

或從 marketplace 來源：
```
/Users/che/Library/CloudStorage/Dropbox/che_workspace/projects/psychquant-claude-plugins/plugins/che-archive-lines/scripts/line-save-chat.sh
```

### Step 3: 執行對應操作

#### calibrate - 校準模式

```bash
# 執行校準腳本
./scripts/line-save-chat.sh calibrate
```

流程：
1. 啟動 LINE
2. 取得視窗位置和大小
3. 提示用戶把滑鼠移到「⋮」按鈕
4. 按 Enter 後記錄滑鼠位置
5. 計算相對偏移值（相對於視窗右上角）
6. 儲存到 `~/.config/che-archive-lines/config.json`

#### save - 儲存模式

```bash
# 執行儲存腳本
./scripts/line-save-chat.sh save
```

流程：
1. 讀取校準設定
2. 啟動 LINE
3. 取得當前視窗位置
4. 計算絕對座標（視窗位置 + 相對偏移）
5. 點擊「⋮」按鈕
6. 等待 0.5 秒
7. 點擊「儲存聊天」選項
8. 等待儲存對話框出現

#### test - 測試模式

```bash
# 測試點擊位置
./scripts/line-save-chat.sh test
```

只點擊「⋮」按鈕，不點擊選單，用於確認校準是否正確。

### Step 4: 輸出結果

```
═══════════════════════════════════════════
 Archive Lines 完成
═══════════════════════════════════════════

操作: save
狀態: 成功
說明: 請在儲存對話框中選擇位置

═══════════════════════════════════════════
```

## 設定檔格式

`~/.config/che-archive-lines/config.json`:

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

## 依賴需求

- **cliclick**: `brew install cliclick`
- **LINE macOS**: 已安裝並登入
- **Accessibility 權限**: Terminal 需要輔助使用權限

## 注意事項

1. **首次使用必須校準**: 執行 `/archive-lines calibrate`
2. **視窗大小變化無影響**: 使用相對座標，自動計算
3. **手動選擇儲存位置**: 腳本會開啟儲存對話框，需手動選擇路徑
4. **僅支援當前聊天**: 每次只能儲存正在查看的聊天
5. **macOS 限定**: 僅支援 macOS 版 LINE

## 故障排除

### 選單沒有打開
- 執行 `/archive-lines test` 確認點擊位置
- 重新執行 `/archive-lines calibrate` 校準

### 點擊到錯誤位置
- LINE 視窗可能被其他視窗遮擋
- 確認 LINE 是前景應用程式

### 權限錯誤
- 系統設定 > 隱私權與安全性 > 輔助使用
- 將 Terminal/iTerm 加入允許清單
