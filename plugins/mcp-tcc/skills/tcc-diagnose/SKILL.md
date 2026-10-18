---
name: tcc-diagnose
description: 診斷 Swift MCP / CLI 的 macOS TCC 授權問題，只涵蓋 EventKit（Calendar／Reminders）與 Apple Events（Automation）。工具回報「Not authorized to send Apple events」(-1743)、-1744、Calendar 或 Reminders access denied、授權對話框不彈出、換簽章後失效、status 顯示已授權卻仍被拒時使用。只診斷，不替使用者按授權或重置。
allowed-tools:
  - Read
  - Grep
  - Bash(codesign -dv *)
  - Bash(codesign -d --entitlements *)
  - Bash(otool -s *)
  - Bash(pgrep *)
  - Bash(ps *)
  - Bash(ls *)
  - Bash(grep *)
  - Bash(sw_vers *)
  - Bash(/usr/bin/log show *)
  - Bash(sqlite3 -readonly -safe *)
---

# tcc-diagnose：MCP 的 macOS 授權卡住時，怎麼一層一層查

做法取自 `che-ical-mcp` 的 `troubleshoot-tcc`，一般化到任何 Swift MCP，並補上 Apple Events。

## Step 0：先讀證據表

先讀 `${CLAUDE_PLUGIN_ROOT}/references/evidence.md`。若這個路徑讀不到，改用載入本 skill 時顯示的 base directory 往上兩層的 `references/evidence.md`。內文每個主張後面的 `[E#]` 對應那張表，狀態只有**已驗證／他人實測／類推／未驗證**四種。**回報時把狀態一起帶上，不要把類推說成事實。**

版本：他人實測的證據各有各的環境，見證據表每一列。**macOS 27.x 的 TCC 行為沒有任何實測。** 先用 `sw_vers` 記下使用者的版本，回報時一併寫出。

## 行為界線

這個 skill **只讀取與診斷**。frontmatter 只預先核准列出的幾個指令前綴（已盡量收緊，例如 `sqlite3` 限定 `-readonly -safe`）；其他指令會跳出權限提示，那是預期的，不要想辦法繞過 [E35]。

- **Claude 不做**：按授權對話框、切換 System Settings、執行任何形式的 `tccutil reset`、改 `TCC.db`。這些要請使用者自己做，並明說「請你…」。
- **`tccutil reset` 完全不建議**：帶 bundle id 的形式對裸 binary 會失敗，或顯示成功卻 no-op [E11]；不帶 bundle id 的形式會重置該服務下**所有** app 的授權 [E29]。使用者堅持要用時，說明這兩個風險，由使用者自己執行。
- **查 `TCC.db`** 只能用 `sqlite3 -readonly -safe`，且先 `.schema access` 看欄位，Automation 列的目標欄位名不要憑記憶寫 [E20]。需要 Full Disk Access；開不起來是查詢者的 shell 缺權限，不代表沒授權 [E15]。
- **驗證時呼叫 MCP 工具**：只用讀取型（list／get／search）。**不用 create／update／delete 類工具探測**；需要寫入驗證時，先問使用者。
- **範圍是封閉的，只有兩項**：EventKit（Calendar／Reminders）與 Apple Events（Automation）。其餘一律是「本 plugin 未涵蓋」：Accessibility、Full Disk Access、Photos、麥克風、相機、Contacts、Location、Screen Recording、Files & Folders，以及 Keychain／API token 這類憑證授權。遇到就說明沒有一手資料、不做類推；可以請使用者查 Apple 文件，但不要給具體修法。
- **`osascript` 子行程**：若 -1743 來自 MCP 用 `Process` 呼叫的 `osascript`，TCC 把授權算在哪個 client 沒有證據。先問使用者，不要直接歸給 MCP 的 binary。
- **往返上限**：`tcc-diagnose` 與 `tcc-instrument` 互相轉介，**整個任務內最多往返一輪**。第二次要轉介時停止，回報目前證據與卡在哪裡，不要再繞。

## Step 1：先分出是哪個 TCC 服務

**先確認這個 MCP 實際用到哪些受保護的 API**：讀它的原始碼（grep 指令見 `tcc-instrument` 的 Step 1），或問使用者。只用到 EventKit 或 Apple Events 才繼續；出現上面「未涵蓋」的服務，就對那一項說明沒涵蓋，其餘照做。確認之後再對症狀：

