---
name: che-duckdb-mcp
description: Guide for using the che-duckdb-mcp MCP tools to search DuckDB documentation and operate local DuckDB databases. Use when user asks about DuckDB SQL syntax, DuckDB functions (read_csv, json_extract, etc.), querying local .duckdb files, or anything related to DuckDB.
allowed-tools:
  - mcp__plugin_che-duckdb-mcp_duckdb__*
---

# che-duckdb-mcp — DuckDB Documentation & Local Database

14 tools split into documentation queries (8) and local database operations (6). The MCP runs the tools; this skill tells you *when* to use them vs alternatives.

## Decision tree: which tool for which question?

### "How do I use DuckDB function X?"

```
mcp__plugin_che-duckdb-mcp_duckdb__get_function_docs { function_name: "X" }
```

- Supports fuzzy matching: `read_csvs` → `read_csv`, `JSON_EXTRACT` → `json_extract`
- **Prefer this over WebFetch** — offline cached, Levenshtein-tolerant
- **Prefer this over Grep** — already indexed by the parser

### "What's the DuckDB SQL syntax for X?"

```
mcp__plugin_che-duckdb-mcp_duckdb__get_sql_syntax { statement: "COPY" }   # SELECT, INSERT, CREATE TABLE, etc.
```

- Use for SQL statements (SELECT, INSERT, CREATE, COPY, ATTACH, etc.)
- For general concepts ("window functions", "CTEs") use `search_docs` instead

### "Search DuckDB docs for keyword X"

```
mcp__plugin_che-duckdb-mcp_duckdb__search_docs { query: "window functions", mode: "all", limit: 10 }
```

- Uses TF-IDF ranking (not substring match) — order matters, first result is usually best
- `mode`: `title` (fastest), `content`, `all` (default)
- Results include `source` field: `llms.txt` (concise) or `duckdb-docs.md` (full); llms.txt hits get 1.5× score bonus
- **Prefer this over WebFetch duckdb.org** — offline, ranked, no network round trip

### "Show me section X of the docs"

```
mcp__plugin_che-duckdb-mcp_duckdb__list_sections [{ level: 2 }]       # browse structure
mcp__plugin_che-duckdb-mcp_duckdb__get_section { id: "..." }          # fetch by anchor id
mcp__plugin_che-duckdb-mcp_duckdb__get_section { title: "COPY" }      # fuzzy title match
```

### "List all DuckDB functions"

```
mcp__plugin_che-duckdb-mcp_duckdb__list_functions
```

### "My doc results look outdated"

```
mcp__plugin_che-duckdb-mcp_duckdb__refresh_docs        # force re-download both llms.txt + duckdb-docs.md
mcp__plugin_che-duckdb-mcp_duckdb__get_doc_info        # shows per-source lastUpdated, sectionCount, cachePath
```

Normally not needed — the MCP uses ETag/Last-Modified conditional HTTP caching, so it auto-refreshes when upstream changes.

---

## Local database operations

### "Connect to a .duckdb file"

```
mcp__plugin_che-duckdb-mcp_duckdb__db_connect { path: "/abs/path/to/file.duckdb", read_only: true }
```

- `path` omitted → in-memory database
- **Storage version check** happens automatically before opening — incompatible files return a structured `storageVersionMismatch` error with upgrade suggestion
- For **remote / MotherDuck cloud** databases, use `mcp-server-motherduck` instead (this MCP is local-only)

### "Run a SELECT query"

```
mcp__plugin_che-duckdb-mcp_duckdb__db_query { sql: "SELECT ...", format: "markdown", limit: 1000 }
```

- Allowed: SELECT / WITH / SHOW / DESCRIBE / EXPLAIN / PRAGMA
- DDL / DML → `db_execute`
- `format`: `json` (default), `markdown` (best for reading), `csv`
- Default `limit: 1000` — override explicitly if user needs full table

### "Run CREATE / INSERT / UPDATE / DELETE"

```
mcp__plugin_che-duckdb-mcp_duckdb__db_execute { sql: "CREATE TABLE ... AS SELECT ..." }
```

### "What tables are there? What's this table's schema?"

```
mcp__plugin_che-duckdb-mcp_duckdb__db_list_tables [{ include_views: true, schema: "main" }]
mcp__plugin_che-duckdb-mcp_duckdb__db_describe { table: "users" }              # by name
mcp__plugin_che-duckdb-mcp_duckdb__db_describe { query: "SELECT a+b FROM t" }  # result schema
```

### "What version / state is the DB in?"

```
mcp__plugin_che-duckdb-mcp_duckdb__db_info
```

Returns DuckDB engine version, `swiftBindingRevision` (pinned), connection path, table count, read-only state.

---

## When NOT to use this MCP

| User wants | Use instead |
|------------|-------------|
| MotherDuck cloud database | `mcp-server-motherduck` |
| Remote / S3 .duckdb files | `mcp-server-motherduck` (supports `s3://`) |
| DuckDB installation / build guide | WebFetch `duckdb.org/docs/installation` |
| Very recent DuckDB release notes (hours old) | WebFetch `github.com/duckdb/duckdb/releases` |
| Writing SQL for other dialects (Postgres, SQLite) | Don't use this — DuckDB-specific |

## Error messages to expect

**Real DuckDB errors now surface cleanly** (as of v2.0.0):

- `Binder Error: Referenced column "X" not found in FROM clause! Candidate bindings: "Y"` — typo in column name
- `Catalog Error: Table with name X does not exist! Did you mean "Y"?` — typo in table name
- `Parser Error: syntax error at or near "X"` — SQL syntax problem
- `storageVersionMismatch` — file newer than current duckdb-swift

Previously these were all `DuckDB.DatabaseError error N` opaque strings — if you see that, the MCP binary is outdated and needs rebuild from the fix commit `a8b5a88` or later.

## Architecture notes

- MCP source: https://github.com/PsychQuant/che-duckdb-mcp
- `duckdb-swift` pinned to commit `d90cf8d` (DuckDB v1.5.0-dev)
- Docs cache at `~/.cache/che-duckdb-mcp/` (llms.txt + duckdb-docs.md + cache-meta.json)
- Both documentation sources are merged into a single TF-IDF inverted index at startup
