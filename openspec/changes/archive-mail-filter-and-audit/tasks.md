## 1. Config schema expansion

- [x] 1.1 Add `subject_keywords: [String]` optional field parsing in Step 2 of `archive-mail.md` per **Subject-keyword search expands email corpus** requirement. When absent, skip subject-keyword pass.
- [x] 1.2 Add `participant_aliases: { email: name }` optional field parsing per **Participant aliases config field** requirement. Store for audit reporting.
- [x] 1.3 Document both new fields in the config example section at the bottom of `archive-mail.md`

## 2. Filter expansion (#24)

- [x] 2.1 Per **Subject-keyword search expands email corpus** — after the existing sender-based search in Step 3, add a second search loop: for each keyword in `subject_keywords`, call `search_emails` with `field: subject` and `query: keyword`. Collect results.
- [x] 2.2 Per **Thread-subject expansion discovers sibling messages** — for each email found by the sender search, extract the bare subject (strip `Re:` / `RE:` / `Fwd:` / `FW:` prefixes via regex `^(Re|RE|Fwd|FW|转发|轉寄):\s*`), then search with `field: subject` and `query: bare_subject`. Collect results.
- [x] 2.3 Union all three result sets (sender + subject_keywords + thread-subject) and deduplicate by Message-ID. Feed the deduplicated corpus into Step 4 (filter new).
- [x] 2.4 Add a note in the Step 7 report showing expanded corpus stats: `搜尋結果: {sender_count} by sender + {keyword_count} by subject keyword + {thread_count} by thread expansion = {total_unique} unique (after dedup)`

## 3. Coverage audit (#25)

- [x] 3.1 Add new Step 8 "Coverage Audit" after Step 7 per **Coverage audit validates attachment completeness** requirement. For each newly archived email, call `list_attachments` and compare count against actual files in the expected disk directory.
- [x] 3.2 Per **Thread completeness check identifies potential gaps** requirement: for each unique bare subject in the archive, search for total message count with that subject; compare against archived count. Report any gap as "potential missing thread siblings".
- [x] 3.3 Per **Audit report format** requirement: append the audit section to Step 7 output with attachment coverage percentage, thread coverage summary, and Issues list. Clean audit shows 100% with no Issues section.

## 4. Documentation + deployment

- [x] 4.1 Update skill description and usage notes to mention subject_keywords, participant_aliases, and the coverage audit step
- [x] 4.2 Bump version in `plugins/che-apple-mail-mcp/.claude-plugin/plugin.json` to 2.4.0
- [x] 4.3 Deploy via `/plugin-tools:plugin-deploy`

## 5. Issue closure

- [x] 5.1 Post implementation-complete comment on #24 referencing the deployed version
- [x] 5.2 Post implementation-complete comment on #25
- [x] 5.3 Close both via `/idd-close` with gate-checked closing summaries (no `Closes` trailer in commits)
- [x] 5.4 Update `PsychQuant/macdoc#75` umbrella: tick #24 and #25 in Layer 3; add progress note; Layer 3 fully complete
