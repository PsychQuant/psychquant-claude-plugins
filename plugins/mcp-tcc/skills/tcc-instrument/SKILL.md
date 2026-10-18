---
name: tcc-instrument
description: 把 macOS TCC 授權做進 Swift MCP/CLI（僅限 EventKit 與 Apple Events）：嵌入 Info.plist（NS*UsageDescription）、放對 entitlements、提供可行動的授權錯誤訊息，並可加 --setup／--print-tcc-path。新 MCP 要碰 EventKit 或 Apple Events、這類專案缺 Info.plist 或 entitlements、或準備跑 mcp-sign-pipeline 之前使用；授權已經卡住、要先查原因時，改用 tcc-diagnose。
allowed-tools:
  - Read
  - Grep
  - Bash(ls *)
  - Bash(grep *)
  - Bash(git status *)
  - Bash(codesign -dv *)
  - Bash(codesign -d --entitlements *)
  - Bash(otool -s *)
  - Bash(plutil -p *)
---

# tcc-instrument：把授權做進 MCP，而不是出事後才查

做法取自 `che-ical-mcp`（PR #44、#154），一般化後補上 Apple Events。出事了先用 `tcc-diagnose` 查原因；本 skill 是修，不是查。

本 skill 會修改專案檔案。frontmatter 只預先核准列出的幾個唯讀指令前綴；**寫檔、build、簽章等其他指令會跳出權限提示，那是預期的**，不要想辦法繞過 [E35]。

**往返上限**：`tcc-instrument` 與 `tcc-diagnose` 互相轉介，整個任務內最多往返一輪。第二次要轉介時停止，回報目前證據與卡在哪裡。

## Step 0：先讀證據表

先讀 `${CLAUDE_PLUGIN_ROOT}/references/evidence.md`。若這個路徑讀不到，改用載入本 skill 時顯示的 base directory 往上兩層的 `references/evidence.md`。內文每個 `[E#]` 對應那張表，狀態只有**已驗證／他人實測／類推／未驗證**四種。**macOS 27.x 的 TCC 行為沒有任何實測**；他人實測的證據各有各的環境，見證據表每一列。

## 先決警告：`mcp-sign-pipeline` 有五個會破壞成果的行為

`harness-devtools:mcp-sign-pipeline`（2.5.0）[E16][E21]。內文凡提到「pipeline 的 Step N」，指的是它自己的步驟，不是本 skill 的：

1. **pipeline 的 Step 3.1 無條件覆蓋**專案裡既有的 `Sources/{{Target}}/Entitlements.plist`，換成空的 `<dict/>`。簽章又用 `--options runtime`。ical 就是這樣出貨，在 macOS 26.5.1 被 tccd 靜默且永久地拒絕，最後在 #154 補上 entitlements [E4]。
2. **pipeline 的 Step 3.2 同樣無條件覆蓋** `scripts/sign-and-notarize.sh`。「已安裝就中止」的檢查在它的 Step 3.3，是蓋完才做。
3. **pipeline 的 Step 5 隨後自己 `git add` 並 `git commit` 這些檔**，所以**事後 `git diff` 看不到覆蓋**。
4. Makefile 範本新建的 `install:` 含 `codesign --force --sign - ~/bin/…`，裝出來的是 ad-hoc。（專案已有 `install:` 時，它只加 `rm -f`。）
5. `sign-and-notarize.sh` 的 `ENTITLEMENTS` 預設值寫死 `Sources/CheICalMCP/Entitlements.plist`，別的專案沒設就直接報錯。

所以：**專案已經有簽章 pipeline 時，不要再跑它**；沒有時，Step 3（Entitlements）要在跑它之前做好並 commit。詳見 Step 5。

## Step 1：看專案現況，再決定要加什麼

**動手前先看哪些檔案已經存在，已存在的一律合併、不覆蓋。**

```bash
ls Sources/*/Info.plist Sources/*/Entitlements.plist
grep -n -E "__info_plist|sectcreate|exclude:" Package.swift
ls scripts/sign-and-notarize.sh
grep -n -E "release-signed|install-signed" Makefile
git status --short
```

`git status` 有未提交的變動就先請使用者 commit 或備份。

偵測用了哪些受保護的 API：

