## Context

#118 的既有診斷已允許跳過discuss，推薦主skill策略＋最小CLI缺口。#119安裝與#120書籤搜尋已有驗證PR。#125的formResponse因果敘述尚無證據；官方文件僅支持上傳需登入、題目可限制檔案，以及Picker可使用iframe，不能從URL判斷送出。#140要求呼叫端保留stderr與狀態。

## Goals / Non-Goals

目標：可執行、可驗證的候選整理與命令結果檢查，以及符合既有六節規範的Forms交接。
非目標：不新增Safari CLI子命令、不放寬playbook命名規範、不自動送出表單、不宣稱找回原始未命名頁面。

## Decisions

### Recall workflow

主skill保留recall觸發，連到reference與相鄰scripts/recall.py。helper僅依序呼叫既有CLI的JSON查詢，所有來源皆先檢查exit/stderr再解析；任一步失敗不輸出部分候選。只在記憶體合併，不建立瀏覽資料暫存檔。依完整URL去重，保留query/fragment與同標題不同URL；按已知最新紀錄時間排序，未知時間在後。來源、Reading List、folder/device/filename保留為線索，download source_url不是引用它的網頁證據。提供來源limit/returned/at_limit與stderr首行、候選total/offset/next_offset，不能把限制或缺資料說成查無其頁。每次分頁重新查詢並標示此界線；使用者以URL識別候選，不以索引鎖定。

### Command result handling

主skill與reference要求每步檢查退出碼、stderr第一行與完整診斷。Python範例分開以記憶體擷取stdout/stderr，非零或BLOCKING DIALOG即停止後續步驟，不自動重播已可能執行的動作。Shell pipeline明列pipefail，不用head/tail截斷活的命令串流。JSON只從stdout解析。

### Google Forms handoff

`safari-google-fill`採site=google/domainfragment、action=fill，description限定Forms。六節包含登入/表單權限、目標鎖定、文字與單選的觀察驗證、多頁SPA狀態、遇Picker/無可用file input交棒、人工上傳後檢查檔名，再依已有授權處理提交。公開文件與本案觀察分開列；formResponse或click exit0都不能證明送出或未送出。不得從私有題型碼推定可填textarea，也不得假定所有Picker iframe皆同源或跨源。

## Implementation Contract

初版helper規劃history/bookmarks採CLI search；經R1審查後，以下R2契約取代這個查詢層選擇。helper預設history→bookmarks→cloud-tabs→downloads，支援選來源、search、since、正數limit、offset及page-size。history保留CLI search；bookmarks讀既有JSON全集，與其他來源依完整URL先合併，再按title/URL與device/filename線索選候選，保留不同標題的同URL線索。helper不依賴尚未合併的CLI #120，直接CLI search範例另明示功能前提。輸出JSON候選和coverage，保留unknown日期與空download source_url線索；stderr原文先呈現，首行與有診斷標記留在coverage。未知schema/非零/阻擋警告即明確失敗。只處理既有權限，不修改TCC、binary或daemon。

命令範例對照實際CLI help與JSON欄位；功能測試用合成資料/fake CLI驗證完整URL去重、nullable日期、來源限制、失敗不產生成功空結果及每步停止。Forms不在真實表單操作，驗證以官方來源、命令語法及情境審查為限。新skill六節/frontmatter/name/description驗證；plugin.json與marketplace版本一致為2.9.0。

## Risks / Trade-offs

- 找不到頁面可能是來源缺失/查詢受限 → coverage與診斷明示，人的辨識保留給使用者。
- 來源查詢與分頁非同一瞬間 → 每次是新觀察，不宣稱transaction across sources。
- Forms的DOM與語言會變 → 以當下snapshot refs、可見文字與欄位回讀判斷，拒絕硬編personal selector。
- 跨repoissue引用 → PR/commit使用完整PsychQuant/safari-browser引用；狀態仍寫回原issue。

## R2 審查調整

保留完整搜尋目的，將書籤搜尋放在URL合併後，既能保留Reading List/alias線索也能使用目前JSON介面。未觀察到書籤時reading_list是null，不宣稱false。主skill不新增Python自動授權，沿用原有工具權限規則。新增以真實Swift編碼器產生的合成JSON fixture，來源字段source_url是String、空值用空字串而非null；不把錯誤schema轉成成功空結果。Forms目標鎖定使用已觀察的form-ID前綴，檔案選擇明確交棒。
