# che-telegram-mcp Plugin

Claude Code plugin for Telegram — combines **Bot API** and **personal account (TDLib)** in one plugin. Credentials are stored in macOS Keychain, never in config files.

## Two MCP Servers

| Server | Identity | Read private chats | Full history | Search |
|--------|----------|-------------------|-------------|--------|
| `telegram-all` | Personal account | Yes | Yes | Yes |
| `telegram-bot` | Bot account | No | No | No |

## Installation

### Step 1: Build MCP Servers

**telegram-all** (requires TDLib, ~300MB first build):
```bash
cd ~/Developer/che-mcps
git clone https://github.com/kiki830621/che-telegram-all-mcp.git
cd che-telegram-all-mcp && swift build -c release
```

**telegram-bot** (lightweight):
```bash
cd ~/Developer/che-mcps
git clone https://github.com/kiki830621/che-telegram-bot-mcp.git
cd che-telegram-bot-mcp && swift build -c release
```

### Step 2: Store Credentials in Keychain

```bash
# telegram-all (get from https://my.telegram.org)
security add-generic-password -a che-telegram-all-mcp -s TELEGRAM_API_ID -w 'YOUR_API_ID' -U
security add-generic-password -a che-telegram-all-mcp -s TELEGRAM_API_HASH -w 'YOUR_API_HASH' -U

# telegram-bot (get from @BotFather)
security add-generic-password -a che-telegram-bot-mcp -s TELEGRAM_BOT_TOKEN -w 'YOUR_BOT_TOKEN' -U
```

### Step 3: Install Plugin

```bash
claude plugin add --from /path/to/psychquant-claude-plugins/plugins/che-telegram-mcp
```

### Step 4: First-time Authentication (telegram-all only)

On first use, authenticate your personal account:
1. Use `/auth` command or ask Claude to authenticate Telegram
2. Provide your phone number and verification code
3. Session is saved — won't need to authenticate again

## Commands

| Command | Description |
|---------|-------------|
| `/chats` | Show recent Telegram conversations |
| `/send` | Send a message (with confirmation) |
| `/search` | Search message history |
| `/auth` | One-time Telegram authentication |

## Security

- Credentials never appear in config files — always read from macOS Keychain at runtime
- Personal account access can read **all** private chats — use responsibly
- Messages are confirmed before sending
- Session data: `~/Library/Application Support/che-telegram-all-mcp/tdlib/`

## License

MIT
