---
name: new-note
description: Quickly create an Apple Notes note from a description
allowed-tools:
  - mcp__che-apple-notes-mcp__list_folders
  - mcp__che-apple-notes-mcp__create_note
---

# New Note

Create a new Apple Notes note. If the user hasn't specified a folder, either use
the default folder or ask (prefer defaulting).

Usage examples the user might write:
- `/new-note Shopping list: milk, eggs, bread`
- `/new-note title: Meeting notes, body: ...`
- `/new-note in Work folder: reminder to ship the release`

Steps:
1. Parse the user's request for title, body, and optional folder.
2. If folder is mentioned, optionally call `list_folders` to verify it exists
   (skip for speed when the folder is common like "Notes" or "Work").
3. Call `create_note` with `body_text` (not HTML) unless the user provided HTML.
4. Report the returned id and folder.

Use Chinese or the user's language when writing the note body.
