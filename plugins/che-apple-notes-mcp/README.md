# che-apple-notes-mcp

macOS Apple Notes MCP plugin. Wraps [CheAppleNotesMCP](https://github.com/PsychQuant/che-apple-notes-mcp) — a native Swift binary that reads via SQLite (fast path) and writes via AppleScript (CloudKit-safe).

## Features

- **18 MCP tools** covering folders, notes CRUD, search, batch ops, undo/redo
- **SQLite fast read**: `list_notes` over 1000+ notes in <10 ms vs ~5 s with AppleScript
- **AppleScript safe write**: CloudKit sync untouched
- **Dual-track body**: accept plaintext or HTML on input; return both on read
- **Account disambiguation**: handle iCloud + On My Mac + other accounts
- **Graceful fallback**: read ops auto-downgrade to AppleScript if Full Disk Access is not granted

## Installation

Via marketplace:

```
claude plugin marketplace add kiki830621/psychquant-claude-plugins
claude plugin install che-apple-notes-mcp@psychquant-claude-plugins
```

The wrapper downloads the `CheAppleNotesMCP` binary from GitHub Releases on first use.

## First-Run Setup

```bash
~/bin/CheAppleNotesMCP --setup
```

This:
1. Probes Full Disk Access. If denied, prints instructions.
2. Dispatches a trivial AppleScript to trigger the Automation permission dialog for Notes.app.

**Optional but strongly recommended**: grant Full Disk Access to enable the SQLite fast path. Without it, reads work via AppleScript fallback (50–500× slower but correct).

## Permissions

| Permission | Why | How |
|------------|-----|-----|
| Automation → Notes.app | All write tools | Prompt appears on first write |
| Full Disk Access (recommended) | SQLite fast reads | System Settings → Privacy & Security → Full Disk Access, add `~/bin/CheAppleNotesMCP` |

## Tools (18)

### Folders
- `list_folders`, `create_folder`, `update_folder`, `delete_folder`

### Notes CRUD
- `list_notes`, `list_notes_quick`, `get_note`
- `create_note`, `update_note`, `delete_note`, `move_note`

### Search
- `search_notes`

### Batch
- `create_notes_batch`, `move_notes_batch`, `delete_notes_batch`

### Undo/Redo (process-local)
- `undo`, `redo`, `undo_history`

## Slash Commands

- `/new-note` — quickly create a note
- `/search-notes` — search and show results
- `/list-folders` — view folder hierarchy

## Skill

`notes-management` auto-loads when the conversation mentions Apple Notes, 備忘錄, or note-taking on Mac.

## Known Limits (v0.1.0)

- Locked notes: body is AES-encrypted and cannot be read.
- Pinning: read-only (AppleScript doesn't expose `pinned` for writes).
- Attachments: read-only metadata (no upload/replace).
- Body HTML from SQLite: falls back to plaintext for formatting beyond common inline styles. AppleScript path returns full HTML fidelity.
- Large bodies: 1 MB cap per note.

## License

MIT © Che Cheng
