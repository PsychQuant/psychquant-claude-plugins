---
name: gfh-import
description: Import a Google Drive file into a GiftHub repo — move to LFS folder, create pointer, and pull. Use when user says "download recording", "import video", "把 Drive 檔案拉下來", "gfh import".
allowed-tools:
  - Bash
  - Read
  - Grep
  - Glob
---

# /gfh-import — Import Drive File into GiftHub

Move a Google Drive file into the GiftHub-LFS folder, create an LFS pointer via `gfh link`, and optionally pull the actual file.

## Prerequisites

- `.gfh.json` exists in repo root
- `gfh` CLI installed (`~/bin/gfh`)
- `gws` CLI installed (Google Workspace CLI)

## Execution

### Step 1: Read repo config

```bash
cat .gfh.json
```

Extract:
- `driveFolderId` — the GiftHub-LFS folder on Drive
- `registryPath` / `aliasRegistryPath` — alias file path

### Step 2: Determine source file

**If user provides a Drive file ID or URL:**
- Extract file ID from URL (format: `https://drive.google.com/file/d/{ID}/...`)
- Verify file exists: `gws drive files get --params '{"fileId":"ID","fields":"id,name,size,parents"}'`

**If user says "latest Meet recording" or similar:**
- Read project CLAUDE.md for Meet Recordings folder ID
- List recent files: `gws drive files list --params '{"q":"FOLDER_ID in parents","fields":"files(id,name,size,createdTime)","orderBy":"createdTime desc","pageSize":5}'`
- Ask user to confirm which file

### Step 3: Determine local path

**If user provides a local path:** use it directly.

**If not:** ask user. Suggest based on project conventions (e.g., from CLAUDE.md naming patterns).

### Step 4: Move + rename on Drive

Move the file from its current folder to the GiftHub-LFS folder, and rename if needed:

```bash
gws drive files update \
  --params '{"fileId":"FILE_ID","addParents":"GFH_FOLDER_ID","removeParents":"SOURCE_FOLDER_ID"}' \
  --json '{"name":"NEW_NAME.mp4"}'
```

- `addParents`: GiftHub-LFS folder ID (from `.gfh.json`)
- `removeParents`: the file's current parent folder ID (from Step 2 metadata)
- `name`: new filename matching project convention

**Skip if file is already in the GiftHub-LFS folder.**

### Step 5: Create LFS pointer via `gfh link`

```bash
gfh link "FILE_ID" "LOCAL_PATH"
```

This will:
1. Stream the file from Drive to compute SHA-256 (no full download needed)
2. Create a local pointer file (135 bytes)
3. Register the SHA → Drive ID alias in `lfs-registry-aliases.json`

### Step 6: Pull the actual file

```bash
gfh pull "LOCAL_PATH"
```

Downloads the full file from Drive, replacing the pointer.

### Step 7: Git add (optional)

Ask user if they want to stage the file:

```bash
git add "LOCAL_PATH"
```

### Step 8: Report

```
✅ Imported: {filename}
   Drive ID: {id}
   Local: {path}
   Size: {size}
   Status: hydrated (full file)
```

## Error Handling

- **`gfh link` fails**: Check if `gfh` version supports `link` (requires v0.3.0+). Suggest `~/bin/gfh version`.
- **`gfh pull` fails (500 from Drive)**: File may still be processing on Google's side (common with fresh Meet recordings). Suggest waiting 10-30 minutes and retrying, or manual browser download.
- **File already exists locally**: Ask user whether to overwrite or skip.

## Notes

- `gfh link` is preferred over downloading first + `gfh push`, because it avoids a full download-then-reupload cycle — the file stays on Drive, only the SHA is computed via streaming.
- Project-specific parameters (Meet folder ID, naming conventions, target directories) come from the project's CLAUDE.md, not this skill. This skill only handles the generic GiftHub import workflow.
