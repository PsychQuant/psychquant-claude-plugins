# che-apple-mail-mcp

macOS Apple Mail MCP server with native AppleScript integration.

## Features

- List accounts, mailboxes, and emails
- Search emails with UTF-8 support (Swift-layer filtering)
- Read, reply, forward emails
- Manage drafts, attachments, rules
- Flag, move, delete operations
- VIP senders and signatures

## Commands

### `/archive-mail` — 歸檔郵件到 Markdown

把指定聯絡人的 Apple Mail 郵件批次歸檔為 Markdown 檔案，自動去重。

```bash
# Explicit filter mode (available now)
/archive-mail some@example.com
/archive-mail some@example.com communications
```

> **Roadmap — zero-arg mode (not yet implemented, tracked in #13)**
> Planned: `/archive-mail` (no args) will read `.claude/emails.md` frontmatter for
> filters / output_dir / last_archived / exclude_mailboxes. Do **not** call it
> without args today — it requires a filter parameter.

詳細 spec 見 [`commands/archive-mail.md`](commands/archive-mail.md)。

## Installation

### Option 1: From Release (Recommended)

```bash
# Download latest release
curl -L https://github.com/kiki830621/che-apple-mail-mcp/releases/latest/download/CheAppleMailMCP -o ~/bin/CheAppleMailMCP
chmod +x ~/bin/CheAppleMailMCP
```

### Option 2: Build from Source

```bash
cd /path/to/che-apple-mail-mcp
swift build -c release
cp .build/release/CheAppleMailMCP ~/bin/
```

## Usage Notes

### i18n Best Practices

This MCP follows internationalization best practices:

1. **Use `list_mailboxes` first** to discover available mailbox names for your locale
2. **Standard English names** (`INBOX`, `Drafts`, `Sent`) will try AppleScript system properties
3. **Localized names** (e.g., `收件匣`) should be used exactly as returned by `list_mailboxes`

### Example Workflow

```
# Step 1: Discover mailboxes
list_mailboxes(account="your@email.com")
# Returns: 收件匣, 草稿, 寄件備份, ...

# Step 2: Use exact name
search_emails(account="your@email.com", mailbox="收件匣", query="keyword")
```

## Permissions Required

- **Full Disk Access** or **Mail** permission in System Settings > Privacy & Security
- Grant access when prompted on first run

## Source Code

https://github.com/kiki830621/che-apple-mail-mcp
