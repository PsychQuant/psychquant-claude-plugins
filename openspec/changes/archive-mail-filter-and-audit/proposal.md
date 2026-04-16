## Why

Phase 1 (`archive-mail-downloads-and-routing`, v2.3.0) shipped attachment download + routing. But two structural gaps remain:

1. **Filter asymmetry (#24 bug)**: `/archive-mail tatsuma` only matches emails where "tatsuma" appears in sender/to. Internal multi-party discussions (Che ↔ Lay ↔ Pei-Chi without Tatsuma in cc) are invisible — 21 emails + 14 attachments were missed in the 2026-04-14 tatsuma audit. The root cause: `mail__search_emails` with `query: filter, field: sender` cannot capture threads where the external collaborator is absent from sender/to.

2. **No coverage audit (#25 feature)**: after archive-mail runs, there's no verification that (a) all attachments were actually downloaded (save_attachment could silently fail) or (b) the thread corpus is complete (no sibling emails missing from the archive). The 2026-04-14 audit was a 1+ hour manual cross-check.

This change is **Phase 2**, closing `#24` and `#25`.

## What Changes

### Filter expansion (#24)

- **Subject-keyword matching**: new optional `subject_keywords` field in `.claude/emails.md` YAML (e.g., `[taxometric, SSQ, paper]`). After the sender-based search (unchanged), a second pass searches by subject keyword. Union of both results. Deduplication by Message-ID.
- **Participant aliases**: new optional `participant_aliases` field (map of `email_address → canonical_name`). When a sender-based match returns a thread, the skill follows the thread's subject to find sibling messages from other participants (including internal-only threads). Not a new MCP call — uses the same `search_emails` but with `field: subject` and the matched thread's subject.
- **Thread-subject expansion**: for each email found by the initial sender search, extract its subject (strip `Re:` / `Fwd:` prefixes), search again by that bare subject. This catches internal follow-ups that share the same thread subject but lack the external collaborator in sender/to.

### Coverage audit (#25)

- **New Step 8** (after Step 7 report): `list_attachments_batch` on all archived emails, cross-check against disk files. Warn for any email whose reported attachment count doesn't match disk count.
- **Thread completeness check**: for each unique thread subject in the archive, search for additional messages with the same subject that were NOT archived. Report as "potential missing thread siblings".
- **Output**: audit report appended to the Step 7 output, showing warnings and a "coverage score" (`archived/total_found` for both emails and attachments).

## Non-Goals

- Not implementing `--backfill-attachments` or `--backfill-thread` auto-repair flags — those require transactional behavior (download + update index atomically) that the current skill structure doesn't support well. Deferred to a future change.
- Not using `In-Reply-To` / `Message-ID` chains for thread tracking — requires MCP `get_email_headers` which adds latency per email. Subject-based heuristic is good enough for 90%+ of academic email threads.
- Not auto-correcting the archive when audit finds gaps — audit REPORTS issues but doesn't fix them. Users re-run `/archive-mail` with expanded config to fill gaps.

## Capabilities

### New Capabilities

- `archive-mail-filter-expansion`: Defines how `/archive-mail` expands beyond sender-based search to capture complete thread corpora using subject keywords, participant aliases, and thread-subject expansion.

### Modified Capabilities

- `archive-mail-attachments`: ADDS the coverage audit step (Step 8) that validates attachment download completeness and thread coverage after the main archive flow completes.

## Impact

- **Affected specs**:
  - New: `openspec/specs/archive-mail-filter-expansion/spec.md`
  - Modified: `openspec/specs/archive-mail-attachments/spec.md` (adds audit requirement)
- **Affected code**:
  - Modified: `plugins/che-apple-mail-mcp/commands/archive-mail.md` (~310 → ~400 lines after Phase 2)
- **Config schema**:
  - New optional fields in `.claude/emails.md`: `subject_keywords: [String]`, `participant_aliases: { email: canonical_name }`
- **Closes**: [`#24`](https://github.com/PsychQuant/psychquant-claude-plugins/issues/24), [`#25`](https://github.com/PsychQuant/psychquant-claude-plugins/issues/25)
- **Completes**: [`PsychQuant/macdoc#75`](https://github.com/PsychQuant/macdoc/issues/75) Layer 3
