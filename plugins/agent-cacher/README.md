# agent-cacher (Claude Code plugin)

Plugin shell that wires [PsychQuant/agent-cacher](https://github.com/PsychQuant/agent-cacher) into Claude Code as an MCP server.

## What it adds

Four MCP tools, all read-only against a local SQLite cache:

| Tool | Purpose |
|------|---------|
| `cache.lookup` | Most recent N calls matching a fingerprint signature (e.g. `gh api`) |
| `cache.fetch` | Output bytes for a specific call ROWID (returns base64) |
| `cache.recent` | All calls within a time window, optionally filtered by binary name |
| `cache.diff` | Unified diff between two cached calls' outputs |

## Mode B (explicit lookup) — what this is NOT

This plugin does **not** transparently intercept your shell commands. The wrappers shipped in the upstream repo always actually run the underlying command and write the result to SQLite; the agent decides whether to query the cache and reuse cached output instead of re-running. See [the upstream README](https://github.com/PsychQuant/agent-cacher#design-evolution-mode-a--mode-b) for the rationale.

## Auto-installed binaries

`bin/cacher-mcp-wrapper.sh` downloads two binaries from the GitHub Release on first invocation:

- `~/bin/cacher` — the CLI (use `cacher --help`)
- `~/bin/cacher-mcp` — the MCP server stdio binary

Source builds at `~/Developer/agent-cacher/.build/release/` are preferred when present and never overwritten.

## DB location

Default: `~/Library/Application Support/agent-cacher/cache.db`. Override via `AGENT_CACHER_DB_PATH` env var (set in your Claude Code settings or shell).

## Recommended workflow

Inside Claude Code, the agent:

1. Calls `cache.recent` or `cache.lookup` BEFORE invoking a known-slow shell command.
2. Reads the timestamp + sha256 to decide whether the cached output is fresh enough.
3. If fresh: calls `cache.fetch` to retrieve the bytes.
4. If stale or missing: runs the actual command (via a wrapper) — which records a fresh row.

## License

MIT.