| 症狀 | 先看 |
|---|---|
| `Not authorized to send Apple events to <App>` | Automation。這句文字常對應 OSStatus **-1743**，但這個對應是類推 [E28]；授權是針對特定目標 app 的 [E1] |
| OSStatus **-1743** | Automation，被拒 [E1] |
| OSStatus **-1744** | Automation，還沒被問過，且當下不允許彈窗 [E1] |
| `procNotFound`、目標 app 沒開 | **不是授權問題** [E1] |
| 「access denied」類錯誤，且確認用的是 EventKit | Calendar／Reminders。ical 的字串是 `accessDenied`／`insufficientAccess`／`unknownAuthState`，那是 ical **自己的** enum，別的 MCP 字串不同 [E22] |
| 授權對話框從頭到尾不彈出 | 確認服務之後直接 Step 3、4 |
| 換簽章或升級之後突然失效 | Step 3、4。EventKit 已觀察到 [E4]；Apple Events 沒有證據 [E31] |
| status 或 `--print-tcc-path` 顯示已授權，工具卻被拒 | EventKit 已觀察到，且**取決於讀取時的 context** [E10]；Apple Events 有沒有同樣盲點未驗證 [E27]；到 Step 4 |

Automation 的 TCC 服務鍵一般稱 `kTCCServiceAppleEvents`，但本機沒有看到過，未驗證 [E32]；`tccutil` 的短名 `AppleEvents` 是否有效也沒驗證 [E19]，所以本 skill 不使用它。

## Step 2：找出失敗的是哪個 binary、哪個 host

同一個 MCP 常有兩個互相獨立的安裝，各有各的授權：Claude Code（wrapper，`~/bin/<Binary>`）與 Claude Desktop（`.mcpb`）。授權一個不會涵蓋另一個。

```bash
pgrep -fl <Binary>                                                                 # 正在跑的實例
ls -l ~/bin/<Binary>                                                               # Claude Code
ls -d ~/Library/Application\ Support/Claude/Claude\ Extensions/*/server/<Binary>   # Claude Desktop
```

**要在失敗的 host 內重現與取證。** 你目前所在的 session 若不是那個 host（例如失敗的是 Claude Desktop，而你在 Claude Code），請使用者在那個 host 內操作並把結果貼回來，不要在這裡替代。在別的 context 讀到的狀態不能用來判斷失敗的 host [E10]。

授權可能有**兩層**：binary 自己，以及實際發出請求的 responsible process。這是 EventKit 的實測 [E9]；Apple Events 是否同樣適用屬類推 [E26]。Claude Desktop 是例外，它的 binary 自己就是 responsible process [E9]，這個例外同樣只有 EventKit 的證據。

追 host 身分。`<pid>` 取 `pgrep` 結果中祖先鏈與失敗 host 吻合的那一個，有多個又分不出來就問使用者。下面這個迴圈是複合指令，不在預先核准範圍內，會跳權限提示：

```bash
P=<pid>; while [ -n "$P" ] && [ "$P" -gt 1 ] 2>/dev/null; do ps -o pid=,ppid=,comm= -p "$P"; P=$(ps -o ppid= -p "$P" | tr -d ' '); done
```

判斷順序（先排除再判）：

1. 鏈上有 Terminal 或 VS Code → 是那個 app 的 context，即使 binary 是 `.mcpb` 路徑也一樣（從 Terminal 手動跑 `.mcpb` binary 的情況）。
2. 鏈上有 `claude/versions/<版本>` → Claude Code。
3. 以上都沒有，且 binary 是 `.mcpb` 路徑 → 判為 Claude Desktop（靠「沒有」判斷，不是直接觀察 [E9]）。
4. Cursor、launchd 等其他 host **沒有資料** [E9]，不要硬判，問使用者。

**當同一個 binary 在某些 context 能用、某些不能用**，才用 toggle-and-observe 找出關鍵條目。請使用者：(1) 先確認有一個 context 是正常的；(2) 一次只關掉**一個**條目；(3) 在失敗的 host 內重跑工具；(4) 記錄有沒有壞；(5) 開回去確認恢復，再換下一個。關掉會壞的那個，就是關鍵條目。

