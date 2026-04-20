---
name: notes-management
description: Guide for effective use of che-apple-notes-mcp for macOS Apple Notes management. Use when user asks about Apple Notes, 備忘錄, note taking on Mac, creating/searching/organizing notes.
allowed-tools:
  - mcp__che-apple-notes-mcp__list_folders
  - mcp__che-apple-notes-mcp__create_folder
  - mcp__che-apple-notes-mcp__update_folder
  - mcp__che-apple-notes-mcp__delete_folder
  - mcp__che-apple-notes-mcp__list_notes
  - mcp__che-apple-notes-mcp__list_notes_quick
  - mcp__che-apple-notes-mcp__get_note
  - mcp__che-apple-notes-mcp__create_note
  - mcp__che-apple-notes-mcp__update_note
  - mcp__che-apple-notes-mcp__delete_note
  - mcp__che-apple-notes-mcp__move_note
  - mcp__che-apple-notes-mcp__search_notes
  - mcp__che-apple-notes-mcp__create_notes_batch
  - mcp__che-apple-notes-mcp__move_notes_batch
  - mcp__che-apple-notes-mcp__delete_notes_batch
  - mcp__che-apple-notes-mcp__undo
  - mcp__che-apple-notes-mcp__redo
  - mcp__che-apple-notes-mcp__undo_history
---

# macOS Apple Notes Management

Guide for operating Apple Notes.app via `che-apple-notes-mcp`.

## Architecture at a Glance

| Operation | Path | Speed | Needs |
|-----------|------|-------|-------|
| Read (list/get/search) | SQLite direct | <10 ms | Full Disk Access |
| Write (create/update/delete/move) | AppleScript | ~50 ms | Automation permission |
| Read (fallback) | AppleScript | ~500 ms | Automation permission only |

If Full Disk Access is not granted, read ops transparently fall back to AppleScript.

## Body Format (Dual-Track)

**Input**: provide `body_text` OR `body_html` (not both):

```
create_note(
  title: "Meeting notes",
  body_text: "Plain text with\nnewlines",   # will be wrapped in <div>
  folder: "Work"
)
```

```
create_note(
  title: "Styled",
  body_html: "<h1>Heading</h1><p>With <b>bold</b></p>",
  folder: "Work"
)
```

**Output**: `get_note` and `list_notes(include_body=true)` return both forms:

```
{
  "id": "x-coredata://...",
  "title": "Meeting notes",
  "body_text": "Plain text with\nnewlines",
  "body_html": "<div>Plain text with<br>newlines</div>",
  ...
}
```

## Tool Categories

### Discovery (start here)

- `list_folders` — see all folders and their account (iCloud / On My Mac)
- `list_notes_quick` with `range: "recent" | "today" | "this_week" | "pinned"` — common views
- `search_notes` — keyword search (title + snippet)

### Folders

| Task | Tool |
|------|------|
| List | `list_folders` (optional `account` filter) |
| Create | `create_folder(title, account?)` |
| Rename | `update_folder(id, title)` |
| Delete | `delete_folder(id)` — empty folders only |

### Notes CRUD

| Task | Tool | Key params |
|------|------|------------|
| List | `list_notes` | folder, folder_id, account, pinned, locked, include_body, limit, sort |
| Get | `get_note` | id |
| Create | `create_note` | title, body_text XOR body_html, folder?, account? |
| Update | `update_note` | id, title?, body_text? / body_html? |
| Delete | `delete_note` | id |
| Move | `move_note` | id, folder, account? |

### Batch (more efficient than multiple single calls)

- `create_notes_batch(notes: [{title, body_text?, body_html?, folder?, account?}, ...])`
- `move_notes_batch(ids: [...], folder, account?)`
- `delete_notes_batch(ids: [...])`

### Undo/Redo (process-local)

- `undo` — revert last write
- `redo` — reapply an undone write
- `undo_history` — show stack

## Source Disambiguation

When folder names collide across accounts (e.g., "Notes" on iCloud and On My Mac):

```
create_note(
  title: "Shopping list",
  body_text: "milk, eggs",
  folder: "Notes",
  account: "iCloud"    # disambiguate
)
```

Available accounts can vary: `iCloud`, `On My Mac`, plus any configured accounts. Use `list_folders` to inspect.

## ID Formats

- `id` field returned by SQLite path = AppleScript URL form: `x-coredata://<account-uuid>/ICNote/p<PK>`. Use this directly for `update_note`, `delete_note`, `move_note`.
- `uuid` field = raw ZIDENTIFIER (just the note's UUID). For debugging / advanced consumers.

## Common Workflows

### Capture a quick note

```
create_note(title: "Idea", body_text: "The thing I just thought of", folder: "Notes")
```

### Daily review

```
1. list_notes_quick(range: "today")  → see today's notes
2. list_notes_quick(range: "pinned") → see pinned items
```

### Find and update

```
1. search_notes(keyword: "project X")
2. get_note(id: <first result>)
3. update_note(id: ..., body_text: "<appended content>")
```

### Bulk reorganize

```
1. list_notes(folder: "Inbox")          → collect ids
2. move_notes_batch(ids, folder: "Archive")
```

## Performance Tips

1. **Default to metadata-only listing** — only pass `include_body: true` when you need body (each body requires GZIP inflate + protobuf decode, ~1ms per note).
2. **Prefer `list_notes_quick`** over `list_notes` for common ranges.
3. **Batch writes** cut AppleScript dispatch overhead from ~50ms × N to a single dispatch.
4. **Search via `search_notes`** beats listing and filtering in the caller.

## Known Limits (v0.1.0)

- Locked notes: body is AES-encrypted and cannot be decoded — `{locked: true, body: null}`.
- Note pinning: read-only (AppleScript does not expose the `pinned` attribute for writes).
- Attachment writes: not supported (read-only via `list_notes` metadata).
- Body HTML decoded from SQLite falls back to plaintext for formatting beyond bold/italic/link/list (v0.2.0 will render full attribute runs). Read via AppleScript for full HTML fidelity.
- Large bodies: hard-capped at 1 MB; split into multiple notes.

## First-Run Setup

Users must run `~/bin/CheAppleNotesMCP --setup` once to:

1. Get prompted for Automation permission to Notes.app (click Allow when the dialog appears)
2. See whether Full Disk Access is granted (if not, follow the printed instructions to enable — optional but much faster)

Without Full Disk Access: read ops fall back to AppleScript, ~50–500× slower but still functional. Features `list_notes_quick`, `search_notes` require SQLite and will error if FDA is missing.
