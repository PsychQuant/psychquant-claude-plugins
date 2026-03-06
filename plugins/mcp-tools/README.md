# MCP Tools

MCP Server 開發工具集，提供完整的專案建立、部署發布、升級建議、連線診斷、功能除錯、測試驗證功能。

## Commands

| Command | 用途 | 使用時機 |
|---------|------|----------|
| `/mcp-tools:mcp-new-app` | 建立新專案 | 開始開發新 MCP Server |
| `/mcp-tools:mcp-deploy` | 部署發布 | 專案完成，要發布到 GitHub Release |
| `/mcp-tools:mcp-install` | 安裝 MCP | 從 GitHub Release 下載安裝到 ~/bin |
| `/mcp-tools:mcp-upgrade` | 升級建議 | 檢查依賴更新、結構優化 |
| `/mcp-tools:mcp-sync` | Binary 同步 | 確保 .build/mcpb/~/bin 一致（Swift） |
| `/mcp-tools:mcp-diagnose` | 連線診斷 | Server 無法連線時 |
| `/mcp-tools:mcp-debug` | 功能除錯 | 有 bug、錯誤時 |
| `/mcp-tools:mcp-clone` | Clone 參考 repo | 給 URL，clone + 自動分析可升級功能 |
| `/mcp-tools:mcp-clone-references` | 搜尋競品 | 用關鍵字搜尋並批次 clone |
| `/mcp-tools:mcp-test` | 完整測試 | 開發完成後、CI |

---

## 專案生命週期

```
建立專案               開發完成               其他機器安裝            維護升級
    │                     │                       │                     │
    ▼                     ▼                       ▼                     ▼
┌──────────────┐   ┌──────────────┐       ┌──────────────┐   ┌──────────────┐
│ mcp-new-app  │ → │  mcp-deploy  │ ────→ │  mcp-install │   │  mcp-upgrade │
└──────────────┘   └──────────────┘       └──────────────┘   └──────────────┘
      │                   │                       │                   │
  建立完整結構         編譯+打包+發布         從 GitHub 下載       依賴+結構分析
  Swift/Python/TS     GitHub Release         安裝到 ~/bin        升級建議報告
                      + Plugin（可選）                                ▲
                         │                                           │
                    ┌────┴────┐                              ┌──────────────┐
                    ▼         ▼                              │  mcp-clone   │
             ┌───────────┐  ┌──────────────┐                └──────────────┘
             │  mcp-sync │  │ che-claude-  │                      │
             └───────────┘  │   plugins    │              給 URL，clone 到
                  │         └──────────────┘              references/ 並分析
          .build → mcpb/server → ~/bin                    可借鏡的功能
          Binary 一致性同步
```

---

## 開發流程 Commands

### `/mcp-tools:mcp-new-app [project-name]`

**建立新專案**：互動式建立完整的 MCP Server 專案結構。

```bash
/mcp-tools:mcp-new-app
/mcp-tools:mcp-new-app che-notes-mcp
```

支援語言：
- **Swift**（推薦）- macOS 原生整合、單一 binary
- **Python** - 快速開發、跨平台
- **TypeScript** - Node.js 生態系

建立的結構：
```
project-name/
├── Package.swift / pyproject.toml / package.json
├── Sources/ / src/        # 程式碼
├── mcpb/                   # MCPB 套件目錄
│   ├── manifest.json       # 套件 metadata
│   ├── PRIVACY.md          # 隱私政策
│   ├── server/             # Binary 存放位置
│   └── {project}.mcpb      # 打包後的套件檔（部署時產生）
├── .gitattributes          # Git LFS 設定
├── README.md
├── CHANGELOG.md
└── LICENSE
```

### `/mcp-tools:mcp-deploy [version]`

**部署發布**：編譯 → 打包 MCPB → 建立 GitHub Release → 可選發布為 Plugin。

```bash
/mcp-tools:mcp-deploy
/mcp-tools:mcp-deploy 1.0.0
```

流程：
1. **編譯** - Swift: Universal Binary (arm64 + x86_64)
2. **打包** - 建立 `.mcpb` 套件檔（放在 `mcpb/` 目錄內）
3. **更新** - manifest.json、CHANGELOG.md、README.md 版本歷史
4. **發布** - git commit/push + GitHub Release
5. **Plugin**（可選）- 自動建立 che-claude-plugins 結構並同步

