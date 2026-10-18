# mcp-tcc

MCP 開發時的 macOS TCC 授權。出問題時一層一層查；開發時把授權做進 Swift MCP，而不是出事後才查。

做法取自 [`che-ical-mcp`](https://github.com/PsychQuant/che-ical-mcp) 的實戰經驗，並補上 Apple Events（Automation）。

> **狀態：v0.1.0。** 每個主張都在 [`references/evidence.md`](references/evidence.md) 標了「已驗證／他人實測／類推／未驗證」。他人實測的證據各有各的環境（見證據表每一列，有些沒記載版本）；**macOS 27.x 的 TCC 行為沒有任何實測**。Apple Events 缺 entitlement 時的實際失敗樣子目前是**類推**。

## 它解決什麼

| 你看到的 | 屬於 |
|---|---|
| `Not authorized to send Apple events to Things3`（常對應 OSStatus -1743） | Automation |
| `Calendar access denied`，但 status 顯示已授權 | EventKit（已觀察到） |
| 授權對話框從頭到尾不彈出 | 簽章／entitlements／Info.plist |
| 換簽章或升級之後突然失效 | 舊授權綁在舊簽章上：EventKit 已觀察到，Apple Events 沒看過 |

涵蓋範圍是封閉的，只有 **EventKit（Calendar／Reminders）** 與 **Apple Events**。Accessibility、Full Disk Access、Photos、麥克風、相機、Contacts、Location、Screen Recording、Files & Folders，以及 Keychain／API token 這類憑證授權，都沒有一手資料，不涵蓋。

## Skills

| Skill | 做什麼 |
|---|---|
| `/mcp-tcc:tcc-diagnose` | 逐層診斷：哪個服務 → 哪個 binary 與 host → 簽章／entitlements／Info.plist → tccd 日誌 → 下一步。只讀取，不替使用者按授權或重置；frontmatter 只預先核准列出的幾個指令前綴（已盡量收緊），其餘照常跳權限提示 |
| `/mcp-tcc:tcc-instrument` | 把授權做進 Swift MCP：嵌入 Info.plist、放對 entitlements、把 -1743 轉成可行動的錯誤訊息；`--setup`／`--print-tcc-path` 是建議項。**準備跑 `mcp-sign-pipeline` 之前先看它的「先決警告」** |

**最低要求**是 Info.plist、entitlements、可行動的錯誤訊息這三樣；`--setup`、`--print-tcc-path`、啟動橫幅是建議但非必要。

## 使用

```
che-things-mcp 回 "Not authorized to send Apple events to Things3"，幫我查
→ /mcp-tcc:tcc-diagnose

幫 che-things-mcp 補上 Info.plist、entitlements 和可行動的錯誤訊息
→ /mcp-tcc:tcc-instrument
```

## 何時用哪個

| 情境 | 用 |
|---|---|
| MCP 完全連不上、工具叫不出來 | `harness-devtools:mcp-diagnose` |
| 連得上但某個 tool 行為錯，原因未知 | `harness-devtools:mcp-debug` |
| 已知或懷疑是 EventKit／Apple Events 授權 | `mcp-tcc:tcc-diagnose` |
| 新 MCP 要碰 EventKit／Apple Events，或這類專案缺 Info.plist／entitlements | `mcp-tcc:tcc-instrument` |
| 安裝簽章與公證 pipeline | `harness-devtools:mcp-sign-pipeline`（**先**做 `tcc-instrument` 的 Step 3，並讀它 Step 5 的流程） |
| che-ical-mcp 自己的 Calendar 問題 | `che-ical-mcp:troubleshoot-tcc` |

幾個 skill 的觸發語會重疊（`mcp-sign-pipeline` 的 description 也寫了「TCC dialog 不出現」，`mcp-debug`、`che-ical-mcp:troubleshoot-tcc` 也有「permission denied」）。分工寫在這裡與 `CLAUDE.md`，不在 description 裡。`che-ical-mcp:troubleshoot-tcc` 的 Step 4 建議 `tccutil reset Calendar com.checheng.CheICalMCP`，但同一個專案的 ical#154 記載這個形式對裸 binary 會失敗（-10814，證據 E11），兩者不一致。

## 四個要知道的坑

1. **`mcp-sign-pipeline` 會無聲地覆蓋兩個檔案，而且自己 commit。** 它的 Step 3.1 無條件把專案既有的 `Entitlements.plist` 換成空的 `<dict/>`，Step 3.2 無條件蓋掉 `scripts/sign-and-notarize.sh`（「已安裝就中止」的檢查在 Step 3.3，是蓋完才做），Step 5 再自己 `git commit`，所以事後 `git diff` 看不到。這個空範本沿用的是 ical 當時「留空」的決定；ical 在 macOS 26.5.1 被系統靜默拒絕後於 #154 推翻它，範本沒跟上，ical 自訂的 sign 腳本還有範本沒有的簽後檢查閘門（證據 E16、E21、E4、E33）。**專案已經有簽章 pipeline 就不要再跑它**；沒有時，跑前先 commit，跑完用 `plutil -p` 驗值是 `=> true`。
2. **裝出來的 binary 可能是 ad-hoc。** ical 的 `make install`、pipeline 範本新建的 `install:`、`mcp-debug` 2.5.0 的重建同步，都是把新 build 簽成 ad-hoc（E23、E21、E18）。另外，對**已簽章**的 binary 再執行 `codesign --force --sign -` 會抹掉簽章身分、runtime 旗標與 entitlements（已實測，E17）。
3. **`sign-and-notarize.sh` 的 `ENTITLEMENTS` 預設值寫死 `Sources/CheICalMCP/…`**，別的專案要明確設定（E21）。
4. **Reminders 要放哪個 entitlement 不確定。** Apple 文件只列 `com.apple.security.personal-information.calendars`，沒有 `…reminders`（該文件端點 404，E25）；ical 兩把都放。以 tccd 日誌 `requires entitlement <名稱>` 裡的名稱為準。

## 需求

- macOS，Xcode Command Line Tools（`codesign`、`otool`）
- 簽章與公證需要 Developer ID 憑證與 notarytool profile，由使用者自行準備（見 `mcp-sign-pipeline`）

## 相關

- [`references/evidence.md`](references/evidence.md)：每個主張的證據與狀態
- `harness-devtools`：`mcp-sign-pipeline`、`mcp-debug`、`mcp-diagnose`
- `che-ical-mcp`：本 plugin 的做法來源