```bash
# 本 plugin 涵蓋的
grep -rn --include='*.swift' -E "requestFullAccessToEvents|requestFullAccessToReminders|EKEventStore|NSAppleScript|NSAppleEventDescriptor|AEDeterminePermissionToAutomateTarget" Sources
# 本 plugin 未涵蓋的
grep -rn --include='*.swift' -E "AXIsProcessTrusted|CGWindowListCreateImage|SCStream|PHPhotoLibrary|AVCaptureDevice|CNContactStore|CLLocationManager" Sources
# 子行程呼叫 osascript：TCC 歸屬未驗證
grep -rn --include='*.swift' -E "osascript" Sources
# Apple Events 的目標 app 清單
grep -rn --include='*.swift' 'tell application' Sources
```

| 命中 | 處置 |
|---|---|
| `requestFullAccessToEvents`、`.event` | Calendar，放 Step 2、3 的 Calendar 那組 |
| `requestFullAccessToReminders`、`.reminder` | Reminders，同上 |
| `NSAppleScript`、`NSAppleEventDescriptor`、`AEDeterminePermissionToAutomateTarget` | Apple Events；目標 app 清單取自 `tell application "X"` 的 X |
| 第二個 grep 有命中 | 該服務**未涵蓋**：明說沒有一手資料、不做類推，**只跳過那個服務**，涵蓋的服務照做 |
| `osascript` 當子行程 | 這一部分停下來問使用者（TCC 歸屬未驗證），其他部分照做 |
| 有 `scripts/sign-and-notarize.sh`，或 Makefile 有 `release-signed` | 專案**已有簽章 pipeline**：Step 5 走「情況 A」，不要再跑 `mcp-sign-pipeline` |

兩個 EventKit 的命中都有，就兩組 key 都放。

## Step 2：嵌入 Info.plist

沒有 Info.plist，系統就沒有 usage description 可以顯示；`NSAppleEventsUsageDescription` 在 app 使用送出 Apple events 的 API 時為必要 [E3]。命令列 binary 沒有 `.app` 包裝，所以要用 linker 把它嵌進 Mach-O。

**已有 Info.plist 就只補缺的 key，不要覆蓋；也不要更動既有的 `CFBundleIdentifier`。**

**專案原本沒有 Info.plist 時要先告知使用者**：嵌入後，binary 的簽章 identifier 一律變成 `CFBundleIdentifier`（ical 是 `com.checheng.CheICalMCP`；這一步已實測 [E8][E30]）。TCC 的 code requirement 含 identifier，所以以舊 identifier 取得的授權可能對不上、需要重新授權。這後半是類推 [E36]；預期會發生，但要讓使用者知道。

`Sources/{{Target}}/Info.plist`（格式取自 ical [E7]；`{{…}}` 是要替換的佔位符，不是 XML 標籤）。**usage description 只放 Step 1 命中的服務**，沒用到的不要放：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleIdentifier</key>
	<string>{{反向網域前綴}}.{{Target}}</string>
	<key>CFBundleName</key>
	<string>{{Target}}</string>
	<key>CFBundleVersion</key>
	<string>{{與 --version 相同的版本}}</string>
	<!-- 只在 Step 1 命中 Apple Events 時放： -->
	<key>NSAppleEventsUsageDescription</key>
	<string>{{Target}} needs access to {{目標 App}} to {{做什麼}}.</string>