#### MCPB 套件結構

```
mcpb/
├── manifest.json           # 套件 metadata（必要）
├── PRIVACY.md              # 隱私政策（必要）
├── icon.png                # 套件圖示（推薦）
├── server/                 # Binary 或 script（必要）
│   └── BinaryName          # 執行檔
└── project-name.mcpb       # 打包後的 ZIP 檔案
```

**重要**：`.mcpb` 檔案放在 `mcpb/` 目錄內，不是專案根目錄！

### `/mcp-tools:mcp-install [version]`

**安裝 MCP**：從 GitHub Release 下載並安裝到 `~/bin`。

```bash
/mcp-tools:mcp-install              # 安裝最新版
/mcp-tools:mcp-install v1.2.0       # 安裝指定版本
/mcp-tools:mcp-install --list       # 列出可用版本
```

流程：
1. **讀取** - 從 manifest.json 取得專案資訊
2. **下載** - 從 GitHub Release 下載 binary
3. **安裝** - 放置到 ~/bin 並設定執行權限

**與 mcp-deploy 的差異**：

| 命令 | 用途 | Reproducibility |
|------|------|-----------------|
| `mcp-deploy` | 編譯+發布（開發用） | 可能是未 release 的版本 |
| `mcp-install` | 下載+安裝（使用用） | 確保是已發布的 release 版本 |

### `/mcp-tools:mcp-clone <github-url> [target-mcp-project]`

**Clone 參考 repo**：直接 clone 指定 GitHub repo 到 MCP 專案的 `references/`，自動分析可借鏡功能。

```bash
/mcp-tools:mcp-clone https://github.com/user/apple-mail-mcp
/mcp-tools:mcp-clone https://github.com/user/repo che-apple-mail-mcp
/mcp-tools:mcp-clone --list
```

流程：
1. **Clone** - `--depth 1` 到 `references/{repo-name}/`
2. **README** - 在 `references/README.md` 記錄來源 URL
3. **分析** - 平行分析參考 repo 和自己的專案
4. **比較** - 產生功能矩陣和升級建議（存到 `docs/`）
5. **串接**（可選）- 直接執行 `/mcp-tools:mcp-upgrade features`

### `/mcp-tools:mcp-clone-references [search-query]`

**搜尋競品**：用關鍵字在 GitHub 搜尋相關 MCP servers，批次 clone 並可選競品分析。

```bash
/mcp-tools:mcp-clone-references calendar
/mcp-tools:mcp-clone-references apple reminders
/mcp-tools:mcp-clone-references --list
```

### `/mcp-tools:mcp-upgrade [focus-area]`

**升級建議**：分析現有專案，提出改進建議，完成後可串接部署。

```bash
/mcp-tools:mcp-upgrade           # 全面分析
/mcp-tools:mcp-upgrade deps      # 只檢查依賴
/mcp-tools:mcp-upgrade structure # 只檢查結構
/mcp-tools:mcp-upgrade features  # 只建議新功能
```

檢查項目：
- **依賴更新** - MCP SDK、其他套件最新版本
- **結構優化** - 缺失檔案（LICENSE、CHANGELOG、.gitattributes）
- **程式碼品質** - TODO/FIXME、不安全的 try!
- **新功能建議** - 批次操作、搜尋功能等

完成升級後會詢問是否要直接串接 `mcp-deploy` 進行部署。

### `/mcp-tools:mcp-sync [--check-only]`

**Binary 同步**：確保 Swift MCP 專案的三個 binary 副本一致。

```bash
/mcp-tools:mcp-sync              # 檢查並同步
/mcp-tools:mcp-sync --check-only # 只檢查不同步
```

同步方向：
```
.build/arm64 + .build/x86_64 → mcpb/server/{Binary} → ~/bin/{Binary}
```

**只適用 Swift 專案**。Python/TypeScript 使用 wrapper script，不需要。

功能：
- **一致性檢查** — hash + architecture-aware 比對
- **同步選項** — 從 .build 重建 / mcpb→bin / 完整重編譯
- **Post-sync 驗證** — 確認三者 hash 一致

---

## 除錯流程 Commands

