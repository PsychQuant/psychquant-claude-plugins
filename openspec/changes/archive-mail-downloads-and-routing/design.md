## Context

This is **Phase 1** of a two-phase sequence resolving the 4-issue `archive-mail` attachment handling bundle (`#23` `#24` `#25` `#26`). Phase 1 ships foundational functionality (download + routing); Phase 2 (`archive-mail-filter-and-audit`) ships robustness layer (filter expansion + coverage audit). See the consolidated diagnosis cross-posted to all 4 issues for the full scope analysis.

Current skill state at `plugins/che-apple-mail-mcp/commands/archive-mail.md` (202 lines, 7 steps):

1. Parse filter argument
2. Build directory + index
3. Search emails via `mail__search_emails` with `query: filter`
4. Filter new emails (dedup against index)
5. Generate Markdown per email (attachment filenames as plain text, no download)
6. Update index
7. Output report

MCP capabilities available but unused: `list_attachments`, `list_attachments_batch`, `save_attachment`.

The 2026-04-14 tatsuma manuscript backfill (commits `bcac7ee`, `784eac6` in `PsychQuant/collaborations_tatsuma`) established a validated pattern for attachment handling — this change formalizes and automates that pattern.

## Goals / Non-Goals

**Goals:**

- Download every attachment from every archived email automatically
- Route attachments to semantic locations: research data → `data/raw/`, document attachments → `correspondence/attachments/{email_stem}/`
- Preserve original filenames on disk; URL-encode only in Markdown links
- Allow per-project override via `.claude/emails.md` YAML config
- Establish the first `archive-mail-*` capability spec that Phase 2 will extend

**Non-Goals:**