</dict>
</plist>
```

- 反向網域前綴：沿用同一人或組織其他 MCP 的前綴（本 repo 是 `com.checheng.`）；沒有可沿用的就問使用者，不要自己決定。
- EventKit 命中時，改放（或加上）對應的 `NSCalendarsFullAccessUsageDescription`、`NSCalendarsUsageDescription`、`NSRemindersFullAccessUsageDescription`、`NSRemindersUsageDescription`。
- 說明文字要寫清楚**做什麼、為什麼**，這是顯示給使用者的授權對話框文字。

`Package.swift`，在 executable target 上（照 ical 的寫法 [E7]）：

```swift
.executableTarget(
    name: "{{Target}}",
    dependencies: [ /* 原本的 */ ],
    path: "Sources/{{Target}}",
    exclude: ["Info.plist", "Entitlements.plist"],
    linkerSettings: [
        .unsafeFlags([
            "-Xlinker", "-sectcreate",
            "-Xlinker", "__TEXT",
            "-Xlinker", "__info_plist",
            "-Xlinker", "Sources/{{Target}}/Info.plist"
        ])
    ]
)
```

- `exclude` 兩個 plist 都列。ical 只排除 `Info.plist`；`Entitlements.plist` 放在同一個 target 目錄卻沒排除時，`swift build` 會印 unhandled file 警告（實跑過，只是警告）[E7]。若 `Entitlements.plist` 放在 target 目錄之外，就只需要列 `Info.plist`。
- 最後一個路徑是相對路徑，推論上要從 repo 根目錄執行 `swift build`（從寫法推得，沒有另外驗證）。
- `CFBundleVersion` 要跟 `--version` 印出的版本同步，ical 兩處是同一個數字。
- `unsafeFlags` 只放在 executable target。專案若同時有 library product（例如 `CheThingsMCPCore`），不要放進 library target。

驗證要先 build（`swift build -c release`，會跳權限提示），再：

```bash
otool -s __TEXT __info_plist <binary 路徑> | grep -c "Contents of"      # 應大於 0
```

## Step 3：Entitlements

hardened runtime 下，要放行對應的授權詢問，需要對應的 entitlement：

| 服務 | entitlement | 依據 |
|---|---|---|
| Calendar | `com.apple.security.personal-information.calendars` | Apple 文件有列 [E25]；ical#154 [E4] |
| Reminders | 兩把都放：`…calendars` 與 `com.apple.security.personal-information.reminders`（照 ical） | **Apple 文件沒有 `…reminders`**（端點 404）[E25]，ical 為什麼放它沒有證據。因此**以 tccd 日誌 `requires entitlement <名稱>` 裡的名稱為準**，日誌要求哪個就確保有哪個。Step 5 的開發簽章複本驗證，正好可以拿來取得這個日誌，不必走到公證 |
| Apple Events | `com.apple.security.automation.apple-events` | Apple 文件 [E2]；缺它時的實際失敗樣子是類推 [E5] |

Apple 文件明說：Apple Events 的 entitlement 在只傳給自己或同 team ID 的程序時不需要 [E2]。MCP 要控制 Things、Mail、Notes 這類別人的 app，就需要。即使 [E5] 還沒被實測，**有文件依據的做法是放進去**。

`Sources/{{Target}}/Entitlements.plist`。**已有這個檔案就只加缺的 key**；沒有才建立：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.automation.apple-events</key>
    <true/>
</dict>
</plist>
```

多個服務並用就全部放，不要只留一個。**值必須是 `<true/>`**。

照 ical 的做法加兩道防線，防止日後有人「清理」回空檔：

1. 在 plist 內放一段 XML 註解，寫明為什麼不能留空、引用的 issue 與 tccd 日誌（參考 ical 的 `Entitlements.plist`）。
2. 加一個 CI 測試，斷言這些 key 存在（參考 ical 的 `Tests/CheICalMCPTests/EntitlementsPlistTests.swift`）。

## Step 4：診斷入口與可行動的錯誤訊息

**最低要求**：Step 2 的 Info.plist、Step 3 的 entitlements，加上下面的「可行動的錯誤訊息」。`--setup`、`--print-tcc-path`、啟動橫幅是建議但非必要，補救任務不要擴大成實作全部。

下面的 ical 檔案在 `mcps/che-ical-mcp/Sources/CheICalMCP/` 下，可以抄結構：

| 入口 | 做什麼 | ical 的對應 |
|---|---|---|
| `--setup` | 在前景、互動環境主動要求授權；非互動環境（SSH）要直接說做不到 | `SetupRunner.swift`、`SetupAccessDecision.swift`、`NonInteractiveDetection.swift` |
| `--print-tcc-path` | 印出 binary 實際路徑、bundle id、各服務目前狀態。輸出是「執行這個指令的 context」的結果，不是 binary 的固有屬性：EventKit 在 code requirement 不符時，Terminal 讀到 `fullAccess`，失敗的 MCP context 卻可能讀回 `denied` [E10]，所以輸出旁要附這個警告 | `Version.swift`（說明文字）、`EventKit/TCCStatusFormatter.swift` |
| 每次呼叫重讀狀態 | 不要把授權結果快取成旗標，否則授權變了也看不到（ical#108 的 anti-pattern） | `AuthorizationGate.ensureAccess`、`EventKit/AuthorizationStatusSource.swift` |
| 啟動橫幅 | 每次啟動把授權狀態寫到 **stderr**（stdout 是 MCP 協定通道） | `EventKit/TCCDriftDetector.swift`（ical#122） |

