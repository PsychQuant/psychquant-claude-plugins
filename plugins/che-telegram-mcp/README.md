# che-telegram-mcp Plugin

Claude Code plugin for Telegram — bundles **personal account (TDLib)** and **Bot API** MCP servers in one plugin. Credentials are stored in macOS Keychain, never in config files.

## Two paths, one plugin

This plugin ships two independent MCP servers. Pick the one(s) you need — wrappers lazy-download binaries, so an unused server costs you nothing.

| Server | Identity | What it can do | Binary size | When to use |
|--------|----------|----------------|-------------|-------------|
| `telegram-all` | **Your personal Telegram account** (via TDLib) | Read all your private chats, send as you, search full history, manage groups, dump chats to Markdown | ~223 MB | "I want my own Telegram automated" — reading conversations, drafting replies, archiving chats |
| `telegram-bot` | **A Telegram bot** (via Bot API) | Send/receive messages as a bot, manage chats the bot is in, get updates | ~16 MB | "I want a bot to post updates / take commands" — notifications, integrations, public chat moderation |

Most personal-automation users want **`telegram-all` only**. Bot integrations are a separate use case.

---

## Quick start — pick your track

### Track A — Personal account only (most common)

You want to read/send messages as **yourself**.

```bash
# 1. Install plugin
/plugin install che-telegram-mcp@psychquant-claude-plugins

# 2. Store API credentials (from https://my.telegram.org/apps)
security add-generic-password -a "che-telegram-all-mcp" -s "TELEGRAM_API_ID" -w 'YOUR_API_ID' -U
security add-generic-password -a "che-telegram-all-mcp" -s "TELEGRAM_API_HASH" -w 'YOUR_API_HASH' -U

# Optional: 2FA password (auto-entered if your account has 2FA)
security add-generic-password -a "che-telegram-all-mcp" -s "TELEGRAM_2FA_PASSWORD" -w 'YOUR_2FA_PASSWORD' -U

# Optional: phone number (auto-entered to skip the prompt)
security add-generic-password -a "che-telegram-all-mcp" -s "TELEGRAM_PHONE" -w '+886912345678' -U

# 3. Authenticate (one-time; SMS code is the only thing you must enter live)
/auth
```

Don't want the bot server spawning at startup? Add this to `.claude/settings.json` in your project (or `~/.claude/settings.json` for user-wide):

```json
{
  "disabledMcpjsonServers": ["telegram-bot"]
}
```

### Track B — Bot only

You want a **bot** to post messages or receive commands. No personal account.

```bash
# 1. Install plugin
/plugin install che-telegram-mcp@psychquant-claude-plugins

# 2. Store bot token (get one from @BotFather in Telegram)
security add-generic-password -a "che-telegram-bot-mcp" -s "TELEGRAM_BOT_TOKEN" -w 'YOUR_BOT_TOKEN' -U

# 3. Disable the personal-account server (skip TDLib download entirely)
```

Add to `.claude/settings.json`:

```json
{
  "disabledMcpjsonServers": ["telegram-all"]
}
```

That's it — bot tools are now available without ever fetching the 223 MB TDLib binary.

### Track C — Both servers

You actually use both. Run all three keychain commands from Track A **plus** the one from Track B, then `/auth`. No `disabledMcpjsonServers` needed.

---

## How wrappers work

The plugin's wrappers (`bin/che-telegram-{all,bot}-mcp-wrapper.sh`) detect your installation in this order:

1. `~/bin/$BINARY_NAME`
2. `/usr/local/bin/$BINARY_NAME`
3. `~/.local/bin/$BINARY_NAME`
4. Source build at `~/Developer/che-msg/che-telegram-{all,bot}-mcp/.build/release/$BINARY_NAME`

