## ADDED Requirements

### Requirement: Skill downloads attachments from archived emails

The `/archive-mail` skill SHALL, after generating the Markdown for each archived email, iterate the email's attachments (via `mail__list_attachments_batch`) and save each attachment to disk via `mail__save_attachment`. Emails whose `list_attachments` returns an empty list SHALL NOT trigger any save operation.

#### Scenario: Email with attachments triggers downloads

- **WHEN** `/archive-mail` processes an email that `list_attachments` reports has 2 attachments
- **THEN** the skill calls `save_attachment` twice, producing 2 files on disk in the configured attachment directory

#### Scenario: Email without attachments does not call save_attachment

- **WHEN** `/archive-mail` processes an email whose `list_attachments` returns an empty list
- **THEN** no `save_attachment` call is made for that email and no files are written

<!-- @trace
source: archive-mail-downloads-and-routing
updated: 2026-04-16
code:
  - plugins/che-apple-mail-mcp/commands/archive-mail.md
-->

---

### Requirement: Attachment directory matches email Markdown stem

For each archived email, attachments SHALL be written under a per-email subdirectory whose name matches the email's generated Markdown file (without the `.md` extension).

Given an email Markdown file at `correspondence/2026-04-08_Re--Taxometric-Analysis.md`, its attachments SHALL go to `correspondence/attachments/2026-04-08_Re--Taxometric-Analysis/` (when routed as documents) OR to the configured `data_dir` (when routed as data per the routing rules).

#### Scenario: Document attachment placed under email stem directory

- **WHEN** an email saved as `correspondence/2026-04-08_Foo.md` has an attachment `Report.pdf` classified as a document
- **THEN** the file is written to `correspondence/attachments/2026-04-08_Foo/Report.pdf`

#### Scenario: Data attachment placed under data_dir

- **WHEN** the same email has an attachment `raw_indicators.csv` classified as data (per routing rules)
- **THEN** the file is written to `{data_dir}/raw_indicators.csv` (where `data_dir` is either the configured value or the default `data/raw`)

<!-- @trace
source: archive-mail-downloads-and-routing
updated: 2026-04-16
code:
  - plugins/che-apple-mail-mcp/commands/archive-mail.md
-->

---

### Requirement: Attachment routing follows config-keyword-extension precedence

The skill SHALL classify each attachment as `data` or `document` by evaluating rules in strict precedence order:

1. **Config match** — if `.claude/emails.md` contains an `attachment_routing` block whose filename explicitly matches (not covered in v1, reserved for future exact-file override)
2. **Keyword match** — case-insensitive substring search of the filename against the two keyword lists. The first list to match determines classification. Keyword lists evaluated in order: `data_keywords` then `document_keywords`
3. **Extension match** — file's extension compared against `data_extensions` then `document_extensions`

The first matching rule determines classification. Later rules are NOT consulted.

If NO rule matches (filename has no keyword match and extension is in neither list), the file SHALL be routed to `documents_dir` as a conservative default.

#### Scenario: Keyword match overrides extension

- **WHEN** an attachment named `Submission_data_v3.xlsx` is encountered (both `Submission` document keyword and `data` data keyword present; `.xlsx` is a data extension)
- **THEN** the first matching keyword tier wins. Evaluated: `data_keywords` first → matches `data` (substring) → file routes to `data_dir`.
- **AND** the `.xlsx` extension is NOT consulted

Note: if the user's project treats `Submission_data_v3.xlsx` as a document (e.g., it's a submitted spreadsheet figure), they override via config's `attachment_routing` block.

#### Scenario: Extension-only classification

- **WHEN** an attachment named `appendix.pdf` matches no keyword in either list
- **THEN** extension `.pdf` is in `document_extensions` → file routes to `documents_dir`

#### Scenario: Unmatched file defaults to documents

- **WHEN** an attachment named `unknown.xyz` matches no keyword and its extension is in neither list
- **THEN** the file routes to `documents_dir` (conservative default)

<!-- @trace
source: archive-mail-downloads-and-routing
updated: 2026-04-16
code:
  - plugins/che-apple-mail-mcp/commands/archive-mail.md
-->

---

### Requirement: Default routing rules when config is absent

When `.claude/emails.md` does NOT contain an `attachment_routing` block, the skill SHALL apply these built-in defaults:

- `data_extensions`: `csv, tsv, sav, dta, parquet, feather, xlsx, sas7bdat`
- `document_extensions`: `pdf, docx, doc, txt, md, rtf, odt`
- `data_keywords` (case-insensitive substring): `data, raw, indicators, codebook, dataset`
- `document_keywords` (case-insensitive substring): `Submission, Figures, Tables, Manuscript, draft, Revision, v1, v2, v3`
- `data_dir`: `data/raw`
- `documents_dir`: `correspondence/attachments`

#### Scenario: Absent config uses built-in defaults

- **WHEN** `.claude/emails.md` has no `attachment_routing` field, and an email has attachments `data.csv` and `manuscript.docx`
- **THEN** `data.csv` → `data/raw/data.csv` (extension + keyword both match data); `manuscript.docx` → `correspondence/attachments/{email_stem}/manuscript.docx` (keyword `Manuscript` — case-insensitive — matches document)

#### Scenario: Partial config replaces ALL defaults (no merge)