### Apple Events 版

ical 用 EventKit。Apple Events 的參考實作是 che-things-mcp 1.7.0：`Sources/CheThingsMCPCore/Authorization/AutomationAuthorization.swift`（分類、報告格式、`--setup` 的步驟選擇）與 `Things/ThingsManager.swift` 的 `ThingsError.automationNotAuthorized`。它依 SDK 標頭語意 [E1] 寫成，分類、格式、`--setup` 的步驟選擇有單元測試；2026-10-18 在 macOS 27.2 實機上觀察到：從未被問過的 host 跑 `--setup` 會跳出對話框、允許後持續有效 [E43]；已授權的 host 換上新簽章的 binary 後仍有效 [E42]；授權記在 host 身上 [E41]。**macOS 26、缺 entitlement 的情況、對話框上的文字來源都沒有測**，所以下面是有參考實作與單次實機觀察的設計，不是全面驗證過的做法：

- **`--print-tcc-path`**：對 Step 1 清單中的每個目標 app 呼叫 `AEDeterminePermissionToAutomateTarget(target, typeWildCard, typeWildCard, false)`，把回傳對成人話：`noErr`＝已授權、`errAEEventNotPermitted`（-1743）＝被拒、`errAEEventWouldRequireUserConsent`（-1744）＝還沒問過、`procNotFound`＝目標 app 沒開（**不是授權問題**）。**其他 OSStatus 原樣印出數值**，不要硬翻譯。這個查詢在 code requirement 不符時是否準確未驗證 [E27]。
- **`--setup`**：同一個函式但 `askUserIfNeeded=true`。目標 app 必須已在執行，所以先檢查，沒開就請使用者先開；不要在主執行緒呼叫 [E1]。1.7.0 在狀態已是「被拒」時不再詢問，改指向 System Settings；「拒絕後不會再彈窗」是假設，沒有一手資料。把「這次該做什麼」抽成純函式（1.7.0 的 `AutomationSetup.plan`）才測得到，對話框本身測不到。
- **工具執行失敗時**：把 -1743 轉成可行動的訊息。判斷以錯誤字典的數值 `NSAppleScript.errorNumber` 為主，英文訊息只當後備 [E40]（這句文字與 -1743 的對應是類推 [E28]）。訊息至少包含：**目標 app**、**binary 的實際路徑**、**失敗發生在哪個 host**，以及修法的順序：
  1. 先看 System Settings → 隱私權與安全性 → 自動化，有沒有這個 binary 或 host 的條目、是不是關閉的；
  2. 沒有條目時，若有 `--setup`，在實際使用的終端機 app 跑 `'<Binary>' --setup`（路徑要加引號：.mcpb 的安裝路徑含空白；也不要假設是 Terminal.app）。**這可能只取得該終端機 app 歸屬的授權**，不一定涵蓋實際的 host（EventKit [E9] 與 Apple Events [E41] 都已觀察到）。沒有 `--setup` 的話，改在實際的 host 內呼叫一個讀取型工具，讓對話框出現在那個 context；
  3. 完成後回到實際的 host 內再試一次，仍失敗就用 `tcc-diagnose` 查。

  不要丟出原始的 `Not authorized to send Apple events to Things3.`，che-things-mcp#1 的使用者看到的就是那一句。

最終判準是實際送一個無害的事件：選該 MCP **現有的讀取型工具**（list／get），不要自己發明新的探測事件。

## Step 5：簽章與公證

先看 Step 1 偵測到的結果。

### 情況 A：專案已經有簽章 pipeline

