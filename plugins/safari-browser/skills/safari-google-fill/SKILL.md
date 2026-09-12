---
name: safari-google-fill
description: Fill Google Forms in Safari, verify section changes, and hand off file-upload pickers. Use for Google Forms questionnaires, registrations, or submissions in Safari.
allowed-tools:
  - Bash(safari-browser:*)
  - Bash(safari-browser *)
---

## When to use

Use for a Google Form the user wants to complete in Safari, especially multi-section forms with file-upload questions. This playbook is scoped to Forms, not other Google applications. It records a DOM/Picker boundary; it does not promise unattended file uploads or submissions.

## Preconditions

- The user supplied the form and intended answers/files. Determine whether their existing request authorizes filling, uploading and submitting; reuse that authorization instead of asking again.
- Safari has the correct signed-in Google account and access to the form. File-upload questions require sign-in; check the displayed file count/type/size restrictions against the specified file.
- Use the main Safari skill's command-result handling: inspect each exit code and full stderr, beginning with the first line. Stop on failures or blocking warnings; do not discard diagnostics.
- The supplied form is open in Safari (open its URL first if that is already authorized). Run `safari-browser documents --json`, select the actual form tab and set `FORM` to a unique, observed form-ID path prefix that survives `viewform`/`formResponse` changes. Do not use a changing query parameter or terminal page name as the lock. For a short link, identify the resolved form tab first. Resolve duplicate matches explicitly and rediscover the target after an unexpected redirect; do not use `--first-match` to guess.
- Example variables `TEXT_REF`, `CHOICE_REF`, `NEXT_REF` and `ANSWER` must come from the current snapshot and the user's prepared content, not from the numeric examples in another session.

## Steps

1. Inspect the current section and visible question types:
   ```bash
   : "${FORM:?Set FORM to the verified unique form URL substring}"
   safari-browser snapshot --page --url "$FORM"
   ```
   Expected: the form's current section and actual controls are readable. A visible “Add file” / “新增檔案” control or file restriction is evidence of an upload question even when no `input[type=file]` or textarea is present. Private `FB_PUBLIC_LOAD_DATA_` codes are not authoritative.

2. Fill a verified text control and read back its displayed value:
   ```bash
   : "${TEXT_REF:?Use a current text-control reference}" "${ANSWER?Use the user's prepared answer}"
   safari-browser fill "$TEXT_REF" "$ANSWER" --url "$FORM"
   safari-browser snapshot --page --url "$FORM"
   ```
   Expected: the intended question shows that answer. For a single-choice question, use a fresh observed option reference:
   ```bash
   : "${CHOICE_REF:?Use the intended current choice reference}"
   safari-browser click "$CHOICE_REF" --url "$FORM"
   safari-browser snapshot --page --url "$FORM"
   ```
   Expected: that option is visibly selected. Do not infer selection from exit zero or text that could match another question.

3. Advance one section only after its answers and validation state are correct:
   ```bash
   : "${NEXT_REF:?Use the current Next control reference}"
   safari-browser click "$NEXT_REF" --url "$FORM"
   safari-browser snapshot --page --url "$FORM"
   ```
   Expected: the intended next section heading/questions appear. Forms can update in place with no URL change. A change in body-text length is only a clue; validate the actual section. If the section does not advance, inspect required-field errors or intentional branching before another click. Refresh references after each section change.

4. At a file-upload question, this playbook hands file selection to the user. Inspect the visible control and restrictions. If there is no usable file input, do not call `upload` with a guessed selector or put the document's text into an unrelated field. If opening Add file is already authorized, click its observed reference once and inspect the resulting page/dialog state. When the current DOM path cannot access the Picker (including a cross-origin frame boundary), hand off:
   > Please choose the specified file in the Google file picker and wait for upload to finish. Let me know when the attachment appears; I will verify it before continuing.
   Pause for that action. Do not synthesize keyboard input, invent selectors inside inaccessible frames, repeatedly reopen the picker, or bypass origin restrictions. After the user finishes, take a fresh snapshot and verify the expected filename/attachment and that upload is no longer pending. User takeover might also navigate or submit: inspect the current state before resuming.

5. Recheck the remaining answers and attachments. Submit only if the user's existing request authorizes it; otherwise obtain the missing instruction after preparing the form for review. Use the current observed Submit reference once, then inspect the actual confirmation state. If the user already submitted during takeover, do not submit again. A timeout or ambiguous response is a reason to inspect, not automatically replay the action.

## Error handling

- Wrong account, access denial, closed form or file restrictions: report the specific visible condition and let the user resolve it. Do not substitute another account/file or contact the form owner without authorization.
- Nonzero CLI exit or `⚠ BLOCKING DIALOG`: stop later steps, inspect `dialog list`, and select a named choice only within the user's intent. An incomplete/failed probe does not prove absence.
- Picker not readable through the current DOM path: stop at the handoff above. Whether an iframe is accessible depends on its origin and current structure; do not generalize one session's cross-origin failure to every Picker.
- A `formResponse` URL appears, or click returns `undefined`: neither establishes submission nor non-submission. Check the visible form/confirmation state and ask what the user did during takeover if needed. Do not retry Submit to find out.

## Verification

Verify field values, selected choices, section transitions and attachment filenames from the current page after each action. For final submission, require the form's actual confirmation state—such as its customized response-recorded message together with the transition away from editable questions—not a URL pattern or a matching word somewhere in a question. If confirmation cannot be observed, report the submission as unverified.

## Gotchas

- Multi-section transitions can be SPA updates; unchanged `location.href` does not mean Next failed. Google also supports intentional branching back to earlier sections.
- Upload questions can expose only an Add file control before the picker is created. Do not infer “paragraph text” from a private type code, absence of `input[type=file]`, or an internal data array.
- In the source incident, an upload trigger introduced a dialog/iframes and a `formResponse` URL was observed. Its cause was not established. The rule above deliberately avoids claiming it was a normal session side effect or proof of no submission.
- Official references: [Forms response/upload troubleshooting](https://support.google.com/docs/answer/15473134?hl=en) documents sign-in and file restrictions; [Google Picker documentation](https://developers.google.com/workspace/drive/picker/guides/web-picker) describes its file-selection UI and iframe integration. These do not establish the incident's URL-transition cause. Observations and instructions last reviewed 2026-09-12.
