# mcp-tcc — CLAUDE.md

## Purpose

MCP 開發時的 macOS TCC 授權：出問題時一層一層查，開發時把「可授權、可診斷、可簽章」做進 Swift MCP。
做法取自 `che-ical-mcp`（#44、#108、#122、#154、#158、#168），補上 Apple Events。

範圍是**封閉的，只有兩項**：EventKit（Calendar／Reminders）與 Apple Events（Automation）。Accessibility、Full Disk Access、Photos、麥克風、相機、Contacts、Location、Screen Recording、Files & Folders 沒有一手資料，不涵蓋；憑證與 token 類授權（Keychain、API token）也不在範圍。遇到就說明沒涵蓋，不依性質相似類推。

## Skills

| Skill | 用途 |
|-------|------|
| `/mcp-tcc:tcc-diagnose` | 授權卡住時的逐層診斷：哪個服務 → 哪個 binary 與 host → 簽章／entitlements／Info.plist → tccd 日誌 → 下一步。只讀取，不替使用者操作 |
| `/mcp-tcc:tcc-instrument` | 把授權做進 Swift MCP：Info.plist、entitlements、可行動的錯誤訊息（`--setup`／`--print-tcc-path` 為建議項），並銜接 `harness-devtools:mcp-sign-pipeline` |

## 證據紀律（最重要）

`references/evidence.md` 是這個 plugin 的核心。每個主張標 `[E#]`，狀態是**封閉的四種**：已驗證／他人實測／類推／未驗證。一個主張若一部分是實測、一部分是類推，就拆成兩列。

- 改 skill 裡的主張，先改證據表的狀態，不要反過來。
- 不要把「類推」寫成事實。目前最重要的兩個待實測項是 **E5**（Apple Events 缺 entitlement 的實際失敗樣子）與 **E13**（加 entitlement 重簽後 healing 是否如預期）。
- **誰能升級狀態**：只有維護者，在 `psychquant-claude-plugins/plugins/mcp-tcc/references/evidence.md` 這份原始碼上改。執行 skill 的 Claude 不改 plugin cache 內的副本，也不自己升級狀態；觀察到新證據時把原文貼給使用者。
- 外部事實一律查一手來源（SDK 標頭、Apple 文件原文、man page、原始碼、實跑指令），不憑記憶。**證據表引用的原始檔也要去讀**：第二輪審查就是因為去讀了來源，才抓到 Reminders 的 entitlement 在 Apple 文件不存在。
- macOS 27.x 的 TCC 行為沒有任何實測，不要假設 26.5.1 的行為延續。

## allowed-tools 紀律

官方文件 [E35]：`allowed-tools` 讓列出的工具在該回合**免詢問**；裸 `Bash` 等於整個回合的所有 shell 指令都免詢問。所以兩個 skill 都只列範圍限定的 `Bash(…)`，寫檔（Edit／Write）與其他指令保留正常的權限提示。**不要為了省提示把裸 `Bash`、`Edit`、`Write` 加回去。**

寫 pattern 時注意兩點，都是第三輪審查抓到的：

- `Bash(ls *)` 的空格是規則的一部分，所以 `Bash(codesign -d *)` **不會**匹配 `codesign -dv …`；要為每個實際用到的旗標形式各寫一條。
- 複合指令（`|`、`&&`、`;`…）的每個子指令都要各自匹配；skill 內文的指令因此寫成獨立的單一指令，不用 `BIN=…` 這種變數。

「預先核准」不等於「絕對唯讀」：即使限定了前綴，`sqlite3` 仍有 `.shell` 之類的點指令（所以限定 `-readonly -safe`），`git diff` 有 `--output=<檔案>`（所以不預先核准 `git diff`）。**只預先核准內文實際用到的指令**，沒用到的不要列。

## 與鄰近 skill 的分工

| 情境 | 用 |
|---|---|
| MCP 完全連不上、工具叫不出來 | `harness-devtools:mcp-diagnose` |
| 連得上但某個 tool 行為錯，原因未知 | `harness-devtools:mcp-debug` |
| 已知或懷疑是 EventKit／Apple Events 授權 | `mcp-tcc:tcc-diagnose` |
| 新 MCP 要碰 EventKit／Apple Events，或這類專案缺 Info.plist／entitlements | `mcp-tcc:tcc-instrument` |
| 安裝簽章與公證 pipeline | `harness-devtools:mcp-sign-pipeline`（**先**做 `tcc-instrument` 的 Step 3，並讀它 Step 5 的流程） |
| che-ical-mcp 自己的 Calendar 問題 | `che-ical-mcp:troubleshoot-tcc`（專屬版，本 plugin 是它的一般化） |

同一個症狀可能同時觸發 `tcc-diagnose`、`che-ical-mcp:troubleshoot-tcc`、`mcp-debug`，甚至 `mcp-sign-pipeline`（它的 description 也寫了「TCC dialog 不出現」）。Calendar／Reminders 且專案是 che-ical-mcp 時用 ical 專屬的，其餘 EventKit／Apple Events 用 `tcc-diagnose`。`mcp-sign-pipeline` 若先被觸發，`tcc-instrument` 的先決警告就沒載入，這是已知風險，只能靠使用者與 README 提醒。

`mcp-debug` 2.5.0 的 B3 與重建同步流程、`che-ical-mcp:troubleshoot-tcc` 的 Step 4（`tccutil reset … com.checheng.CheICalMCP`）和本 plugin 的結論有出入，細節在證據表 E18、E11。

## Development

- 改完同步：`/harness-devtools:plugin-update mcp-tcc`
- 每次改 skill，bump `plugin.json` 的 version，否則 `plugin update` 不會把新內容拉進 cache
- description 保持精簡、觸發語在前（≤ ~500 字元），見 harness-devtools 的 `skill-description-budget` 規則
- 改了 skill 清單或 description，同步 `README.md` 與 marketplace.json 的描述
- skill 內用 `${CLAUDE_PLUGIN_ROOT}/references/evidence.md` 讀證據表；官方文件說明在 plugin skill 內文會展開這個變數
- skill 之間用「Step N」互相引用（`tcc-diagnose` ↔ `tcc-instrument`），改編號時兩邊一起改；`mcp-sign-pipeline` 的步驟在內文一律寫成「pipeline 的 Step N」以免混淆