- **WHEN** `.claude/emails.md` contains `attachment_routing: { data_extensions: [csv, sav] }` (all other fields omitted)
- **THEN** the skill uses ONLY `[csv, sav]` for data extensions and EMPTY lists for `document_extensions`, `data_keywords`, `document_keywords`. Default `data_dir` / `documents_dir` paths still apply (these fields have separate defaults, not part of the keyword/extension lists).
- **AND** a `.docx` attachment with no keyword match routes to `documents_dir` per the "unmatched file defaults to documents" rule (because the empty `document_extensions` list means the `.docx` doesn't match extension-tier either)

<!-- @trace
source: archive-mail-downloads-and-routing
updated: 2026-04-16
code:
  - plugins/che-apple-mail-mcp/commands/archive-mail.md
-->

---

### Requirement: Filename preservation on disk with URL encoding in Markdown links only

Attachment files SHALL be saved to disk with their original filename bytes preserved — including spaces, `&`, CJK characters, and emoji — without any sanitization. URL encoding SHALL be applied ONLY to the URL portion of Markdown links, not to the display text.

URL encoding rules for the Markdown link URL:
- Space (U+0020) → `%20`
- Ampersand `&` (U+0026) → `%26`
- All other characters (including CJK, emoji, other punctuation) SHALL pass through unchanged

#### Scenario: Original filename preserved on disk

- **WHEN** the attachment is named `Figures & Tables20260408.docx`
- **THEN** the file is saved as `Figures & Tables20260408.docx` (with literal space and `&`) on disk
- **AND** the Markdown link is `[Figures & Tables20260408.docx](attachments/{stem}/Figures%20%26%20Tables20260408.docx)`

#### Scenario: CJK filename passes through URL unchanged

- **WHEN** the attachment is named `資料_v3.xlsx` (CJK + underscore)
- **THEN** the file is saved with the CJK name on disk
- **AND** the Markdown link URL is `attachments/{stem}/資料_v3.xlsx` (CJK NOT percent-encoded)

<!-- @trace
source: archive-mail-downloads-and-routing
updated: 2026-04-16
code:
  - plugins/che-apple-mail-mcp/commands/archive-mail.md
-->

---

### Requirement: Attachment block placement in Markdown

Generated email Markdown SHALL contain a `Attachments:` block placed AFTER the email body signature and BEFORE any thread quote (identified by patterns like `差出人:`, `寄件者:`, `From:`, or `On ... wrote:`).

If the email has no attachments, no `Attachments:` block is emitted.

#### Scenario: Email with body + signature + thread quote

- **WHEN** an email contains body text, a signature ending with `∞∞∞` divider, and a thread quote starting with `差出人:`
- **THEN** the generated Markdown order is: body → signature → `Attachments:` block → thread quote

#### Scenario: Email without thread quote

- **WHEN** an email has body + signature but no thread quote (original message, not a reply)
- **THEN** the `Attachments:` block appears AFTER the signature with no following thread quote

<!-- @trace
source: archive-mail-downloads-and-routing
updated: 2026-04-16
code:
  - plugins/che-apple-mail-mcp/commands/archive-mail.md
-->

---

### Requirement: Reply without attachments emits cross-reference

When a reply email has an empty `list_attachments` result BUT its body contains quote-time attachment markers (text patterns like `<filename.ext>` appearing in the thread quote), the skill SHALL emit a cross-reference line in place of a download. The cross-reference SHALL identify the original sender and point to the original email's Markdown stem.

#### Scenario: Reply quoting original's attachments

- **WHEN** a reply email's `list_attachments` returns empty, and the body quote contains `<original_file.docx>` pointing at an original email archived as `2026-04-08_Foo.md`
- **THEN** the reply's Markdown contains `(Attachments on the original email from {original_sender} — see \`2026-04-08_Foo.md\`)` in place of the Attachments block
- **AND** no `save_attachment` call is made for the reply

#### Scenario: Reply without quote markers

- **WHEN** a reply's `list_attachments` is empty AND the body has no quote-time attachment markers
- **THEN** no `Attachments:` block and no cross-reference is emitted (silence is correct)

<!-- @trace
source: archive-mail-downloads-and-routing
updated: 2026-04-16
code:
  - plugins/che-apple-mail-mcp/commands/archive-mail.md
-->

---

### Requirement: Skill output report summarizes attachment routing

At the end of an `/archive-mail` invocation, the output report SHALL include a summary line counting attachments by routing destination.

Format: `N attachments archived: M to <data_dir>, K to <documents_dir>`

Where `N = M + K`. If no attachments were downloaded, the summary line is `0 attachments archived` (no breakdown).

#### Scenario: Mixed routing report

- **WHEN** an invocation downloads 15 total attachments: 4 classified as data, 11 as documents
- **THEN** the report includes the line `15 attachments archived: 4 to data/raw, 11 to correspondence/attachments`

#### Scenario: No attachments report

- **WHEN** an invocation processes emails that collectively have zero attachments
- **THEN** the report includes the line `0 attachments archived` with no breakdown

<!-- @trace
source: archive-mail-downloads-and-routing
updated: 2026-04-16
code:
  - plugins/che-apple-mail-mcp/commands/archive-mail.md
-->
