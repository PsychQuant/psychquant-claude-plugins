# Changelog

## 0.1.2 — 2026-10-18

第一次在實機上觀察 Apple Events 的授權行為（che-things-mcp 1.7.0，macOS 27.2）。只新增觀察到的事；沒有觀察到的部分維持原狀態。

### Added

- **E41**：Apple Events 的授權記在發出請求的 host app 身上。同一個 binary，Ghostty 底下是 authorized、Terminal.app 底下是 -1744。
- **E42**：把 binary 從 ad-hoc（identifier `CheThingsMCP`）換成 Developer ID（`com.checheng.CheThingsMCP`）後，host 原有的授權仍然有效。
- **E43**：簽章、Hardened Runtime、帶 Apple Events entitlement 的 CLI binary，在從未被問過的 host 上跑 `--setup` 會跳出對話框，允許後持續有效（單一樣本）。

### Changed

- **E26、E31 縮小範圍**：原本的主張涵蓋整個 Apple Events；host 層現在有一手觀察（E41、E42），所以這兩列只留下沒觀察到的 binary 層，狀態不變（類推、未驗證）。E36 補註 host 層不受 identifier 改變影響。
- `tcc-diagnose`：「換簽章後失效」那列改成先查是不是換了 host；兩層模型段改引 E41。
- `tcc-instrument`：Apple Events 段改寫為有單次實機觀察的設計，並明列沒測的三件事（macOS 26、缺 entitlement、對話框文字的來源）。
- 「還沒有證據的地方」：移除「對話框是否出現、授權是否持久」，新增對話框文字來源、macOS 26、binary 層條目三項。

## 0.1.1 — 2026-10-18

第一次拿 `tcc-instrument` 實際套用到一個專案（che-things-mcp 1.7.0，簽章、公證、發布）之後的更正。新增的主張都有一手輸出，沒有升級任何既有的類推。

### Changed

- **E30（identifier 規則）**：原本寫「沒有 Info.plist 時是 `CheThingsMCP-<hash>`」，實測是：有嵌 Info.plist 時不論 ad-hoc 或 Developer ID 一律是 `CFBundleIdentifier`；沒有時 linker 自簽與 Developer ID 簽的是檔名，`codesign --sign -` 重簽的才是「檔名-hash」。依一列一種狀態的規則，「既有授權會對不上」拆成新的 E36，維持類推。
- **E7（`exclude`）**：原本只提 `Info.plist`，「為什麼要排除沒有查證」。實跑：`Entitlements.plist` 放在同一 target 目錄時，不排除會有 unhandled file 警告。`tcc-instrument` 的 `Package.swift` 範例改成兩個都列。
- `tcc-instrument` 的「Apple Events 版（設計，非已出貨）」改為有參考實作（che-things-mcp 1.7.0），但明說授權對話框與授權持久性**沒有實機驗證**。錯誤訊息的修復順序改成 System Settings 在前、`--setup` 在後，路徑要加引號，不再假設使用者的終端機是 Terminal.app。

### Added

- 證據表 E36–E40（共 40 條）：授權對不上（類推）；`swiftbuild` 下 `--arch` 都寫同一個目錄；`mcpb pack` 的輸出檔名；公證的驗證指令（`spctl -t install`，`-t execute` 對裸 CLI binary 一律 rejected）；`NSAppleScript` 的錯誤字典 key。
- `tcc-instrument` 新增「簽章前先確認被簽的是新 binary」與公證驗證的說明。
- 「還沒有證據的地方」新增兩項：被明確拒絕後是否還會彈窗；已簽章的 Apple Events binary 上對話框是否出現、授權是否持久。

## 0.1.0 — 2026-10-18

初版。

### Added

- `tcc-diagnose`：macOS TCC 授權問題的逐層診斷（服務分類、binary 與 host、簽章／entitlements／Info.plist、tccd 日誌、下一步決策表）。
- `tcc-instrument`：把授權做進 Swift MCP（現況偵測、Info.plist 嵌入、entitlements、可行動的錯誤訊息、`--setup`／`--print-tcc-path` 設計），並銜接 `mcp-sign-pipeline`，附上它的五個破壞性行為警告，以及「先複本開發簽章驗證、再公證」的流程。
- `references/evidence.md`：35 條主張的證據與狀態，狀態為封閉的四種。

### 發布前經過三輪獨立審查

每一輪都由全新的審查者執行，只讀檔案、不看作者結論；第二、三輪另外被要求去讀證據表引用的來源檔。審查者回報的每一項，我都對原始檔、man page 或官方文件核實後才處理；個別項目以文件說明取代程式修改（例如重疊觸發的分工寫在 README 與 CLAUDE.md，沒有塞進 description）。

**第一輪**（30 項）

