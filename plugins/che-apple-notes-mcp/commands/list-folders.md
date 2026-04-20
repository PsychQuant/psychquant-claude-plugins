---
name: list-folders
description: List all Apple Notes folders grouped by account
allowed-tools:
  - mcp__che-apple-notes-mcp__list_folders
---

# List Folders

Call `list_folders` and present the result grouped by account (iCloud / On My Mac).

Show:
- Account name as heading
- Folder names as a list
- Note counts if easy to obtain (or skip — keep it fast)

Hide folders where `is_hidden` is true (system containers).
