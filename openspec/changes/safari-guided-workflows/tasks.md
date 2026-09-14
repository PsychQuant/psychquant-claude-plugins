## 1. 指引與範例
- [x] 1.1 Recall workflow：完整URL候選整理與coverage helper，合成資料及fake CLI驗證來源合併、排序、限制與失敗。
- [x] 1.2 Command result handling：主skill/reference加入逐步stderr/status與pipefail，執行範例驗證exit0警告與nonzero皆阻止下一步。
- [x] 1.3 Google Forms handoff：新增safari-google-fill六節playbook，核對官方來源、CLI語法與上傳/送出情境。
- [x] 1.4 R2審查調整：合併URL後搜尋、未知Reading List、既有JSON相容與原有工具權限；真實Swift編碼器fixture/fake CLI及metadata測試通過。
## 2. 整合
- [x] 2.1 Consistent plugin packaging：同步2.9.0版本與description，驗證frontmatter/name/六節/連結及完整測試。
- [x] 2.2 獨立審查、跨repo PR及三個原始issue狀態同步。

R2驗證：24項測試在預設Python及系統Python3.9.6通過；CLI help與實際Swift編碼器的合成JSON對照完成。六份CODE/DOCS審查通過；沒有查詢真實瀏覽內容、操作真實表單或更新已安裝cache。