```
MCP Server 有問題？
        │
        ▼
┌───────────────────┐
│ /mcp-tools:mcp-diagnose │  ← 先確認連線正常
└─────────┬─────────┘
          │
    連線正常？
    │     │
   Yes    No → 修復連線問題
    │
    ▼
┌───────────────────┐
│ /mcp-tools:mcp-debug  │  ← 診斷功能問題
└─────────┬─────────┘
          │
    問題解決？
    │     │
   Yes    No → 根據報告修復
    │
    ▼
┌───────────────────┐
│ /mcp-tools:mcp-test   │  ← 驗證所有功能
└───────────────────┘
```

### `/mcp-tools:mcp-diagnose <server-name>`

**連線診斷**：確認 MCP Server 基本連線正常。

```bash
/mcp-tools:mcp-diagnose che-ical-mcp
```

功能：
- 檢查 `claude mcp list` 連線狀態
- 測試基本 tool 呼叫
- 輸出連線診斷報告

### `/mcp-tools:mcp-debug <server-name> [error-message]`

**功能除錯**：深入診斷功能問題。

```bash
/mcp-tools:mcp-debug che-ical-mcp
/mcp-tools:mcp-debug che-things-mcp "access denied"
```

功能：
- 快速診斷（3 個讀取測試）
- 錯誤訊息分析
- 框架特定除錯（AppleScript / EventKit）
- 權限問題修復指引

### `/mcp-tools:mcp-test <server-name>`

**完整測試**：驗證所有 tools 正常運作。

```bash
/mcp-tools:mcp-test che-ical-mcp
```

功能：
- 自動發現所有 tools
- 分類測試（讀取 / 搜尋 / 建立修改刪除）
- 生命週期測試（無副作用）
- 覆蓋率報告

---

## 支援的框架

| 框架 | 適用 MCP | 特殊除錯 |
|------|----------|----------|
| AppleScript | che-things-mcp, che-apple-mail-mcp | Dictionary 分析、唯讀屬性 |
| EventKit | che-ical-mcp | 隱私權限（Calendars/Reminders）|
| OOXML | che-word-mcp | Document 結構分析 |
| 其他 Swift | - | Package.swift 分析 |

## 權限問題快速修復

EventKit MCP 最常見問題是權限：

```bash
# 開啟系統設定
open "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars"
open "x-apple.systempreferences:com.apple.preference.security?Privacy_Reminders"
```

**重要**：要授權的是 **IDE**（Cursor/VS Code/Terminal），不是 MCP binary！

## 測試資料命名規則

| 類型 | 前綴 |
|------|------|
| Event | `MCP_DEBUG_TEST_EVENT` |
| Reminder | `MCP_DEBUG_TEST_REMINDER` |
| Calendar | `MCP_DEBUG_TEST_CALENDAR` |
| Todo | `MCP_DEBUG_TEST_TODO` |
| Project | `MCP_DEBUG_TEST_PROJECT` |

---

## MCP Server 對應表

| MCP Server | Binary 名稱 | 語言 |
|------------|-------------|------|
| che-things-mcp | CheThingsMCP | Swift |
| che-ical-mcp | CheICalMCP | Swift |
| che-apple-mail-mcp | CheAppleMailMCP | Swift |
| che-word-mcp | CheWordMCP | Swift |

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| v1.8.0 | 2026-02-20 | 新增 clone 命令（給 URL 直接 clone + 自動分析可升級功能）；新增 mcp-clone-references 命令（搜尋競品批次 clone）|
| v1.7.0 | 2026-02-01 | 新增 mcpb-sync 命令；mcp-deploy 加入 Phase 3.5 Binary 一致性驗證；mcp-upgrade 加入 Binary 檢查；debug 重建後自動同步 |
| v1.6.0 | 2026-01-27 | mcp-deploy 新增 Plugin 發布；mcp-upgrade 可串接 deploy |
| v1.5.0 | 2026-01-16 | 新增 mcp-install 命令：從 GitHub Release 下載安裝 MCP Server |
| v1.3.0 | 2026-01-16 | 修正 MCPB 套件結構說明，.mcpb 放置於 mcpb/ 目錄內；更新 README 文件 |
| v1.2.0 | 2026-01-16 | 新增 new-mcp-app、mcp-deploy、mcp-upgrade 三個開發流程命令 |
| v1.1.0 | 2026-01-15 | 新增 debug、test 命令 |
| v1.0.0 | 2026-01-14 | 初始版本，diagnose 命令 |