## Step 3：簽章、entitlements、Info.plist 是否到位（最常見的根因）

每個指令各自獨立執行，直接寫出 binary 路徑，不要用變數：

```bash
codesign -dv <binary 路徑> 2>&1 | grep -E "Signature|TeamIdentifier|flags|Identifier="     # 簽章型態、runtime、identifier
codesign -d --entitlements - <binary 路徑> 2>&1                                          # entitlements（空輸出 = 沒有）
otool -s __TEXT __info_plist <binary 路徑> | grep -c "Contents of"                        # 0 = 沒嵌 Info.plist
```

三個指令在 Developer ID 簽章的 ical 與 ad-hoc 簽章的 things 上輸出不同，可以分辨 [E8]。

| 讀到 | 意義 |
|---|---|
| `Signature=adhoc`、`TeamIdentifier=not set` | ad-hoc。他人實測 macOS 26 上無法新建授權 [E6]（既有授權可能仍有效）。專案明明簽過、`~/bin` 的卻是 ad-hoc，要查是怎麼裝上去的：ical 的 `make install` 就是把新 build 簽成 ad-hoc（要裝 Developer ID 簽的開發版用 `make install-signed`，未公證；公證散布走 `release-signed`）[E23]；`mcp-sign-pipeline` 範本新建的 `install:` 同樣如此 [E21]；`mcp-debug` 的重建同步也是 [E18]。另外，對**已簽章**的 binary 再執行 `codesign --force --sign -` 會抹掉簽章與 entitlements [E17] |
| `flags=...(runtime)` 且 entitlements 空 | **高風險組合**。hardened runtime 缺對應 entitlement 時，tccd 可能直接不彈窗：Calendar 在 macOS 26.5.1 有一次日誌樣本 [E4]；Apple Events 是類推 [E5] |
| `otool` 計數為 0 | 沒嵌 Info.plist，沒有 usage description；`NSAppleEventsUsageDescription` 在使用 Apple Events API 時為必要 [E3] |
| `Identifier=` 是 `<名稱>-<一串 hash>` | 沒有 Info.plist 時的預設 identifier。嵌入 Info.plist 後**推測**會變成 `CFBundleIdentifier`，既有授權可能因此對不上（類推）[E30] |

各服務該有的 key：

| 服務 | Info.plist | hardened runtime 下的 entitlement |
|---|---|---|
| Calendar | `NSCalendarsFullAccessUsageDescription`、`NSCalendarsUsageDescription` | `com.apple.security.personal-information.calendars` [E7][E4] |
| Reminders | `NSRemindersFullAccessUsageDescription`、`NSRemindersUsageDescription` | **不確定。** Apple 文件只列 `…calendars`，沒有 `…reminders` [E25]；ical 兩把都放。**以 tccd 日誌 `requires entitlement …` 裡的名稱為準**（Step 4） |
| Apple Events | `NSAppleEventsUsageDescription` [E3] | `com.apple.security.automation.apple-events` [E2]（只傳給自己或同 team ID 的程序時不需要） |

> 若這個 binary 是用 `harness-devtools:mcp-sign-pipeline` 的範本簽的，特別看 entitlements：範本是空的 `<dict/>`，簽章又用 `--options runtime`，pipeline 還會無條件覆蓋既有檔案並自動 commit [E16][E21]。

## Step 4：讀 tccd 日誌（最直接的證據）

在**重現失敗之後**讀。**一定要用 `/usr/bin/log`**：zsh 內建的 `log` 會讓指令直接失敗 [E14]。

```bash
/usr/bin/log show --last 5m --predicate 'process == "tccd"' --style compact | grep -i -E "<Binary>|Prompting policy|Policy disallows|requires entitlement|Failed to match"
```

查不到東西時，不要下結論：請使用者在你下指令**之前**重現一次失敗，再把 `--last` 放寬到 15m 重查；仍沒有，就是「沒有取得日誌證據」，照實回報，不要當成「沒問題」。

| 日誌 | 意義 |
|---|---|
| `Prompting policy for hardened runtime; service: kTCCService… requires entitlement <名稱> but it is missing` ＋ `Policy disallows prompt` | 缺 entitlement，系統根本不會問使用者。**要放的就是日誌裡寫的 `<名稱>`** |
| `Failed to match existing code requirement for subject …`（在 ical#154 的樣本中，前面還有一行 `SecStaticCodeCheckValidity … status: -67050`） | 既有的授權 row 綁在舊簽章，換簽章後對不上 |

