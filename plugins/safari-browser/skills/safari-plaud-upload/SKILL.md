---
name: safari-plaud-upload
description: Upload audio files to Plaud via Safari. Use when the user asks to upload a recording to Plaud, add tracks to a Plaud folder, or trigger Plaud transcription from a file that is already on disk.
allowed-tools:
  - Bash(safari-browser:*)
  - Bash(safari-browser *)
---

# safari-plaud-upload

Upload an audio file to Plaud via the user's already-logged-in Safari session.

## When to use

Trigger phrases:
- "upload this recording to Plaud"
- "add this audio to Plaud folder X"
- "send this file to Plaud for transcription"

Do NOT trigger for:
- Querying Plaud transcription status → use `plaud-transcriber:plaud-status` instead.
- Downloading transcripts → use `plaud-transcriber:plaud-download` instead.
- Chrome / non-Safari browser automation → use a Chrome-based tool.

## Preconditions

The user MUST satisfy all of these before the playbook runs:

1. **Logged in**: A Safari tab is open on `app.plaud.ai` (or the current Plaud web app origin) and the user is signed into their own Plaud account. If you see a login/SSO page, STOP and ask the user to sign in manually; do not type credentials.
2. **Target folder known**: The user has either (a) already navigated to the destination folder in that tab, or (b) told you the exact folder name to use.
3. **File on disk**: The audio file exists at a known absolute path. Supported formats follow Plaud's current restrictions (commonly `.mp3`, `.m4a`, `.wav`; confirm via Plaud's UI if unsure).
4. **No modal sheet blocking the tab**: Close any Plaud first-run tour, banner, or subscription prompt before uploading.

## Steps

Run each step and check the expected result before moving on. Target the Plaud tab explicitly with `--url plaud` so nothing depends on which Safari window is frontmost.

1. **Verify the Plaud tab is reachable**
   ```bash
   safari-browser get url --url plaud
   ```
   Expected: a URL on the Plaud origin. If multiple Plaud tabs exist, safari-browser fails with `ambiguousWindowMatch`; ask the user which window to use or pass `--window N` explicitly.

2. **Snapshot the page to find the upload control**
   ```bash
   safari-browser snapshot -i --url plaud
   ```
   Expected: a list of `@eN` refs including a clearly labelled upload button (text such as "Upload", "+", or a plus-icon affordance near the folder content area). Note the ref of the upload trigger.

3. **Click the upload trigger**
   ```bash
   safari-browser click @eN --url plaud
   ```
   Expected: a file picker opens OR an in-page drop zone becomes visible.

4. **Attach the file**

   Prefer the native file dialog (requires AX / Accessibility permission for safari-browser):
   ```bash
   safari-browser upload --native "input[type=file]" <absolute-path> --url plaud
   ```

   If AX is not granted OR the dialog is stubborn, fall back to JS:
   ```bash
   safari-browser upload --js "input[type=file]" <absolute-path> --url plaud
   ```
   Expected: the filename appears in Plaud's upload progress list or in the current folder's item list.

5. **Wait for upload to complete**
   ```bash
   safari-browser wait --for-text "Uploaded" --url plaud
   ```
   Expected: a progress indicator reaches 100% or a "Uploaded"/"Processed" status appears. Timeout defaults to 30s; adjust with `--timeout 120` for large files.

## Error handling

- **`ambiguousWindowMatch`**: The user has multiple Plaud tabs. Ask which one, or pass `--window N`.
- **File picker opens but upload is silent**: The element targeted by `input[type=file]` was wrong. Re-run `safari-browser snapshot -i --url plaud`, find the `<input>` with `data-testid` or `accept="audio/*"`, and retry.
- **Upload progress stalls at <100%**: Plaud's backend is slow or the file exceeds the current plan's limit. Surface the exact error message from `snapshot` — do NOT retry silently.
- **Quota exceeded banner**: STOP and tell the user; retrying will not fix it.
- **Login redirect mid-upload**: The session expired. STOP and ask the user to re-authenticate in Safari; do NOT attempt to type credentials.

## Verification

Success criteria — ALL must hold:

1. The filename appears in the target folder's item list (visible via a fresh `safari-browser snapshot -i --url plaud`).
2. The item's status is either "Processing", "Transcribing", or a terminal state such as "Ready" — not "Failed".
3. No error banner is visible anywhere on the page.

If any criterion fails, report it with the snapshot output rather than claiming success.

## Gotchas

- **Plan-specific limits**: Free-tier Plaud has lower file-size and duration limits than Pro. A failure on Free may "just work" on Pro without any UI change — check plan tier in Preconditions if uploads keep failing.
- **Folder vs library root**: Plaud treats the library root differently from folders (some uploads to root re-appear only after a manual refresh). Prefer uploading into a named folder.
- **Reactive title resets**: Plaud may reset `document.title` on navigation; a `🟢` ownership marker you set earlier will disappear. This is harmless; do not interpret it as the tab being "lost".
- **Large file memory**: The JS upload path (`--js`) loads the file into a JavaScript `DataTransfer` object and is constrained by the plugin's internal ~10MB cap. Use `--native` for anything larger; if AX is not granted, split the file or grant AX.
- **Two-tab race**: If the user has a second Plaud tab open in another window, a snapshot on the "wrong" one looks valid but clicks go nowhere because the target folder is on the other tab. Always pass `--url plaud` together with `--window N` when in doubt.
