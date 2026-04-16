## 1. Skill structure + config parsing

- [x] 1.1 Per Decision: Phase 1 Scope is #23 + #26 Only — add a new Step 5.5 block between current Step 5 (Markdown generation) and Step 6 (Update Index) in `plugins/che-apple-mail-mcp/commands/archive-mail.md` titled "Step 5.5: Download and route attachments" (confirms scope: only #23 + #26 in this change; #24/#25 deferred to Phase 2)
- [x] 1.2 Per Decision: Config Schema Shape — add YAML parsing in Step 2 (directory + index setup) that reads the optional `attachment_routing` block from `.claude/emails.md` front matter, or falls back to the Decision: Default Routing Rules defaults when the block is absent
- [x] 1.3 Document in the skill that partial config replaces ALL defaults (no merge), with an example showing the full default YAML block for copy-paste reference

## 2. Routing classifier

Implements **Attachment routing follows config-keyword-extension precedence** + **Default routing rules when config is absent** requirements.

- [x] 2.1 Per Decision: Routing Precedence is Config > Keyword > Extension and **Attachment routing follows config-keyword-extension precedence** requirement — implement a classifier that takes a filename and the loaded config object, and returns `"data"` or `"document"`. Evaluation order: (a) future config-exact-file override (reserved), (b) `data_keywords` substring match (case-insensitive), (c) `document_keywords` substring match (case-insensitive), (d) `data_extensions` exact match, (e) `document_extensions` exact match, (f) conservative default = `"document"`
- [x] 2.2 Per Decision: Default Routing Rules and **Default routing rules when config is absent** requirement — hardcode the built-in defaults for `data_extensions` (csv/tsv/sav/dta/parquet/feather/xlsx/sas7bdat), `document_extensions` (pdf/docx/doc/txt/md/rtf/odt), `data_keywords` (data/raw/indicators/codebook/dataset), `document_keywords` (Submission/Figures/Tables/Manuscript/draft/Revision/v1/v2/v3), `data_dir` (data/raw), `documents_dir` (correspondence/attachments)
- [x] 2.3 Add unit test documentation in the skill (not executable tests, but worked examples as doc): classify `Submission_Figures_v3.docx` → document, `raw_indicators.csv` → data, `appendix.pdf` → document, `unknown.xyz` → document (conservative default)

## 3. Attachment download loop

Implements **Skill downloads attachments from archived emails** + **Attachment directory matches email Markdown stem** + **Filename preservation on disk with URL encoding in Markdown links only** requirements.

- [x] 3.1 Per **Skill downloads attachments from archived emails** requirement: in Step 5.5, for each archived email, call `mail__list_attachments_batch` with the email's identifier. If the result is empty, skip to next email.
- [x] 3.2 Per **Attachment directory matches email Markdown stem** requirement: for each attachment, classify via the routing classifier from Section 2 to determine target directory: `data_dir` (for data files) or `{documents_dir}/{email_stem}/` (for document files, where `email_stem` matches the email's Markdown filename without `.md`)
- [x] 3.3 Per Decision: Filename Preservation on Disk and **Filename preservation on disk with URL encoding in Markdown links only** requirement — call `mail__save_attachment` with the original filename bytes (no sanitization: spaces, `&`, CJK, emoji all preserved) as the target filename, to the classified directory
- [x] 3.4 Create the target directory on demand if it does not exist (both `data_dir` and `{documents_dir}/{email_stem}/` patterns)
- [x] 3.5 Wrap the `save_attachment` call in a try/catch (or equivalent error handling); on failure, log a warning but continue with next attachment. Full error handling with audit report is Phase 2 scope.

## 4. Markdown link generation + placement

Implements **Attachment block placement in Markdown** + **Filename preservation on disk with URL encoding in Markdown links only** requirements.

- [x] 4.1 Per Decision: Attachment Block Placement in Markdown and **Attachment block placement in Markdown** requirement — modify Step 5's Markdown template to insert a new "Attachments:" bullet list between the signature block and the thread quote separator. Identify the thread quote by matching the first occurrence of any of: `差出人:`, `寄件者:`, `From:`, `On ... wrote:`. If no thread quote exists (original message, not a reply), append the Attachments block at the end of the body.
- [x] 4.2 For each downloaded attachment, generate a Markdown link in the format `- [{original_filename}]({url_encoded_path}) ({size_kb} KB)`. The display text preserves the original filename verbatim. The URL encodes space → `%20`, `&` → `%26`, all other characters (including CJK) pass through.
- [x] 4.3 If the email has no attachments AND no quote-time markers (not a reply), no Attachments block is emitted.

## 5. Reply cross-reference

Implements **Reply without attachments emits cross-reference** requirement.

- [x] 5.1 Per Decision: Reply Cross-Reference Instead of Duplicate Download and **Reply without attachments emits cross-reference** requirement — when an email's `list_attachments` returns empty, scan the body for quote-time attachment markers matching the pattern `<[^>\n]+\.(docx?|pdf|xlsx?|csv|pptx?|png|jpe?g)>` (case-insensitive extension list). If found, record the original sender and the original email's inferred Markdown stem (best-effort match against the index).
- [x] 5.2 Emit a cross-reference line in place of the Attachments block: `(Attachments on the original email from {original_sender} — see \`{original_stem}.md\`)`. If the original stem cannot be inferred (original not yet archived), use a fallback: `(Attachments referenced in thread quote — original not yet archived)`.

## 6. Skill output report

Implements **Skill output report summarizes attachment routing** requirement.

- [x] 6.1 Per **Skill output report summarizes attachment routing** requirement — modify Step 7 (Output report) to accumulate counts during Step 5.5: `data_count`, `document_count`. Report line: `{N} attachments archived: {data_count} to {data_dir}, {document_count} to {documents_dir}` where `N = data_count + document_count`
- [x] 6.2 Zero-case: `0 attachments archived` (no breakdown) when no attachments were downloaded.

## 7. Documentation + deployment

- [x] 7.1 Update the skill's opening description / usage notes to mention the new attachment download behavior and point to the `attachment_routing` config block
- [x] 7.2 Add an example `.claude/emails.md` snippet at the end of the skill file showing the full default `attachment_routing` block for copy-paste reference
- [x] 7.3 Bump the version in `plugins/che-apple-mail-mcp/plugin.json` (minor bump — new behavior but additive: absent config = works out of the box with defaults)
- [x] 7.4 Deploy the updated plugin via `/plugin-tools:plugin-deploy` (this handles marketplace.json sync + cache update)

## 8. Issue tracking

- [x] 8.1 Post an implementation-complete comment on [`#23`](https://github.com/PsychQuant/psychquant-claude-plugins/issues/23) referencing the Spectra change and the deployed plugin version
- [x] 8.2 Post the same on [`#26`](https://github.com/PsychQuant/psychquant-claude-plugins/issues/26)
- [x] 8.3 Close both issues via `/idd-close` (gate-checked closing summaries). Do NOT use `Closes #N` in commit trailer (auto-close bypasses `idd-close`).
- [x] 8.4 Update [`PsychQuant/macdoc#75`](https://github.com/PsychQuant/macdoc/issues/75) umbrella: tick `#23` and `#26` in Layer 3 checklist; add a 2026-04-MM progress note; note that `#24` + `#25` remain for Phase 2 (`archive-mail-filter-and-audit`).