- 導入 skill 補上「已有檔案就合併、不覆蓋」與跑 pipeline 前的備份。
- 診斷 skill 把 `tccutil reset` 統一成「Claude 完全不做」，驗證改為只用讀取型工具。
- 證據表狀態詞收斂成封閉四種；E4 補上完整日誌與版本注意。
- 回填證據的責任改由維護者在原始碼上做，執行者不改 plugin cache。

**第二輪**

- pipeline 會自己 commit 空的 entitlements，原本的「跑完 `git diff` 檢查」看不到覆蓋（E21）。
- Reminders 的 `…personal-information.reminders` 在 Apple 文件不存在（端點 404，E25），不再當成必要 key。
- `allowed-tools` 不再用裸 `Bash`、不預先核准 `Edit`／`Write`（E35）。
- 「ad-hoc 重簽」拆成兩件不同的事：安裝路徑把新 build 簽成 ad-hoc，以及對已簽章 binary 再重簽；`install-signed` 是未公證的開發簽章，不是「正式簽章」（E23）。
- 診斷與導入之間補上順序與「回 Step 2 最多一次」的出口；範圍後門與 `osascript` 子行程的歸屬在兩個 skill 都標為未驗證。
- 更正 E1 的符號名稱為 `kAEDoNotPromptForUserConsent`。

**第三輪**

- 專案**已經有簽章 pipeline** 時不要再跑 `mcp-sign-pipeline`：它的 Step 3.2 也會無條件覆蓋 `scripts/sign-and-notarize.sh`，「已安裝就中止」的檢查在蓋完之後；ical 自訂的 sign 腳本有範本沒有的 `[2.5/5]` 簽後閘門（E21、E33）。
- Step 5 重組：說明 pipeline 只安裝檔案、不簽章；簽章與公證的實際指令與環境變數（同一次呼叫內設定）；**先在複本上開發簽章並驗證，通過了才公證**，閘門的通過條件寫成三項（E33、E34）。
- `allowed-tools` 的 pattern 改成真的能匹配：`Bash(codesign -d *)` 不匹配 `codesign -dv`，所以拆成實際用到的形式；`sqlite3` 加 `-safe`；移除內文沒用到的 `git diff`／`git log`；內文指令改成不含變數的獨立指令（E35）。
- 「frontmatter 只預先核准唯讀指令」改為較精確的「只預先核准列出的幾個指令前綴」。
- 診斷與導入之間加上**整個任務內最多往返一輪**的總上限；跨 skill 的步驟編號一律標明是誰的 Step。
- 把類推寫成事實的地方改正，並新增證據列：Apple Events 舊授權 row 是否失效（E31）、`kTCCServiceAppleEvents`（E32）、`plutil -p` 的布林輸出（E34）。
- 證據表補記同一來源內互相矛盾的說法：ical 對「失敗 context 的狀態查詢」有兩種描述（E10）、`tccutil` 在 ical 文件裡有「報錯 -10814」與「顯示成功但 no-op」兩種失敗（E11）、ical 記載的「未簽章 v1.7.0 在 26.5.1 仍可用」邊界（E6）。
- **移除一句沒有證據的話**：證據表曾寫「AI4o 專案用 calendars 那一把」。那是從審查者轉述抄來、作者沒有自己讀過的；實際檔案是 App Sandbox 的 `.app`，與 hardened runtime 的命令列 binary 不同體制，不能當證據。
- 診斷 skill 的 host 判斷順序改為先排除 Terminal／VS Code；Info.plist 範本的 usage description 只放用到的服務。

### 已知限制

- 只涵蓋 EventKit 與 Apple Events。
- Apple Events 缺 entitlement 時的實際失敗樣子是類推（E5），healing 行為是未驗證（E13）。
- Apple Events 版的 `--setup`／`--print-tcc-path` 是依 SDK 標頭語意推導的設計，尚未在任何出貨 binary 驗證。
- 他人實測的證據各有各的環境：E4 是 macOS 26.5.1，E6 是 26.4.1 以上，E9／E10／E11／E24 沒有記載版本。macOS 27.x 的 TCC 行為沒有任何實測。
- `mcp-sign-pipeline` 先被觸發時，`tcc-instrument` 的先決警告不會載入；分工只能寫在文件裡。
- Reminders 實際需要哪個 entitlement 不確定（E25）；Automation、Calendar、Reminders 窗格能否單獨移除條目沒有資料。
- 審查者沒有網路，所以 Apple 文件端點（E2、E3、E25）與各 GitHub issue 的內容，只有作者自己核對過，沒有第二個人獨立核對。
- Apple 文件頁是 JS 渲染，證據表改用文件的 JSON 端點取得原文；端點回 404 只表示沒有文件頁，不等於該 key 不存在。
