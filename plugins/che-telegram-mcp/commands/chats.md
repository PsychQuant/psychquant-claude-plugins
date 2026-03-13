---
name: chats
description: Show recent Telegram conversations
allowed-tools:
  - mcp__che-telegram-mcp__auth_status
  - mcp__che-telegram-mcp__get_chats
---

# Recent Telegram Chats

1. Check auth status with `auth_status` — if not "ready", guide the user through authentication
2. Use `get_chats` to list recent conversations (default limit: 20)
3. Present chats grouped by type (private, group, channel) with last message preview