這四行是 ical#154 中 **Calendar** 的連續日誌，只有一次樣本 [E4]。Apple Events 與 Reminders 的日誌長相沒看過；若看到不同的內容，原文貼給使用者。

## Step 5：下一步（依 Step 3、4 的發現決定，動作都是使用者的）

下表「交給 `tcc-instrument`」時，步驟編號一律指 **`tcc-instrument` 自己的** Step：

| 發現 | 做什麼 |
|---|---|
| hardened runtime 缺 entitlement，或沒嵌 Info.plist | 交給 `tcc-instrument`：**先**用它的 Step 2–3 補好檔案，**再**用它的 Step 5 簽章，順序不可顛倒。補齊之前，不要請使用者移除任何授權條目，否則可能變成沒有條目、也沒有對話框 [E4] |
| ad-hoc 簽章 | 交給 `tcc-instrument` 的 Step 1–5，同樣先 Step 3（entitlements）再 Step 5（簽章） |
| 簽章、entitlements、Info.plist 都到位，但日誌是 `Failed to match existing code requirement` | 既有 row 綁在舊簽章。**這條路沒有實證**：先告訴使用者可能卡住的風險。請使用者到 System Settings → 隱私權與安全性 → 對應服務窗格處理那個舊條目；這些窗格能不能單獨移除條目沒有資料（證據表「還沒有證據」一節），能移除就移除，不能就關閉再開啟，並照實回報結果。然後觸發重新授權：binary 有 `--setup` 就在 Terminal.app 跑（Terminal 授權不一定涵蓋 host [E9]）；沒有就在實際 host 內呼叫一個讀取型工具。不先處理舊條目就單獨跑 `--setup`，EventKit 已觀察到會 no-op [E24]。entitlement 到位時預期會重新彈窗，但未驗證 [E13]；Apple Events 的舊 row 是否也會失效同樣沒證據 [E31]。**仍不彈窗就停止，回報日誌，不要建議 `tccutil`** |
| 一切到位、日誌也沒有拒絕訊息 | 回 Step 2，**最多一次**。仍定位不出就停止，依「不是 TCC 的情況」回報目前證據 |
| 其他 | 照實回報，不猜 |

對話框只在**前景、互動**的環境彈出（Terminal.app 直接跑 `--setup`）；SSH 或非互動 shell 不會彈。

## Step 6：驗證

- 在**失敗的那個 host 內**，用一個**讀取型**工具實際呼叫一次，以真實結果為準。
- 不要只信 status API 或 `--print-tcc-path`：EventKit 在 code requirement 不符時，Terminal 這類 context 仍回 `fullAccess`，而失敗的 MCP context 可能讀回 `denied`，兩者不同 [E10]。所以**在 Terminal 看到「已授權」不代表失敗的 host 沒問題**。Apple Events 有沒有同樣的現象未驗證 [E27]。

## 不是 TCC 的情況

- `procNotFound`：目標 app 沒開 [E1]。
- 在失敗 host 內的讀取型呼叫成功，但別處失敗：是 context 問題，回 Step 2（遵守上面「最多一次」）。
- 授權、簽章、日誌看起來都乾淨卻仍失敗：**可能**是工具本身的 bug，但 Apple Events 的日誌長相和 status 盲點都沒驗證 [E5][E27]，所以先確認 Step 4 真的取得了日誌證據，再下這個結論。回報時附 Step 1–4 的輸出。

## 回報格式

一張表：服務｜macOS 版本｜binary 與 host｜簽章／runtime／identifier／TeamID｜entitlements｜Info.plist｜tccd 證據｜建議動作。每一列註明狀態（已驗證／他人實測／類推／未驗證）。

**不要修改 plugin cache 內的 `evidence.md`**（更新就會消失）。觀察到新證據時，例如 Apple Events 的 tccd 日誌，把原文貼給使用者，請他在 `psychquant-claude-plugins/plugins/mcp-tcc/references/evidence.md` 回填 E5 或 E13。狀態由維護者升級，不是執行者自己升級。
