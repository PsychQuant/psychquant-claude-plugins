## Why

The `/archive-mail` skill currently writes attachment **filenames** into the generated Markdown but never downloads the actual files. Discovered 2026-04-14 while archiving the tatsuma manuscript thread: `Attachments: Taxometric_Analysis_Submission_v3_20260408.docx, Figures & Tables20260408.docx` appeared in the body, but the `.docx` files stayed trapped inside Apple Mail's internal storage. Users wanting the files had to open Mail.app and manually drag them out.

The MCP server already has the needed capabilities (`list_attachments`, `list_attachments_batch`, `save_attachment`); the skill just never calls them.

Additionally, when attachments are eventually downloaded, they divide into two usage categories that deserve different locations:

- **Document attachments** (reference PDFs, manuscript docx, figures): belong in `correspondence/attachments/{email_stem}/` — logically tied to the email
- **Research data** (raw csv, indicator xlsx, SPSS sav, codebook): belong in `data/` or `data/raw/` — logically tied to the project, not the email

Mixing them makes data files hard to find in research workflows (researchers look for `data/`, not `correspondence/attachments/`).

This change is **Phase 1** of a 4-issue bundle addressing `archive-mail` attachment handling. It closes [`#23`](https://github.com/PsychQuant/psychquant-claude-plugins/issues/23) (download) and [`#26`](https://github.com/PsychQuant/psychquant-claude-plugins/issues/26) (routing). Phase 2 (`archive-mail-filter-and-audit`, closing `#24` filter asymmetry + `#25` coverage audit) ships separately after Phase 1 has been validated in practice.

## What Changes

- **New skill step** (between current Step 5 "Generate Markdown" and Step 6 "Update Index"): iterate archived emails, call `list_attachments_batch` to enumerate attachments, then `save_attachment` for each one
- **Filename preservation on disk**: attachment files keep their original bytes as filename (spaces, `&`, CJK, emoji all preserved). URL encoding is applied ONLY to the Markdown link URL (`%20` for space, `%26` for ampersand; everything else passes through)
- **Attachment block placement in Markdown**: inserted after the signature and before the thread quote (`差出人:` / `From:` separator), grouped per-email — matches the 2026-04-14 tatsuma backfill baseline
- **New attachment routing logic**: classify each attachment as `data` or `document` via a 3-tier precedence (config > keyword > extension), route to different output directories accordingly
- **New `.claude/emails.md` config block** `attachment_routing`: optional YAML with `data_extensions`, `document_extensions`, `data_keywords`, `document_keywords`, `data_dir`, `documents_dir` fields. Absent = use built-in defaults
- **Skill output report** extended: after archive, report `N attachments archived: M to <data_dir>, K to <documents_dir>`
- **Cross-reference for replies without attachments**: when a reply email's `list_attachments` returns empty but the body quotes an original's attachment markers, emit a cross-reference line in the reply's Markdown (e.g., `(Attachments on the original email from <sender> — see <original_stem>.md)`) instead of a broken link

## Non-Goals

<!-- Non-Goals live in design.md. -->

## Capabilities

### New Capabilities

- `archive-mail-attachments`: Defines how `/archive-mail` downloads attachment files from archived emails, where they are placed on disk (with data-vs-document routing), and how they are linked from the generated Markdown.

### Modified Capabilities

(none)

## Impact

- **Affected specs**:
  - New: `openspec/specs/archive-mail-attachments/spec.md`
- **Affected code**:
  - Modified: `plugins/che-apple-mail-mcp/commands/archive-mail.md` (202 → ~310 lines estimated after Phase 1)
  - Modified: `plugins/che-apple-mail-mcp/plugin.json` (version bump)
- **Config schema**:
  - New optional YAML block `attachment_routing` in `.claude/emails.md` (per-project override). Defaults apply when block is absent.
- **Affected users**: any caller of `/archive-mail`. Current behavior preserved when `attachment_routing` block is absent — attachments now download by default (this IS the fix), with data-vs-document heuristic applying built-in defaults. Users with existing archives: a separate `--backfill-attachments` flag is deferred to Phase 2.
- **Closes**: [`PsychQuant/psychquant-claude-plugins#23`](https://github.com/PsychQuant/psychquant-claude-plugins/issues/23), [`#26`](https://github.com/PsychQuant/psychquant-claude-plugins/issues/26)
- **Advances**: [`PsychQuant/macdoc#75`](https://github.com/PsychQuant/macdoc/issues/75) umbrella Layer 3 (partial)