**不要再跑 `mcp-sign-pipeline`。** 它的 Step 3.1、3.2 會無條件覆蓋 `Entitlements.plist` 與 `scripts/sign-and-notarize.sh`，「已安裝」的中止檢查在 Step 3.3，是蓋完才做 [E21]。專案自訂的 sign 腳本可能有模板沒有的檢查，例如 ical 在簽章後、公證前有 `[2.5/5]` 閘門，驗證簽好的 binary 兩個 key 皆為 `<true/>`，模板沒有 [E33]。

用專案自己的流程簽章，並先確認它的 sign 腳本讀的是 Step 3 的那個 `Entitlements.plist`（看腳本裡 `ENTITLEMENTS` 的預設值，可用環境變數覆蓋 [E21]）。然後接下面的「簽章共通步驟」。

### 情況 B：專案沒有簽章 pipeline

跑 pipeline **之前**：

1. 請使用者把 Step 2–3 的成果 **commit**（或經他同意後由你 commit），或複製到專案外備份。記下那個 commit 的 hash。

跑 `harness-devtools:mcp-sign-pipeline`。它**只安裝檔案，不簽章** [E33]；它的 Step 5 會自己 commit [E21]。

跑完 pipeline **之後**，立刻驗證，**不要看 `git diff`**（pipeline 已自己 commit，看不到差異）：

2. `plutil -p Sources/{{Target}}/Entitlements.plist`：Step 3 的每個 key 後面都要是 `=> true` [E34]。是空的、少 key、或值是 `false`，就用 `git checkout <先前記下的 commit> -- Sources/{{Target}}/Entitlements.plist` 還原，並請使用者另外 commit 這次還原。
3. 也檢查 pipeline 新建的 Makefile `install:`：裡面的 ad-hoc 簽只該用於開發迭代，見最後一節。

### 簽章前先確認被簽的是新 binary

簽章與公證不可逆，而且不會告訴你被簽的是不是這次的程式碼。che-things-mcp 1.7.0 的 review 抓到兩個會讓舊成品冒充新版的陷阱，兩個都在簽章**之前**擋掉：

- **逐個 `--arch` build 再 `lipo`**：`swiftbuild` 下所有 `--arch` 寫同一個目錄，舊路徑 `.build/<arch>-apple-macosx/release` 留著舊 binary [E37]。改成一次 `swift build -c release --arch arm64 --arch x86_64`，用 `--show-bin-path` 找產物，並對每個 slice（`lipo -thin`）檢查：版本字面（`strings` 找得到 `Version.swift` 的值）、新碼的特徵字串、`otool -s __TEXT __info_plist` 有內容。
- **`mcpb pack` 沒給輸出路徑**：輸出檔以資料夾名命名，腳本報告的檔案可能是舊檔 [E38]。用 `mcpb pack . <輸出檔>`，打包前先刪舊檔，打包後用 `unzip -p … | cmp` 確認包內 binary 就是剛驗證過的那個。

### 簽章共通步驟（情況 A、B）

模板的簽章與公證是同一支腳本、中間沒有檢查點 [E33]，所以**先在複本上做開發簽章並驗證，通過了才公證**：

4. **開發簽章複本**：把 build 好的 binary 複製到暫存位置（不要動 `~/bin`），用 Developer ID 加 runtime 加 `--entitlements Sources/{{Target}}/Entitlements.plist` 簽那份複本。這會動用使用者的簽章憑證，**先問使用者**，由他執行或同意。專案若已有 `install-signed` 這類開發簽章路徑（ical 有 [E23]），直接用它。
5. **驗證，這就是閘門。** 對簽好的複本（或 `install-signed` 裝出來的 binary）執行：
   ```bash
   codesign -dv <複本路徑> 2>&1 | grep -E "Signature|TeamIdentifier|flags|Identifier="
   codesign -d --entitlements - <複本路徑> 2>&1
   ```
   **通過的條件，三項都要成立**：(a) `flags` 含 `runtime`，且有 `TeamIdentifier`；(b) entitlements 列出 Step 3 的每個 key，值皆為 `true`；(c) 步驟 2 的 `plutil -p` 也是 `=> true`。任何一項不成立，就停止，不要公證。
