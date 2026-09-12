## Why

Safari CLI 已有本機資料查詢與 dialog 診斷，但呼叫端仍缺少可執行的 recall 流程、逐步讀取 stderr/退出碼的方法，以及 Google Forms 檔案上傳的可靠交接。追蹤需求為 PsychQuant/safari-browser 的 #118、#125、#140。

## What Changes

- 主 skill 增加逐步檢查結果的指引；保留完整 stderr、檢查第一行與退出碼、pipeline使用pipefail，遇阻擋先停止後續動作。
- 主 skill 的 recall 流程連到一個唯讀輔助腳本與說明，依完整URL去重、排序、保留跨來源線索並顯示查詢上限；不新增 Safari CLI 子指令。
- 新增符合既有命名規範的 `safari-google-fill`，description明確限定Google Forms，六節記錄多頁、上傳交接與可觀察的成功條件。
- plugin與marketplace版本同步升至2.9.0，保留既有manifest位置與其他plugin內容。

## Capabilities

### New Capabilities
- `safari-workflow-guidance`: 結果檢查、跨來源recall與Google Forms交接。

### Modified Capabilities
無。站點playbook規範仍遵循Safari repo既有契約。

## Impact

僅 `plugins/safari-browser/`、其marketplace entry，以及本change artifact。跨repo tracking使用完整issue引用；不更新已安裝cache、不提交表單、不讀取真實瀏覽內容做測試。