If none are found on first invocation, the wrapper **lazy-downloads** the binary from the latest [GitHub Release](https://github.com/PsychQuant/che-msg/releases/latest), strips the macOS quarantine flag, and caches it in `~/bin/`. A disabled server never triggers a download.

### Auto-upgrade (v1.3.0+)

The wrapper pins a **`DESIRED_VERSION`** matching the binary the plugin expects and writes a `~/bin/.${BINARY_NAME}.version` sidecar each time it installs.

When the plugin is updated and the desired version changes, the wrapper detects the sidecar mismatch on the next MCP server spawn and atomically re-downloads (`.tmp` → `mv`) — falling back to the last installed binary if the network fails. Source builds under `~/Developer/...` are never auto-replaced.

A **SessionStart hook** (`hooks/check-mcp.sh`) verifies on every session that:

- Both binaries are installed (or buildable from source) — printing the installed version next to `✓`
- Required Keychain entries exist
- Compares the sidecar against `releases/latest` and prints `⬆️` when a newer release is available (silent when offline / rate-limited)

It prints `⚠️` warnings with copy-pasteable fix commands when something is missing. If you've disabled a server via `disabledMcpjsonServers`, you can ignore its warnings (the hook checks both servers regardless of disable state).

### Manual install (if auto-download fails)

```bash
mkdir -p ~/bin
curl -L https://github.com/PsychQuant/che-msg/releases/latest/download/CheTelegramAllMCP -o ~/bin/CheTelegramAllMCP
curl -L https://github.com/PsychQuant/che-msg/releases/latest/download/CheTelegramBotMCP -o ~/bin/CheTelegramBotMCP
chmod +x ~/bin/CheTelegramAllMCP ~/bin/CheTelegramBotMCP
xattr -dr com.apple.quarantine ~/bin/CheTelegramAllMCP ~/bin/CheTelegramBotMCP
```

> **Universal binary**: prebuilt binaries are Mach-O universal (arm64 + x86_64), so they run on both Apple Silicon and Intel Macs. Building from source: `git clone https://github.com/PsychQuant/che-msg.git && cd che-msg/che-telegram-all-mcp && swift build -c release`.

## Included Components

### MCP Servers

| Server | Identity | Read private chats | Full history | Search |
|--------|----------|-------------------|--------------|--------|
| `telegram-all` | Personal account (TDLib) | Yes | Yes | Yes |
| `telegram-bot` | Bot account (Bot API) | No (only chats the bot is in) | No (24h fetch window) | No |

### Skills

| Skill | Description |
|-------|-------------|
| `telegram-messaging` | Routes Claude to the right server (all vs bot) and walks through auth, reading, sending, search, history |

### Commands

| Command | Description |
|---------|-------------|
| `/auth` | Walk through one-time authentication for personal account |
| `/chats` | Show recent Telegram conversations |
| `/search` | Search Telegram message history |
| `/send` | Send a message to a chat |

## Usage Examples

```
/auth                            → Set up personal account (one-time)
/chats                           → See recent conversations
/search 會議紀錄                   → Search across chats
/send @alice "see you tomorrow"  → Send a message
```

Or just ask naturally:

- "What did Bob say in the project group last week?"
- "Send 'on my way' to Alice"
- "Dump my chat with Carol from January to a Markdown file"
- "Show me the last 50 messages from the dev channel"

## Available Tools

### `telegram-all` (Personal Account, TDLib) — 28 tools

**Auth (6)**: `auth_status`, `auth_run`, `auth_set_parameters`, `auth_send_phone`, `auth_send_code`, `auth_send_password`

**Read (8)**: `get_me`, `get_chats`, `get_chat`, `get_chat_history`, `search_chats`, `search_messages`, `get_chat_members`, `get_contacts`

**Write (5)**: `send_message`, `edit_message`, `delete_messages`, `forward_messages`, `mark_as_read`

**Manage (4)**: `pin_message`, `unpin_message`, `set_chat_title`, `set_chat_description`

**Group (2)**: `create_group`, `add_chat_member`

**Export (1)**: `dump_chat_to_markdown` — one-shot export with optional `since_date` / `until_date` / `max_messages`

**Other (2)**: `logout`, `get_user`

> v0.5.0 added `auth_run` — a single tool drives the entire auth state machine. See [v0.5.0 release notes](https://github.com/PsychQuant/che-msg/releases/tag/v0.5.0).

### `telegram-bot` (Bot API)

`get_me`, `get_updates`, `send_message`, `forward_message`, `get_chat`, `get_chat_administrators`, `get_chat_member_count`, `get_chat_member`, `set_chat_title`, `set_chat_description`, `pin_chat_message`, `unpin_chat_message`, `unpin_all_chat_messages`, `ban_chat_member`, `unban_chat_member`, `restrict_chat_member`, `promote_chat_member`, `leave_chat`, `delete_message`, `edit_message_text`, `copy_message`, `send_photo`, `send_document`, `send_video`, `send_audio`, `send_sticker`, `send_location`, `send_poll`, `set_my_commands`, `get_my_commands`, `delete_my_commands`

## Multi-session limitation

`telegram-all` uses [TDLib](https://core.telegram.org/tdlib), which keeps the session in a SQLite database with an exclusive WAL lock — **only one process can hold it at a time**. `telegram-bot` is not affected (Bot API is HTTP-based and stateless, so any number of Claude Code sessions can run it in parallel).

If you have **two or more Claude Code sessions open simultaneously**, only the first session can spawn `telegram-all`. The second session's wrapper detects the lock + refuses to start (preventing TDLib database corruption from concurrent writes).

### What you'll see in v1.3.2+

`/mcp` displays a human-readable error such as:

```
mcp__plugin_che-telegram-mcp_telegram-all: Another instance of CheTelegramAllMCP is already running (lock held by PID 11252). Use the existing Claude Code window, or kill the previous wrapper first.
```

The error envelope also carries `data.recoveryCommand` and `data.docsUrl` (this section) for clients that show structured error data.

### Recovery cookbook

When you need to free the lock for the current session:

```bash
# 1. Kill any running telegram-all binary (single instance assumption — safe).
#    Use `2>/dev/null` and `; ` (not `&&`) — the orphan-lock case (where
#    you most need recovery) has no process to kill, and `&&` would skip
#    the cleanup below. `; ` ensures the lock removal always runs.
pkill CheTelegramAllMCP 2>/dev/null

# 2. Remove BOTH lock variants. macOS without flock uses `.lock` directory;
#    Linux with flock uses `.lock.flock` file. The wrapper picks one at
#    runtime — recovery should clean both so it works on any platform.
rm -rf ~/.cache/che-telegram-all-mcp.lock ~/.cache/che-telegram-all-mcp.lock.flock

# 3. (Optional) Confirm no stale process holds TDLib DB files.
lsof ~/Library/Application\ Support/che-telegram-all-mcp/tdlib/db.sqlite 2>/dev/null

# 4. Restart Claude Code or run /mcp to reconnect.
```

Step 1 is graceful — the binary handles `SIGTERM` and `wait`s for TDLib to checkpoint the WAL before exiting. Step 2 removes the wrapper's atomic-claim guard (both `.lock` directory for mkdir mode and `.lock.flock` file for flock mode). After both, the next Claude Code session that spawns `telegram-all` will succeed.

### Pre-v1.3.2 symptom

If you're on `che-telegram-mcp` plugin **v1.3.1 or earlier**, the lock-refused branch only wrote to stderr (which Claude Code's MCP transport doesn't surface), so users would just see a generic `-32000 Server error` with no recovery hint. Upgrade to **v1.3.2+** for the human-readable message described above. See [#31](https://github.com/PsychQuant/che-msg/issues/31) for the diagnosis.

### Why we don't auto-clean stale binaries

Killing a TDLib process mid-write can corrupt the database (WAL checkpoint mid-flight). The wrapper deliberately requires manual intervention so the user — who knows whether the other Claude Code session is genuinely abandoned or just backgrounded — makes the destructive call.

## Permissions

This plugin requires:

- **macOS Keychain** access for credential storage
- **Network** access for the Telegram API
- **Disk** access for TDLib's local database (`~/Library/Application Support/che-telegram-all-mcp/`) — only used by `telegram-all`

## Version

Plugin version: 1.3.2 (currently pins `che-telegram-all-mcp` v0.5.0 + `che-telegram-bot-mcp` v0.5.0 binaries; wrapper auto-upgrades on version mismatch)

### Changelog

**1.3.2** (2026-05-21)

- **Lock-refused branch emits MCP JSON-RPC error envelope to stdout** (refs [che-msg#31](https://github.com/PsychQuant/che-msg/issues/31)). When a second Claude Code session tries to spawn `telegram-all` while a stale session still holds the TDLib lock, the wrapper now writes a `{"jsonrpc":"2.0","id":null,"error":{...}}` envelope to stdout before exit. Claude Code's MCP client surfaces `error.message` (e.g. `"Another instance of CheTelegramAllMCP is already running (lock held by PID 11252). Use the existing Claude Code window, or kill the previous wrapper first."`) instead of generic `-32000 Server error`. `error.data` carries `lockHolderPid`, `recoveryCommand`, and `docsUrl`.
- **Multi-session limitation README section** documents the TDLib upstream constraint + recovery cookbook + Strategy B/C explicit non-decisions.
- **Recovery cookbook hardened**: `pkill ... ; rm -rf ...` (semicolon, not `&&`) so cleanup runs even when no process exists to kill — the orphan-lock case is exactly when cleanup matters most. Also covers both `.lock` (mkdir mode) and `.lock.flock` (flock mode) paths.

**1.3.1** (2026-05-07)

- **Atomic-claim lock**: wrapper now uses `flock` (Linux) or `mkdir` (macOS fallback) to prevent two simultaneous wrappers from racing the TDLib lock. Second wrapper fail-fast with stderr message instead of silent SIGTERM cross-fire. Stale-lock cleanup removes orphaned locks whose owner PID is dead. New regression test (`test-wrapper-pid.sh` test 9). Resolves [#10](https://github.com/PsychQuant/psychquant-claude-plugins/issues/10).

**1.3.0** (2026-04-28)

- **Auto-upgrade wrappers**: each wrapper now pins a `DESIRED_VERSION` and writes a `~/bin/.${BINARY_NAME}.version` sidecar on install. When the plugin bumps the desired version, the wrapper detects the sidecar mismatch and atomically re-downloads (`.tmp` → `mv`) on next spawn. Source builds in `~/Developer/...` are never auto-replaced. Falls back to the existing binary on network failure (no brick).
- **SessionStart hook upgrade notice**: `check-mcp.sh` now reads the sidecar to display installed version, queries `releases/latest`, and prints `⬆️ v0.4.3 → v0.5.0 available` when behind upstream. Silent when offline or rate-limited.
- Pin telegram-bot binary at v0.5.0 (built from same monorepo as telegram-all v0.5.0).

**1.2.1** (2026-04-27)

- Fix `hooks/check-mcp.sh` source-build path: previously pointed at `~/Developer/che-mcps/che-msg/.build/release/...`, which doesn't exist (che-msg is a monorepo, the Swift packages live in sub-dirs `che-telegram-all-mcp/` and `che-telegram-bot-mcp/`). Now mirrors the wrapper's exact 5-path search (incl. `~/Developer/che-msg/<package>/.build/release/<binary>`).
- Fix `check-mcp.sh` build instruction: was `cd che-msg && swift build -c release` (no Package.swift at monorepo root), now `cd ~/Developer/che-msg/<package> && swift build -c release --product <binary>`.
- `check-mcp.sh` no longer warns about optional Keychain entries (`TELEGRAM_PHONE`, `TELEGRAM_2FA_PASSWORD`); they're shown only when present and silently skipped when absent.
- `check-mcp.sh` footer now documents `disabledMcpjsonServers` so users running only one server know how to suppress the other's warnings.

**1.2.0** (2026-04-27)

- Documentation restructure: explicit "Two paths, one plugin" framing with three quickstart tracks (personal-account only / bot only / both)
- README now documents how to disable an unused server via `disabledMcpjsonServers` in `settings.json`
- Skill (`telegram-messaging`) restructured to route between `telegram-all` and `telegram-bot` with server-specific tool guidance
- Skill `allowed-tools` removed: previous list used the wrong namespace prefix (`mcp__che-telegram-mcp__*` vs actual `mcp__plugin_che-telegram-mcp_telegram-{all,bot}__*`), so the allowlist was effectively ignored. Without it, plugin tools are accessible normally.

**1.1.0** (2026-04-16)

- Wrappers auto-download binaries from GitHub Release if not installed locally
- Wrapper PID tracking refinements (Test 7 SIGKILL race fix)
- Currently bundles `che-telegram-all-mcp` v0.4.3, which closes [PsychQuant/che-telegram-all-mcp#1](https://github.com/PsychQuant/che-telegram-all-mcp/issues/1) — TDLib auth error handling overhaul (structured `code`/`message` errors, snake_case decoder regression test, code 406 silent-ignore per protocol)

**1.0.2** (earlier)

- Wrapper PID tracking added

## Source

- Plugin source: [PsychQuant/psychquant-claude-plugins](https://github.com/PsychQuant/psychquant-claude-plugins/tree/main/plugins/che-telegram-mcp)
- Binary source: [PsychQuant/che-msg](https://github.com/PsychQuant/che-msg) — also mirrored at [PsychQuant/che-telegram-all-mcp](https://github.com/PsychQuant/che-telegram-all-mcp) for the personal-account MCP

## Author

Created by **Che Cheng** ([@kiki830621](https://github.com/kiki830621))
