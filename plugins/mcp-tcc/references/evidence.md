# 證據表：這個 plugin 的每個主張憑什麼成立

兩個 skill 用 `[E#]` 引用這張表。**修改 skill 裡的主張時，先改這裡的狀態。**

- 驗證日：2026-10-18
- 驗證機器：macOS 27.2（26B5112a）。**macOS 27.x 的 TCC 行為沒有任何實測。** 本機實跑的 E8、E14、E15、E17、E34 是指令輸出，不是 TCC 行為的觀察。下表所有「他人實測」都不是在這個版本上觀察的。

狀態只有四種，**封閉列舉，不要自己發明第五種**，也不要用括號補充改變狀態（要補充寫在「依據」欄）。一個主張如果一部分是實測、一部分是類推，就拆成兩列：

| 狀態 | 意思 |
|------|------|
| **已驗證** | 本 plugin 作者在驗證機器上讀到一手來源（SDK 標頭、Apple 文件原文、官方文件、man page、原始碼、實跑指令） |
| **他人實測** | 來自 issue 或程式碼註解裡附有證據的實測，本機未重現 |
| **類推** | 由已驗證的事實推得，沒有直接觀察到 |
| **未驗證** | 有人這樣說，或預期會這樣，但沒有一手證據 |

## 表

| # | 主張 | 狀態 | 依據 |
|---|------|------|------|
| E1 | `AEDeterminePermissionToAutomateTarget(target, class, id, askUserIfNeeded)`：已獲准回 `noErr`；被拒回 `errAEEventNotPermitted`（-1743，標頭註解：「the target of the AppleEvent does not allow this sender to execute this event」）；目標 app 沒在執行回 `procNotFound`；尚未被問過且不允許彈窗時回 `errAEEventWouldRequireUserConsent`（-1744）——不允許彈窗指 `askUserIfNeeded=false`，或事件帶 `kAEDoNotPromptForUserConsent` 旗標。對象是**特定目標 app**。目標必須是執行中的 app；不要在主執行緒呼叫（等使用者同意時可能很久）。`eventClass`／`eventID` 傳 `typeWildCard` 可一次判斷「是否所有事件都允許」 | 已驗證 | 本機 Xcode SDK 的 `CoreServices.framework/.../AE.framework/Headers/AppleEvents.h`：-1743 在約第 104 行、-1744 在約第 366 行、旗標常數在約第 373 行。標頭註解把旗標拼成 `kAEDoNotPromptForPermission`，實際定義的常數是 `kAEDoNotPromptForUserConsent`。`procNotFound` 的數值未查 |
| E2 | `com.apple.security.automation.apple-events` 表示 app **可否彈出**「允許送 Apple events 給其他 app」的詢問；只傳給自己或同 team ID 的程序時不需要。在 Xcode 是 Hardened Runtime → Resource Access → Apple Events | 已驗證 | Apple 文件 JSON 端點 `developer.apple.com/tutorials/data/documentation/bundleresources/entitlements/com.apple.security.automation.apple-events.json`。文件頁本身是 JS 渲染，WebFetch 只拿得到標題 |
| E3 | `NSAppleEventsUsageDescription`：app 使用會送出 Apple events 的 API 時，這個 key 為必要 | 已驗證 | 同上網域 `.../information-property-list/nsappleeventsusagedescription.json` |
| E4 | hardened runtime 的 binary 缺少對應的 `personal-information.*` entitlement 時，tccd 不彈授權對話框、直接拒絕，而且是靜默且永久的。**只在 Calendar 觀察到**，環境 macOS 26.5.1 | 他人實測 | ical#154 的 tccd 日誌，同一次失敗呼叫的連續四行：`SecStaticCodeCheckValidity() … identifier "…" and anchor apple generic … cdhash H"…" or cdhash H"…"; status: -67050` → `Failed to match existing code requirement for subject …CheICalMCP and service kTCCServiceCalendar` → `Prompting policy for hardened runtime; service: kTCCServiceCalendar requires entitlement com.apple.security.personal-information.calendars but it is missing` → `Policy disallows prompt … access to kTCCServiceCalendar denied`。**單一樣本**。**版本注意**：ical 的 `Entitlements.plist` 註解與 `mcp-sign-pipeline` 都記載，空 entitlements 在 macOS 26.4.1 上端到端可用，policy 是隨後收緊的。Reminders 的拒絕日誌沒有看到（該 row 當時是健康的） |
| E5 | 同一個 policy 也適用 Apple Events：hardened runtime 缺 `automation.apple-events` ⇒ 不彈窗 | 類推 | 由 E2 加 E4 推得。**沒有任何 Apple Events 的 tccd 日誌**。第一個簽章後的 Apple Events binary 出貨時要實測，結果由維護者回填這一列 |
| E6 | ad-hoc 簽章的 binary 在 macOS 26 無法**新建**TCC 授權（觸發不了對話框） | 他人實測 | harness-devtools `mcp-sign-pipeline` 的描述（來自 ical PR #44）與 che-things-mcp#4（寫「macOS 26.4.1+」）。**邊界**：ical 的 `openspec/changes/archive/2026-06-23-foreground-setup-tcc/proposal.md` 記載使用者回報，未簽章的 v1.7.0 在 macOS 26.5.1 + Claude Desktop「至今可用」，簽章後的 v1.7.1 起 Calendar 才被靜默拒絕——推測是既有授權仍有效，所以本列只指新建授權。本機未重現 |
| E7 | 把 Info.plist 嵌進 Mach-O：`-Xlinker -sectcreate -Xlinker __TEXT -Xlinker __info_plist -Xlinker <路徑>`，並在 target 加 `exclude: ["Info.plist"]`。EventKit 的 key 組是 `NSCalendarsFullAccessUsageDescription`、`NSCalendarsUsageDescription`、`NSRemindersFullAccessUsageDescription`、`NSRemindersUsageDescription`，另加 `CFBundleIdentifier`／`CFBundleName`／`CFBundleVersion` | 已驗證 | che-ical-mcp 的 `Package.swift` 與 `Sources/CheICalMCP/Info.plist`；出貨的 `~/bin/CheICalMCP` 用 `otool -s __TEXT __info_plist` 讀得到內容。ical 只排除 `Info.plist`，同目錄的 `Entitlements.plist` 沒有排除，**為什麼要排除沒有查證** |
| E8 | 下面三個診斷指令能分辨簽章狀態：`codesign -dv`、`codesign -d --entitlements -`、`otool -s __TEXT __info_plist` | 已驗證 | 在 `~/bin/CheICalMCP`（Developer ID、`flags=0x10000(runtime)`、`Identifier=com.checheng.CheICalMCP`、有兩項 entitlement、有 Info.plist）與 `~/bin/CheThingsMCP`（`adhoc`、`Identifier=CheThingsMCP-<hash>`、`TeamIdentifier=not set`、entitlements 空、沒有 `__info_plist` 內容）上實跑，輸出不同 |
| E9 | 授權可能有兩層：binary 本身，以及實際發出請求的 responsible process（host app）。**Claude Desktop 例外**：它用 disclaimer 隔離，`.mcpb` 的 binary 自己就是 responsible process，不需要 host 層條目。Claude Code 的 host 層條目是版本號 binary，路徑隨更新輪替。從 Terminal 跑 `--setup` 建立的授權，responsible process 是 Terminal，不一定涵蓋 Claude Code。**只有 EventKit 的證據** | 他人實測 | ical#168 與其 `troubleshoot-tcc` skill（含「完全打通授權 checklist」第 1 步的註記）。已知 host 只有 Claude Code、Claude Desktop、Terminal／VS Code；Cursor、launchd 等其他 host 沒有資料。環境版本未記載 |
| E10 | EventKit 的 `authorizationStatus(for:)` 在 code requirement 不符時，結果**取決於執行的 context**：在 Terminal 之類的 context 仍回 `fullAccess`（所以 status API 與 `--print-tcc-path` 會報綠），在失敗的 `.mcpb` MCP context 則讀回 `.denied`。真正的拒絕發生在 access 時。只有 EventKit | 他人實測 | **兩個來源對失敗 context 的描述不同，這裡都記。** ical#154 原報告：per-call gate 與 `--print-tcc-path` 都是綠的。ical `EventKitManager.swift` 約第 178–191 行（引用 #158）：失敗的 MCP context 在 gate 讀回 `.denied`，Terminal 的 `--setup`／`--cli` 看到「說謊的 `.fullAccess`」。可用的結論只有一個：**在別的 context 讀到的狀態，不能用來判斷失敗的 host** |
| E11 | `tccutil reset <服務> <bundle-id>` 對沒向 LaunchServices 註冊的裸 binary 會失敗：`No such bundle identifier ... OSStatus error -10814` | 他人實測 | ical#154 的 erratum。本機用不存在的 bundle id 重現了同一個錯誤**格式**，但沒有對真實 binary 測，因為成功時會真的重置那個授權。**ical 自己的 `plugin/CLAUDE.md`（約第 69 行）與 `troubleshoot-tcc`（約第 115 行）說的是另一種失敗**：對以路徑為 key 的 `.mcpb` 條目，同一指令「可能顯示成功但實際 no-op」。兩種說法並存，共同點是 tccutil 對這類條目不可靠。環境版本未記載 |
| E12 | `tccutil` 以 `kTCCService%s` 組服務名 | 已驗證 | `strings /usr/bin/tccutil` 看到格式字串 |
| E13 | 加 entitlement 重簽後，第一次存取會重新彈窗；核准後 row 改寫成 Developer ID requirement，之後升級不再失效 | 未驗證 | ical#154 的預期修法。該 issue 關閉時，「實機 healing 驗證」被列為後續項目，本 plugin 作者沒有看到驗證證據 |
| E14 | `/usr/bin/log show --last 5m --predicate 'process == "tccd"' --style compact` 能讀到 tccd 日誌；zsh 內建的 `log` 會讓直接打 `log ...` 失敗（`too many arguments`） | 已驗證 | 本機實跑；`type log` 回 `log is a shell builtin` |
| E15 | 讀 `~/Library/Application Support/com.apple.TCC/TCC.db` 需要 Full Disk Access | 已驗證 | 本機 `sqlite3 -readonly` 開檔失敗（無 FDA）；ical skill 同樣註記 |
| E16 | `mcp-sign-pipeline` 的 `templates/Entitlements.plist` 是空的 `<dict/>`，`sign-and-notarize.sh` 用 `--options runtime`。ical 已在 #154 推翻「留空」的決定 | 已驗證 | harness-devtools 2.5.0 的 `templates/Entitlements.plist` 與 `templates/sign-and-notarize.sh` 第 90 行 |
| E17 | 對已用 Developer ID 簽章、有 runtime 旗標與 entitlements 的 binary 執行 `codesign --force --sign -`，結果是 `Signature=adhoc`、`TeamIdentifier=not set`、runtime 旗標消失、entitlements 歸零 | 已驗證 | 2026-10-18 在 `~/bin/CheICalMCP` 的**暫存副本**上實跑：重簽前 `flags=0x10000(runtime)`、TeamID `6W377FS7BS`、2 項 entitlement；重簽後 `flags=0x2(adhoc)`、無 TeamID、0 項。原檔未動，副本已刪 |
| E18 | `harness-devtools` 2.5.0 的 `mcp-debug` 有三處與本 plugin 的結論不一致：(1) B3 寫「要授權的是 IDE，不是 binary」，Claude Desktop 對應「Claude」，但 E9 記載 Desktop 的 binary 自己就是 responsible process；(2) B3 用不帶 bundle id 的 `tccutil reset Calendars`／`Reminders`，依 E29 會影響該服務下所有 app，且服務名拼法（`Calendars`）與 ical 用的（`Calendar`）不同，哪個被 tccutil 接受未驗證；(3) 「重建後同步」流程把新 build 的 binary 用 `codesign --force --sign -` 簽成 ad-hoc 再裝到 `~/bin`，裝出來的是 ad-hoc | 已驗證 | `~/.claude/plugins/cache/che-plugin-devtools/harness-devtools/2.5.0/skills/mcp-debug/SKILL.md` 的 B3 與「重建後同步」段落。這是在該版本讀到的內容，之後版本可能已改 |
| E19 | `AppleEvents` 是 `tccutil reset` 接受的服務名 | 未驗證 | tccutil 先驗 bundle id；用不存在的 bundle id 配 `Bogus` 當對照組，得到與 `AppleEvents` 完全相同的錯誤，分辨不出。`man tccutil` 的範例用 `AddressBook`、`All` 這類名稱。要驗證就得對真實 app 執行，會真的重置授權，所以沒做 |
| E20 | TCC.db `access` 表中，Automation 列用哪個欄位記錄目標 app（常聽到 `indirect_object_identifier`） | 未驗證 | 本機無 FDA，開不了資料庫。skill 一律要求先 `sqlite3 -readonly -safe … ".schema access"` 再查 |
| E21 | `mcp-sign-pipeline` 有五個會破壞成果的行為：(1) Step 3.1 **無條件**把空的 `templates/Entitlements.plist` `cp` 到專案；(2) Step 3.2 同樣**無條件**把模板的 `sign-and-notarize.sh` `cp` 到 `scripts/`，蓋掉專案自訂的版本；「已安裝就中止」的檢查在 Step 3.3，是蓋完之後才檢查；(3) Step 5 隨後自己 `git add` 這些檔並 `git commit`，commit 訊息稱「empty `<dict/>`… no entitlement keys needed」，所以**事後 `git diff` 看不到覆蓋**；(4) Makefile 範本的 `install:` 含 `codesign --force --sign - ~/bin/…`，但只在 pipeline 新建該 target 時；專案已有 `install:` 時它只加 `rm -f`；(5) `sign-and-notarize.sh` 的 `ENTITLEMENTS` 預設值寫死 `Sources/CheICalMCP/Entitlements.plist`，檔案不存在時直接報錯 | 已驗證 | harness-devtools 2.5.0 `skills/mcp-sign-pipeline/SKILL.md` 第 94、100–140、150–160、200–225 行與 `templates/sign-and-notarize.sh` 第 21、28、53–54 行 |
| E22 | `accessDenied`、`insufficientAccess`、`unknownAuthState` 是 ical **自己**的 `EventKitError` enum case，不是系統的錯誤名稱。別的 MCP 不會出現這些字串 | 已驗證 | `mcps/che-ical-mcp/Sources/CheICalMCP/EventKit/EventKitManager.swift` 約第 2434–2446 行 |
| E23 | ical 的 `Makefile` 有三條路徑：`install` 用 `codesign --force --sign -`（ad-hoc，開發迭代）；`install-signed` 用 Developer ID 加 `--options runtime` 加 `--entitlements`，**未公證、僅供開發**；`release-signed` 才是公證、可散布的流程 | 已驗證 | `mcps/che-ical-mcp/Makefile` 約第 86–90 行（`install`）與第 91–140 行（`install-signed`）。「未公證、僅供開發」在 `install-signed` 前的註解（「NOT notarized」「dev only」）與 recipe 結尾的 `echo`（「Developer ID signed, NOT notarized — dev only」）都有寫 |
| E24 | code requirement 不符時，在 Terminal 單獨跑 `--setup` 會看到說謊的 `.fullAccess` 然後什麼都不做，所以只建議「跑 `--setup`」是死路。只有 EventKit | 他人實測 | ical `EventKitManager.swift` 的註解，引用 #158 與 #154。環境版本未記載 |
| E25 | Apple 文件有 `com.apple.security.personal-information.calendars`（read-write access to the user's calendar）與 `…addressbook`，**沒有** `com.apple.security.personal-information.reminders`：該文件端點回 HTTP 404 | 已驗證 | 2026-10-18 對 `developer.apple.com/tutorials/data/documentation/bundleresources/entitlements/<key>.json` 取得 200／404。**404 不等於該 key 不存在**，只表示 Apple 沒有為它寫文件頁 |
| E26 | 兩層授權模型也適用 Apple Events（binary 層加 host 層） | 類推 | 由 E9 推得，E9 只有 EventKit 的證據 |
| E27 | Apple Events 的狀態查詢（`AEDeterminePermissionToAutomateTarget(..., false)`）在 code requirement 不符時是準確的，沒有 E10 那種依 context 而異的盲點 | 未驗證 | 沒有任何證據 |
| E28 | `NSAppleScript` 回傳的文字 `Not authorized to send Apple events to <App>` 對應 `errAEEventNotPermitted`（-1743） | 類推 | che-things-mcp#1 只給文字、沒有數值；E1 的標頭註解說明 -1743 的語意與這句話相符 |
| E29 | `tccutil reset <服務>` 不帶 bundle id 時，對該服務下**所有** app 重置；帶 bundle id 時只重置該 bundle | 已驗證 | 本機 `man tccutil`：「Reset all decisions for the specified service… If a bundle identifier is specified, the service will be reset for that bundle only」 |
| E30 | 專案原本沒有 Info.plist、之後嵌入時，binary 的簽章 identifier 會從 `CheThingsMCP-<hash>` 變成 `CFBundleIdentifier`；TCC 的 code requirement 含 identifier，所以既有授權會對不上、需要重新授權 | 類推 | E8：ical 的 identifier 等於它的 `CFBundleIdentifier`，有 Info.plist；things 沒有 Info.plist，identifier 是 `CheThingsMCP-<hash>`。E4 的日誌顯示 requirement 含 `identifier "com.checheng.CheICalMCP"`。沒有對「嵌入前後」做過同一個 binary 的對照 |
| E31 | 換簽章身分（ad-hoc → Developer ID）後，Apple Events 的舊授權 row 也會因 code requirement 不符而失效 | 未驗證 | EventKit 有（E4），Apple Events 沒有任何觀察 |
| E32 | Automation 的 TCC 服務鍵是 `kTCCServiceAppleEvents` | 未驗證 | 沒有在本機日誌或資料庫看到。E12 只證明 `tccutil` 以 `kTCCService%s` 組字串 |
| E33 | `mcp-sign-pipeline` 本身只安裝檔案，不簽章。簽章與公證由 `make release-signed` → build 腳本的 `[3.5/N]` 步驟 → `scripts/sign-and-notarize.sh` 一條鏈完成：`release-signed` 需要 `DEVELOPER_ID` 與 `NOTARY_PROFILE`，`ENTITLEMENTS` 由 sign 腳本讀取。模板的簽章與公證在同一支腳本，中間沒有檢查點；ical 自訂的版本在簽章後、公證前有 `[2.5/5]` 閘門，驗證**簽好的 binary** 兩個 key 皆為 `<true/>`（避免來源檔帶著 `<false/>` 卻通過） | 已驗證 | harness-devtools 2.5.0 的 `templates/Makefile-release-signed.snippet` 第 11–17 行、`templates/build-script-step-3.5.sh` 第 8–46 行；ical 的 `scripts/sign-and-notarize.sh` 約第 122–153 行；模板無 `[2.5/5]` |
| E34 | `plutil -p` 把布林印成 `=> true`／`=> false` | 已驗證 | 2026-10-18 對 ical 的 `Entitlements.plist` 實跑，兩個 key 都是 `=> true` |
| E35 | Claude Code 的 `allowed-tools`：(1) 讓列出的工具在該回合免詢問，裸 `Bash` 等於所有 shell 指令都免詢問；(2) `Bash(ls *)` 的空格是規則的一部分，`ls -la` 與 `ls` 匹配、`lsof` 不匹配，所以 `Bash(codesign -d *)` **不會**匹配 `codesign -dv …`；(3) 複合指令（`&&`、`\|\|`、`;`、`\|`、`&`、換行）的每個子指令都要各自匹配規則；(4) 在 plugin skill 內文與 allowed-tools 中，`${CLAUDE_PLUGIN_ROOT}` 會被展開 | 已驗證 | 官方文件 `code.claude.com/docs/en/skills.md` 與 `…/permissions.md`，2026-10-18 取得 |

## 還沒有證據的地方（寫在這裡，免得被當成已知）

- 未涵蓋的 TCC 服務：Accessibility、Full Disk Access、Photos、麥克風、相機、Contacts、Location、Screen Recording、Files & Folders。本 plugin 沒有這些服務的一手資料，遇到就明說沒涵蓋，不要類推。憑證與 token 類授權（Keychain、API token）也不在範圍。
- **Reminders 實際需要哪個 entitlement。** Apple 文件只列 `calendars`（E25）；ical 另外放了 `reminders`，不清楚是否必要。以 tccd 日誌 `requires entitlement …` 裡的名稱為準。
- Apple Events 缺 entitlement 時的實際失敗樣子（E5）。
- 用 `Process` 呼叫 `osascript` 時，TCC 把授權算在哪個 client（osascript 還是你的 binary）。
- Automation、Calendar、Reminders 這些窗格（System Settings → 隱私權與安全性）能不能單獨移除某個條目。
