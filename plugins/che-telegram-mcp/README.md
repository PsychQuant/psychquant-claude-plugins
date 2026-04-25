# che-telegram-mcp Plugin

Claude Code plugin for Telegram — combines **Bot API** and **personal account (TDLib)** in one plugin. Credentials are stored in macOS Keychain, never in config files.

## Features

- **Two MCP Servers**: Personal account (TDLib) + Bot API in a single plugin
- **28+ MCP Tools**: Read/send messages, manage groups, search history, dump chats to Markdown
- **Skills**: Guided messaging workflow
- **Commands**: Quick shortcuts for auth, chats, search, send
- **Auto-download**: Wrappers fetch the latest binary from GitHub Release on first run
- **Setup check**: SessionStart hook warns if binaries or Keychain entries are missing
- **Keychain credentials**: API keys never written to config files

## Installation

### Step 1: Install the Plugin (Recommended)

```bash
/plugin install che-telegram-mcp@psychquant-claude-plugins
```

The plugin's wrappers will auto-download `CheTelegramAllMCP` and `CheTelegramBotMCP` from the latest [GitHub Release](https://github.com/PsychQuant/che-msg/releases/latest) on first use, install them to `~/bin/`, and strip the macOS quarantine flag.

If the marketplace is not yet added:

```bash
/plugin marketplace add https://github.com/PsychQuant/psychquant-claude-plugins
/plugin install che-telegram-mcp@psychquant-claude-plugins
```

### Step 2: Store Telegram Credentials in Keychain

Get your `api_id` and `api_hash` from [my.telegram.org](https://my.telegram.org).

```bash
# Personal account (TDLib)
security add-generic-password -a "che-telegram-all-mcp" -s "TELEGRAM_API_ID" -w 'YOUR_API_ID' -U
security add-generic-password -a "che-telegram-all-mcp" -s "TELEGRAM_API_HASH" -w 'YOUR_API_HASH' -U

# Optional: 2FA password (auto-entered if set)
security add-generic-password -a "che-telegram-all-mcp" -s "TELEGRAM_2FA_PASSWORD" -w 'YOUR_2FA_PASSWORD' -U

# Bot API (only if you use the bot server)
security add-generic-password -a "che-telegram-bot-mcp" -s "TELEGRAM_BOT_TOKEN" -w 'YOUR_BOT_TOKEN' -U
```

### Step 3: Authenticate (Personal Account)

After plugin install, run `/auth` and follow the prompts to enter your phone number and verification code. This is a one-time step — TDLib persists the session at `~/Library/Application Support/che-telegram-all-mcp/tdlib/`.

### Manual install (if auto-download fails)

```bash
mkdir -p ~/bin
curl -L https://github.com/PsychQuant/che-msg/releases/latest/download/CheTelegramAllMCP -o ~/bin/CheTelegramAllMCP
curl -L https://github.com/PsychQuant/che-msg/releases/latest/download/CheTelegramBotMCP -o ~/bin/CheTelegramBotMCP
chmod +x ~/bin/CheTelegramAllMCP ~/bin/CheTelegramBotMCP
xattr -dr com.apple.quarantine ~/bin/CheTelegramAllMCP ~/bin/CheTelegramBotMCP
```

> **arm64-only**: prebuilt binaries are Apple Silicon. Intel Mac users should build from source: `git clone https://github.com/PsychQuant/che-msg.git && cd che-msg/che-telegram-all-mcp && swift build -c release`.

## How It Works

The plugin's wrappers (`bin/che-telegram-{all,bot}-mcp-wrapper.sh`) detect your installation in this order:

1. `~/bin/$BINARY_NAME`
2. `/usr/local/bin/$BINARY_NAME`
3. `~/.local/bin/$BINARY_NAME`
4. Source build at `~/Developer/che-msg/che-telegram-{all,bot}-mcp/.build/release/$BINARY_NAME`

If none are found, the wrapper auto-downloads the binary from the latest GitHub Release.

A **SessionStart hook** (`hooks/check-mcp.sh`) verifies on every session that:

- Both binaries are installed (or buildable from source)
- Required Keychain entries exist

It prints `⚠️` warnings with copy-pasteable fix commands when something is missing.

## Included Components

### MCP Servers

| Server | Identity | Read private chats | Full history | Search |
|--------|----------|-------------------|--------------|--------|
| `telegram-all` | Personal account (TDLib) | Yes | Yes | Yes |
| `telegram-bot` | Bot account (Bot API) | No (only chats the bot is in) | No (24h fetch window) | No |

### Skills

| Skill | Description |
|-------|-------------|
| `telegram-messaging` | Guide for reading chats, sending messages, search, and history |

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

### `telegram-all` (Personal Account, TDLib)

**Auth (5)**: `auth_status`, `auth_set_parameters`, `auth_send_phone`, `auth_send_code`, `auth_send_password`

**Read (8)**: `get_me`, `get_chats`, `get_chat`, `get_chat_history`, `search_chats`, `search_messages`, `get_chat_members`, `get_contacts`

**Write (5)**: `send_message`, `edit_message`, `delete_messages`, `forward_messages`, `mark_as_read`

**Manage (4)**: `pin_message`, `unpin_message`, `set_chat_title`, `set_chat_description`

**Group (2)**: `create_group`, `add_chat_member`

**Export (1)**: `dump_chat_to_markdown` — one-shot export with optional `since_date` / `until_date` / `max_messages`

### `telegram-bot` (Bot API)

`get_me`, `get_updates`, `send_message`, `forward_message`, `get_chat_administrators`, `set_chat_title`

## Permissions

This plugin requires:

- **macOS Keychain** access for credential storage
- **Network** access for the Telegram API
- **Disk** access for TDLib's local database (`~/Library/Application Support/che-telegram-all-mcp/`)

## Version

Plugin version: 1.1.0 (currently bundles `che-telegram-{all,bot}-mcp` v0.4.3 binaries via wrapper auto-download)

### Changelog

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
