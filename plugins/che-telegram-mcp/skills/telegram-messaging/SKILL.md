---
name: telegram-messaging
description: Guide for using Telegram MCP tools to read chats, send messages, search history, and manage groups. Use when user asks about Telegram messages, chats, or contacts.
allowed-tools:
  - mcp__che-telegram-mcp__auth_status
  - mcp__che-telegram-mcp__auth_set_parameters
  - mcp__che-telegram-mcp__auth_send_phone
  - mcp__che-telegram-mcp__auth_send_code
  - mcp__che-telegram-mcp__auth_send_password
  - mcp__che-telegram-mcp__logout
  - mcp__che-telegram-mcp__get_me
  - mcp__che-telegram-mcp__get_user
  - mcp__che-telegram-mcp__get_contacts
  - mcp__che-telegram-mcp__get_chats
  - mcp__che-telegram-mcp__get_chat
  - mcp__che-telegram-mcp__search_chats
  - mcp__che-telegram-mcp__get_chat_history
  - mcp__che-telegram-mcp__send_message
  - mcp__che-telegram-mcp__edit_message
  - mcp__che-telegram-mcp__delete_messages
  - mcp__che-telegram-mcp__forward_messages
  - mcp__che-telegram-mcp__search_messages
  - mcp__che-telegram-mcp__get_chat_members
  - mcp__che-telegram-mcp__pin_message
  - mcp__che-telegram-mcp__unpin_message
  - mcp__che-telegram-mcp__set_chat_title
  - mcp__che-telegram-mcp__set_chat_description
  - mcp__che-telegram-mcp__create_group
  - mcp__che-telegram-mcp__add_chat_member
  - mcp__che-telegram-mcp__mark_as_read
---

# Telegram Messaging

This skill covers the **telegram-all** MCP (personal account via TDLib). It can read all chats, send messages, and search full history.

## Authentication

Authentication is **one-time**. Session persists in `~/Library/Application Support/che-telegram-all-mcp/tdlib/`.

**Always check `auth_status` first.** If "ready", skip auth. If not:
```
auth_set_parameters → auto-loaded from Keychain
auth_send_phone     → user provides phone (+886...)
auth_send_code      → user provides verification code
auth_send_password  → only if 2FA enabled
```

## Tool Categories

### 1. Discovery (Start Here)
| Tool | Purpose |
|------|---------|
| `get_chats` | List recent conversations (limit param) |
| `search_chats` | Find chat by name |
| `get_chat` | Get details of a specific chat |
| `get_contacts` | List saved contacts |

### 2. Reading Messages
| Tool | Purpose |
|------|---------|
| `get_chat_history` | Read message history (chat_id, limit, from_message_id) |
| `search_messages` | Search within a chat by keyword |

### 3. Sending Messages
| Tool | Purpose |
|------|---------|
| `send_message` | Send text to a chat |
| `edit_message` | Edit your own sent message |
| `forward_messages` | Forward messages between chats |
| `delete_messages` | Delete messages |

**CRITICAL**: Always confirm with user before `send_message`, `delete_messages`, or `forward_messages`. These actions affect real conversations.

### 4. Group Management
| Tool | Purpose |
|------|---------|
| `get_chat_members` | List group members |
| `create_group` | Create a new group |
| `add_chat_member` | Add member to group |
| `pin_message` / `unpin_message` | Pin/unpin messages |
| `set_chat_title` / `set_chat_description` | Edit group info |

## Common Workflows

### Read Recent Messages
```
1. get_chats(limit: 10)           → find the chat
2. get_chat_history(chat_id, limit: 20) → read messages
```

### Search for Something
```
1. search_chats(query: "name")    → find the chat
2. search_messages(chat_id, query: "keyword") → find messages
```

### Send a Message
```
1. search_chats(query: "recipient") → find chat_id
2. CONFIRM with user               → show recipient + message
3. send_message(chat_id, text)     → send
```

## Security Notes

- This MCP operates as the user's **personal Telegram account**
- It can read **all** private chats — handle content with care
- Never log or store message content beyond the current conversation
- Always get explicit user confirmation before sending messages