6. **公證**：會把 binary 上傳到 Apple 的服務、耗時數分鐘，**執行前先問使用者**。Developer ID 憑證與 notarytool profile 是使用者自己準備的，不替他申請或建立；`DEVELOPER_ID` 與 `NOTARY_PROFILE` 由他提供。實際指令要在**同一次呼叫**裡設定環境變數，下一次呼叫會消失：
   ```bash
   DEVELOPER_ID=<使用者提供> NOTARY_PROFILE=<使用者提供> ENTITLEMENTS=<Entitlements.plist 的絕對路徑> make release-signed
   ```
   簽章與公證的鏈是 `make release-signed` → build 腳本的 `[3.5/N]` 步驟 → `scripts/sign-and-notarize.sh` [E33]。`ENTITLEMENTS` 用絕對路徑，避免依賴 build 腳本的工作目錄。

公證完成後，對最後出貨的 binary 再跑一次步驟 5 的兩個指令。**公證本身用 `spctl --assess --type install`、`codesign --verify --strict -R="notarized" --check-notarization` 與 `notarytool info` 驗證**；`--type execute` 對裸 CLI binary 一律回 `rejected (… does not seem to be an app)`，那不是公證失敗 [E39]。最好從公開網址把 release 資產下載到新目錄再驗，確認拿到的就是簽好的那一份。

**已知缺口**：`mcp-sign-pipeline` 的 Step 3.1／3.2／5、Makefile 範本與預設路徑仍是上面的樣子 [E21]，其他專案套用會重蹈 ical#154。這要改在 `harness-devtools`，不在本 plugin 範圍；請使用者決定是否回報。

## 會讓 binary 變回 ad-hoc 的操作

兩件事不同，都要避免：

1. **安裝路徑把新 build 簽成 ad-hoc。** ical 的 `make install` [E23]、pipeline 範本新建的 `install:` [E21]、`mcp-debug` 2.5.0 的「重建後同步」[E18] 都是這樣：build 出新 binary，再用 `codesign --force --sign -` 簽。裝到 `~/bin` 的因此是 ad-hoc，沒有 TeamID、沒有 runtime、沒有 entitlements，等於 Step 2–5 白做。本機要裝簽好的版本，用類似 ical `install-signed` 的路徑：Developer ID 加 `--options runtime` 加 `--entitlements`，**未公證、僅供開發** [E23]。
2. **對已簽章的 binary 再 ad-hoc 重簽。** 實測會把 Developer ID 身分、runtime 旗標、entitlements 全部清掉 [E17]。

做完任何安裝或重建，都用步驟 5 的兩個指令確認簽章與 entitlements 還在。

## Step 6：驗證

1. `otool`、`codesign`、`plutil` 都對（Step 2、5）。
2. 請使用者觸發授權：binary 有 `--setup` 就在 **Terminal.app** 跑 `<Binary> --setup`，對話框按 Allow；沒有 `--setup` 就在實際 host 內呼叫一個讀取型工具，讓對話框出現。
3. 再從實際的 host（Claude Code 或 Claude Desktop）內，用**讀取型**工具呼叫一次。Terminal 授權的 responsible process 是 Terminal，不一定涵蓋 host（EventKit 已觀察到 [E9]）。
4. **換簽章身分後**（ad-hoc → Developer ID），舊的授權 row 可能綁在舊簽章上。這在 EventKit 已觀察到：entitlement 缺時，`--setup` 不彈窗，日誌出現 `Failed to match existing code requirement` [E4]；而且 code requirement 不符時，只在 Terminal 跑 `--setup` 會 no-op [E24]。entitlement 到位後預期會重新彈窗，但未驗證 [E13]。Apple Events 的 host 層授權在換簽章後仍有效 [E42]，binary 層沒有證據 [E31]。發生時轉介 `tcc-diagnose` 的 Step 4、5（受上面的往返上限限制）。
5. 若觀察到新證據，例如 Apple Events 的 tccd 日誌或 healing 結果，把原文貼給使用者，請他在 `psychquant-claude-plugins/plugins/mcp-tcc/references/evidence.md` 回填 E5 或 E13。**不要改 plugin cache 內的檔案**，也不要自己升級證據狀態。

## 不做的事

- 不申請 Developer ID 憑證、不建立 notary profile。
- 不替使用者按授權對話框。
- 不 push、不發 release；那是各 MCP 專案自己的流程。
- 不在沒問過使用者的情況下動用簽章憑證或執行公證。
