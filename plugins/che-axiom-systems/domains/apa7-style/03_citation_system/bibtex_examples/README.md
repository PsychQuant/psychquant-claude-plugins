# BibTeX Citation Examples for APA 7th Edition

這個資料夾包含了完整的 APA 7th Edition BibTeX 引用範例，專為學術寫作和研究而設計。所有範例都經過分類整理，便於查找和使用。

## 📁 資料夾結構

### 01_Citation_Examples/ - 文內引用範例
用於**文內引用**格式 (APA 第8章)：
- `basic_author_date.bib` - 基本作者-日期格式 (8.6-8.11)
- `multiple_authors.bib` - 多作者處理 (8.12, 8.18)  
- `corporate_institutional.bib` - 機構作者 (8.13, 8.17, 8.21)
- `disambiguation_cases.bib` - 同作者/年份消歧 (8.19-8.20)
- `special_formatting.bib` - 特殊情況格式 (8.14-8.16)
- `name_formatting.bib` - 國際姓名和特殊字符

### 02_Reference_Types/ - 參考文獻類型
用於**參考文獻清單**條目 (APA 第10章)：
- `journal_articles_basic.bib` - 基本期刊文章 (10.1)
- `journal_articles_special.bib` - 特殊期刊情況 (撤稿、特刊等)
- `books_basic.bib` - 基本書籍 (10.2)
- `book_chapters.bib` - 書籍章節 (10.3)
- `reports_theses.bib` - 報告和論文 (10.4, 10.6)
- `web_online_sources.bib` - 網路和線上資源 (10.10-10.16)
- `audiovisual_media.bib` - 影音媒體 (10.12-10.13)
- `software_datasets.bib` - 軟體和資料集 (10.9-10.10)
- `legal_references.bib` - 法律引用 (APA 第11章)

### 03_Formatting_Rules/ - 格式規則
用於**格式和排序** (APA 第9章)：
- `basic_author_formats.bib` - 基本作者格式 (9.8)
- `alphabetical_sorting.bib` - 字母排序規則 (9.44)
- `chronological_ordering.bib` - 時間排序 (9.46-9.48)
- `date_formatting.bib` - 日期處理和季節
- `special_characters.bib` - 國際字符和符號

### 04_Usage_Guide/ - 使用指南
- `README.md` - 詳細使用說明
- `apa_conversion_guide.md` - BibTeX 轉 APA 格式指南
- `splitting_large_references.md` - **NEW**: 大型參考文獻檔案分割指南

### 05_Original_Files/ - 原始檔案
- 來自 biblatex-apa 套件的完整原始測試檔案

## 🚀 快速開始

1. **基本引用**: 從 `01_Citation_Examples/basic_author_date.bib` 開始
2. **期刊文章**: 使用 `02_Reference_Types/journal_articles_basic.bib`
3. **網路資源**: 查看 `02_Reference_Types/web_online_sources.bib`
4. **法律引用**: 參考 `02_Reference_Types/legal_references.bib`

## 📊 統計數據

- **總計範例**: 680+ 個完整的 BibTeX 條目
- **涵蓋範圍**: 所有 APA 7 參考文獻類型
- **組織方式**: 按使用情境分類，便於導航
- **檔案大小**: 每個檔案都控制在可一次讀完的大小 (< 200行)

## 💡 使用技巧

### 常見條目類型對照表

| BibTeX 類型 | APA 用途 | 範例檔案 |
|-------------|---------|------------|
| `@ARTICLE` | 期刊文章 | `journal_articles_basic.bib` |
| `@BOOK` | 書籍、專著 | `books_basic.bib` |
| `@INCOLLECTION` | 書籍章節 | `book_chapters.bib` |
| `@ONLINE` | 網路資源、部落格 | `web_online_sources.bib` |
| `@VIDEO` | 電影、YouTube | `audiovisual_media.bib` |
| `@AUDIO` | 播客、音樂 | `audiovisual_media.bib` |
| `@REPORT` | 技術報告 | `reports_theses.bib` |
| `@DATASET` | 研究資料 | `software_datasets.bib` |
| `@SOFTWARE` | 電腦程式 | `software_datasets.bib` |
| `@JURISDICTION` | 法院案例 | `legal_references.bib` |
| `@LEGISLATION` | 法律、法規 | `legal_references.bib` |

### 特殊欄位說明

- **DOI**: 有時一律包含
- **URL**: 無 DOI 時的線上資源
- **ENTRYSUBTYPE**: 指定媒體類型 (tweet, podcast 等)
- **AUTHOR+an:role**: 指定角色 (director, editor 等)
- **AUTHOR+an:username**: 社交媒體用戶名
- **ORIGDATE**: 重印/翻譯作品的原始日期
- **PUBSTATE**: 印刷中出版物

## ⚡ 重要注意事項

1. **機構作者**: 使用雙重大括號 `{{Corporation Name}}`
2. **特殊字符**: 大多數 Unicode 字符可直接使用
3. **大小寫保護**: 專有名詞用大括號保護 `{United States}`
4. **日期範圍**: 使用斜線分隔 `2020-01/2020-03`
5. **季節**: 使用代碼 21=春季, 22=夏季, 23=秋季, 24=冬季

## 📚 延伸學習

詳細的使用說明請參考 `04_Usage_Guide/` 中的指南：

### `apa_conversion_guide.md` - BibTeX 轉換指南
- LaTeX 設定說明
- 編譯步驟
- 常見問題解決
- 進階功能使用

### `splitting_large_references.md` - 檔案分割指南
- **大型參考文獻檔案分割策略**
- **按類型、作者、主題分割方法**
- **APA 7 格式清理步驟**
- **LaTeX 中使用分割檔案的技巧**
- **自動化分割腳本範例**

## 🔗 相關資源

- **APA Style 官網**: https://apastyle.apa.org/
- **biblatex-apa 文檔**: CTAN 套件文檔
- **APA 手冊章節**: .bib 檔案中的註解對應具體的 APA 章節

---
*此收藏基於官方 biblatex-apa 套件測試案例，提供最準確和最新的 APA 7th Edition 引用格式。*