- **Not expanding the email search filter** (#24) — that is Phase 2. Phase 1 downloads whatever emails the current `filter` search returns. Missing emails due to filter asymmetry remain missing until Phase 2 ships.
- **Not auditing download coverage** (#25) — also Phase 2. If `save_attachment` silently fails for an email, Phase 1 proceeds without warning. Phase 2 adds the cross-check step.
- **Not supporting `--backfill-attachments`** for existing archives — deferred to Phase 2. Phase 1 applies only to new `/archive-mail` invocations.
- **Not auto-migrating data files from existing `attachments/` directories to `data/`** — users with pre-existing archives can manually reclassify. Auto-migration would be a separate retroactive tooling change.
- **Not parsing content / doing OCR** to classify attachments — routing is filename-based (extension + keyword). Content-based classification (e.g., "this PDF contains only figures" vs "this PDF is a methodology reference") is out of scope.
- **Not changing the email search MCP call** (stays `mail__search_emails` with `query: filter`). Phase 2 extends it.

## Decisions

### Decision: Phase 1 Scope is #23 + #26 Only

This change covers attachment download (`#23`) and attachment routing (`#26`). Filter expansion (`#24`) and coverage audit (`#25`) are deferred to Phase 2 (`archive-mail-filter-and-audit`).

**Rationale**: `#23` and `#26` share the same code path (the new attachment download loop writes to paths determined by `#26` routing). `#24` expands what emails get processed; `#25` validates the output. Phase 2 logically consumes Phase 1's output. Shipping Phase 1 first lets users get the core fix quickly and validates download behavior before layering filter expansion and audit on top.

**Alternatives**:
- _Bundle all 4 into one change_ — rejected; ~40 tasks in one change is harder to review and slower to validate incrementally
- _Split into 4 separate changes_ — rejected; `#23`+`#26` share the download loop, splitting them would duplicate config plumbing

### Decision: Routing Precedence is Config > Keyword > Extension

When classifying an attachment, the routing logic evaluates in strict precedence:

1. **YAML config `attachment_routing` block** (if present in `.claude/emails.md`): explicit rules win over built-in heuristics
2. **Filename keyword match**: specific keywords in the filename override generic extension rules
3. **Extension-based defaults**: fallback for anything not matched by config or keywords

The first match wins; later rules are not consulted.

**Rationale**:
- **Config top-most** because users with project-specific conventions (e.g., manuscript project where `Figures_20250610.xlsx` is a figures file, not data) need an escape hatch from generic heuristics
- **Keywords above extensions** because a filename like `indicators_raw.xlsx` carries stronger signal than the `.xlsx` extension alone (extension says "spreadsheet", keyword says "data")
- **Extensions last** as a reasonable default for the common case

**Example evaluation** — file `Submission_Figures_v3.xlsx`:
- Config: no entry → skip
- Keyword: "Submission" matches `document_keywords` list → route to `attachments/`
- Extension `.xlsx` is in `data_extensions` list but NOT consulted (keyword already matched)

**Alternatives**:
- _Extension-first_ — rejected; `.xlsx` is ambiguous (data or figures table), forcing extension-first would mis-route manuscript xlsx to `data/`
- _Keyword-first_ — rejected; config loses its override role
- _Longest-match wins (any tier)_ — rejected as hard to explain; precedence model is simpler

### Decision: Default Routing Rules

Built-in defaults (used when `.claude/emails.md` has no `attachment_routing` block):

```yaml
data_extensions:
  - csv
  - tsv
  - sav       # SPSS
  - dta       # Stata
  - parquet
  - feather
  - xlsx      # ambiguous — keyword can override
  - sas7bdat  # SAS

document_extensions:
  - pdf
  - docx
  - doc
  - txt
  - md
  - rtf
  - odt

data_keywords:   # filename substring match, case-insensitive
  - data
  - raw
  - indicators
  - codebook
  - dataset

document_keywords:
  - Submission
  - Figures
  - Tables
  - Manuscript
  - draft
  - Revision
  - v1
  - v2
  - v3

data_dir: data/raw
documents_dir: correspondence/attachments
```

**Rationale**:
- `xlsx` in `data_extensions` because research workflows commonly use xlsx for indicator tables / wide-format datasets
- `Submission`, `Figures`, `Tables`, `Manuscript`, `v1`/`v2`/`v3` in `document_keywords` because these are standard academic paper artifacts
- Case-insensitive keyword match because inconsistent capitalization is common (`figures` vs `Figures` vs `FIGURES`)

**Alternatives considered**: `.xlsx` as document default (rejected — most research xlsx is data; users can override via keywords if their project treats xlsx as documents).

### Decision: Config Schema Shape

`attachment_routing` YAML block lives in `.claude/emails.md` front matter alongside existing `filters`. All fields optional; omitted fields fall back to defaults. Adding any field means the ENTIRE defaults are replaced (not merged) — avoids surprises from partial override.

```yaml
---
filters:
  - tatsuma
attachment_routing:
  data_extensions: [csv, sav, dta]
  data_keywords: [raw, indicators]
  data_dir: data/raw
  documents_dir: correspondence/attachments
  # document_extensions / document_keywords omitted → defaults used? NO: override all or nothing
---
```

**Rationale**: merge semantics are deceptively complex — users expect `data_extensions: [csv]` to ADD csv, but if defaults are `[csv, tsv, sav, ...]` is tsv still included? Partial override leads to bugs. "All or nothing" is explicit.

**Alternatives**: `merge: true` explicit flag for partial override — rejected as scope creep; can be added in Phase 2 if users request it.

### Decision: Filename Preservation on Disk

Attachment files are saved with their ORIGINAL filename bytes, including spaces, `&`, CJK characters, and emoji. No sanitization. URL encoding is applied ONLY when inserting the filename into a Markdown link URL.

**Rationale**:
- macOS filesystem supports Unicode + spaces + most punctuation natively
- Users want to open the file in Word / Excel and see the original name
- GitHub and VS Code render `%20`-encoded Markdown links correctly

**Specifics**:
- Disk path: `attachments/2026-04-08_.../Figures & Tables20260408.docx`
- Markdown link: `[Figures & Tables20260408.docx](attachments/2026-04-08_.../Figures%20%26%20Tables20260408.docx) (93 KB)`
- Display text (`[...]`) keeps original name verbatim for readability
- URL (`(...)`) encodes `space` → `%20` and `&` → `%26`; everything else (including CJK) stays unchanged

**Alternatives**:
- _Slugify filenames_ (replace spaces with `_`, strip `&`) — rejected; breaks user expectation of "original file"
- _Fully percent-encode URL_ — rejected; over-encoding CJK hurts readability without benefit (GitHub/VS Code handle raw CJK in URLs)

### Decision: Attachment Block Placement in Markdown

The Attachments list goes AFTER the signature block and BEFORE the thread quote (identified by `差出人:` / `From:` / `寄件者:` / `On ... wrote:` variants). Matches 2026-04-14 tatsuma baseline.

**Rationale**: Logically, attachments belong to "this email" not "the quoted thread history". Placing them before the thread quote makes this unambiguous. The existing skill already uses body-before-quote placement for the signature; attachments slot in between.

### Decision: Reply Cross-Reference Instead of Duplicate Download

When a reply email's `list_attachments` returns empty but the email body still contains text like `<original_file.docx>` (Mail.app's quote-time attachment marker), the skill emits a cross-reference line rather than attempting to download:

```markdown
Attachments:
(Attachments on the original email from <original_sender> — see `<original_email_md_stem>.md`)
```

**Rationale**: Downloading the same file multiple times across reply chains wastes disk and creates confusion about which copy is "authoritative". `list_attachments` is the source of truth for what THIS email actually has; quote-time markers are stale references. Cross-reference preserves the link without duplication.

**Alternatives**:
- _Download on every quote reference_ — rejected; wasteful + ambiguous provenance
- _Ignore quote-time markers entirely_ (write nothing if `list_attachments` is empty) — rejected; loses the explicit acknowledgement that attachments exist in the thread, just not on this message

## Risks / Trade-offs

- **Risk**: `save_attachment` may fail silently for a specific attachment (MCP returns error but skill doesn't check). Phase 1 proceeds without error handling.
  - **Mitigation**: the coverage audit in Phase 2 (`#25`) catches this. In Phase 1, a simple `try/catch` around `save_attachment` with a `console.warn` output is acceptable — full audit is Phase 2.

- **Risk**: large attachments (multi-MB PDFs, video) balloon repo disk. No size limit enforced.
  - **Mitigation**: Phase 2 can add a `max_attachment_size_mb` config with warn-and-skip behavior. Phase 1 accepts any size — this matches the manual-backfill baseline which downloaded 7 attachments totaling ~2 MB without issue.

- **Risk**: routing mis-classification (e.g., `Submission_Figures_Data.xlsx` has both `Submission` and `Data` keywords — ambiguous).
  - **Mitigation**: precedence is "first match wins"; user can override via config. If mis-classification is common, a `disambiguate` callback or rule ordering spec could be added later.

- **Risk**: YAML schema evolution — adding fields in Phase 2 (#24 subject_keywords, #25 audit_log path) must not break Phase 1 configs.
  - **Mitigation**: YAML parsing should tolerate unknown fields (skip, don't error). Document this as a forward-compat requirement in the spec.

- **Trade-off**: partial override semantics rejected (all-or-nothing). Users with one small override field must repeat all defaults.
  - **Mitigation**: built-in defaults will be exported as a reference snippet in the skill's example docs, so copy-paste is fast.

- **Trade-off**: no content-based classification — a PDF titled `codebook.pdf` gets classified as `document` (keyword `document_keywords` doesn't include "codebook"; `data_keywords` does, but extension is `.pdf` which is in `document_extensions`… keyword matches first, so it routes to `data/`). Works correctly in most cases but can confuse on ambiguous names.
  - **Mitigation**: config override handles edge cases; keyword lists can be tuned per project.

## Migration Plan

Within this change:

1. Write the new skill step between current Step 5 and Step 6
2. Add routing classifier logic (extension + keyword + config precedence)
3. Add Markdown generation updates (Attachments block placement, URL encoding)
4. Add config schema parsing from `.claude/emails.md` front matter
5. Update skill output report
6. Write example `.claude/emails.md` snippet in skill doc for user reference
7. Version bump in `plugins/che-apple-mail-mcp/plugin.json`
8. Deploy via `/plugin-tools:plugin-deploy`

**Rollback**: revert the single commit + re-deploy the previous plugin version. Existing archives are unaffected (they already have no attachments and no new config is required).

## Open Questions

- _(none — all 4 design decisions resolved above, with explicit "all-or-nothing" config semantics and "config > keyword > extension" precedence as the load-bearing choices)_
