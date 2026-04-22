# che-apple-notes-mcp

macOS Apple Notes MCP plugin. Wraps [CheAppleNotesMCP](https://github.com/PsychQuant/che-apple-notes-mcp) — a native Swift binary that reads via SQLite (fast path) and writes via AppleScript (CloudKit-safe).

## Features

- **24 MCP tools** covering folders, notes CRUD, search, batch ops, undo/redo, and **CloudKit sharing visibility**
- **SQLite fast read**: `list_notes` over 1000+ notes in <10 ms vs ~5 s with AppleScript
- **AppleScript safe write**: CloudKit sync untouched
- **Dual-track body**: accept plaintext or HTML on input; return both on read
- **Shared note/folder awareness**: every read emits `shared: Bool`; filter collections via `shared: true|false`
- **Share metadata + workflow helpers** (v0.2.0): read `ZICINVITATION` without deserializing the CKShare BLOB, and trigger Notes.app's native Share sheet for manual invitation
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
| Automation → Notes.app | All write tools + workflow helpers | Prompt appears on first write |
| Full Disk Access (recommended) | SQLite fast reads + `shared` filter + `get_share_metadata` | System Settings → Privacy & Security → Full Disk Access, add `~/bin/CheAppleNotesMCP` |

## Tools (24)

### Folders (4)
- `list_folders` (supports `shared: bool?` filter)
- `create_folder`, `update_folder`, `delete_folder`

### Notes CRUD (7)
- `list_notes` (supports `shared: bool?` filter), `list_notes_quick`, `get_note`
- `create_note`, `update_note`, `delete_note`, `move_note`

### Search (1)
- `search_notes` (supports `shared: bool?` filter)

### Batch (3)
- `create_notes_batch`, `move_notes_batch`, `delete_notes_batch`

### Sharing (3, new in v0.2.0)
- `get_share_metadata` — read `ZICINVITATION` (shareURL, invitation counts, receivedDate, serverShareDataPresent) without touching the CKShare BLOB
- `prepare_share_note` — activate Notes.app, focus a note, open `File → Share Note…` (user completes invitation manually)
- `prepare_share_folder` — same flow for folders (`Share Folder…`)

### Undo/Redo (3, process-local)
- `undo`, `redo`, `undo_history`

> All read tools now emit `shared: Bool` on every folder/note (derived from AppleScript `shared` property + SQLite heuristic on `ZSERVERSHAREDATA` / `ZZONEOWNERNAME`).

## Slash Commands

- `/new-note` — quickly create a note
- `/search-notes` — search and show results
- `/list-folders` — view folder hierarchy

## Skill

`notes-management` auto-loads when the conversation mentions Apple Notes, 備忘錄, or note-taking on Mac.

## Known Limits

- Locked notes: body is AES-encrypted and cannot be read.
- Pinning: read-only (AppleScript doesn't expose `pinned` for writes).
- Attachments: read-only metadata (no upload/replace).
- Body HTML from SQLite: falls back to plaintext for formatting beyond common inline styles. AppleScript path returns full HTML fidelity.
- Large bodies: 1 MB cap per note.
- **CloudKit share creation / invitation / revocation**: explicitly NOT implemented — Notes.app's CKContainer is private; no public API path exists. The `prepare_share_*` workflow helpers are the intended escape valve (Path D per `openspec/specs/apple-notes-sharing-workflow/`).

## Version History

See [CHANGELOG.md](https://github.com/PsychQuant/che-apple-notes-mcp/blob/main/CHANGELOG.md) on the upstream repo.

- **v0.2.0** (2026-04-22) — 6 new tools for Apple Notes sharing, `shared: Bool` on all reads, 112 unit + 11 E2E tests
- **v0.1.0** (2026-04-21) — initial release, 18 tools, dual-track architecture

## License

MIT © Che Cheng
