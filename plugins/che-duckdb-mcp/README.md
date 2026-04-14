# che-duckdb-mcp

**DuckDB MCP Server (Swift)** — 整合 DuckDB 文檔查詢與本地資料庫操作。

## 功能概覽

14 個工具 = 8 文檔 + 6 資料庫。

### 文檔工具 (8 個) — v2.0.0 全面升級

| 工具 | 功能 |
|------|------|
| `search_docs` | **TF-IDF** 加權搜尋 + llms.txt 優先（多來源合併） |
| `list_sections` | 列出文檔章節 |
| `get_section` | 取得章節內容 |
| `get_function_docs` | 查詢函數文檔（**Levenshtein fuzzy matching**） |
| `list_functions` | 列出所有函數 |
| `get_sql_syntax` | 查詢 SQL 語法 |
| `refresh_docs` | 強制更新文檔 |
| `get_doc_info` | 取得兩個來源的快取資訊 |

### 資料庫工具 (6 個)

| 工具 | 功能 |
|------|------|
| `db_connect` | 連接資料庫（記憶體或檔案，自動檢查 storage version） |
| `db_query` | 執行 SELECT 查詢（錯誤訊息含 DuckDB 原始內容） |
| `db_execute` | 執行 DDL/DML 語句 |
| `db_list_tables` | 列出表格和視圖 |
| `db_describe` | 描述表格或查詢結構 |
| `db_info` | 取得資料庫資訊（含 duckdb-swift pinned revision） |

## 安裝

### 方式 1：Plugin 安裝（推薦，自動下載 binary）

```
/plugin install che-duckdb-mcp@psychquant-claude-plugins
```

首次使用時 `bin/che-duckdb-mcp-wrapper.sh` 會自動從 [PsychQuant/che-duckdb-mcp releases](https://github.com/PsychQuant/che-duckdb-mcp/releases) 下載 `CheDuckDBMCP` binary 到 `~/bin/`。

### 方式 2：從原始碼編譯

```bash
git clone https://github.com/PsychQuant/che-duckdb-mcp.git
cd che-duckdb-mcp
swift build -c release
cp .build/release/CheDuckDBMCP ~/bin/
```

然後再 `/plugin install` 即可（wrapper 會偵測到 `~/bin/CheDuckDBMCP` 已存在）。

## v2.0.0 重點

- **TF-IDF 搜尋引擎**：倒排索引 + cosine similarity，比 substring match 精準一個數量級
- **雙來源文檔**：llms.txt (3KB 精簡版) + duckdb-docs.md (5MB 完整版)，llms.txt 命中加 1.5× 分數
- **Levenshtein fuzzy matching**：`read_csvs` → `read_csv`、`JSON_EXTRACT` → `json_extract`
- **ETag/Last-Modified 條件式快取**：不再每 24h 重下 5MB
- **Pinned duckdb-swift**：避免 storage format 相容性炸彈
- **DuckDB 原生錯誤訊息**：`Binder Error` / `Catalog Error` / `Parser Error` 直接穿透到 MCP response，不再是 opaque `error N`（[fix #1](https://github.com/PsychQuant/che-duckdb-mcp/issues/1)）

## 輸出格式

`db_query` 支援三種輸出格式：

- **json**: 結構化 JSON（預設）
- **markdown**: 表格格式（適合閱讀）
- **csv**: CSV 格式

## 技術細節

- **語言**: Swift 5.9+
- **平台**: macOS 13.0+
- **MCP SDK**: swift-sdk 0.12.0
- **DuckDB**: duckdb-swift pinned revision `d90cf8d`（DuckDB v1.5.0-dev）
- **快取**: `~/.cache/che-duckdb-mcp/`（HTTP 條件式更新）

## 安全考量

1. `db_query` 僅允許 SELECT/WITH/SHOW/DESCRIBE/EXPLAIN/PRAGMA
2. 預設限制返回 1000 行
3. 支援唯讀模式
4. **Local-use only**：錯誤訊息含檔案路徑、schema、SQL 片段，不適合未經 sanitize 的遠端部署

## 連結

- **原始碼**: https://github.com/PsychQuant/che-duckdb-mcp
- **Releases**: https://github.com/PsychQuant/che-duckdb-mcp/releases
- **Issues**: https://github.com/PsychQuant/che-duckdb-mcp/issues
