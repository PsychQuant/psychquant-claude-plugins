---
name: search
description: Search Telegram message history
allowed-tools:
  - mcp__che-telegram-mcp__auth_status
  - mcp__che-telegram-mcp__search_chats
  - mcp__che-telegram-mcp__search_messages
  - mcp__che-telegram-mcp__get_chat_history
---

# Search Telegram Messages

1. Check `auth_status`
2. If user specified a chat name, use `search_chats` to find the chat ID
3. Use `search_messages` with the query in the target chat
4. If no specific query, use `get_chat_history` to browse recent messages
5. Present results with sender, date, and message content
