## Why

`/archive-mail` currently has only one mechanism for shaping the email corpus: `filters`, which defines what gets searched at Step 3 (MCP query against sender / recipient / subject). Once emails are fetched, the only available exclusion is `exclude_mailboxes` (mailbox-level: Junk / Drafts / Trash). There is no way to declaratively narrow or exclude the corpus by sender, recipient, or subject content after the search.

Two open issues hit this gap from different angles:

- **#84 (recurring false positives)**: an email sent from a `filters`-matching account but to an unrelated recipient (e.g., supplementary-school content sent from the user's institutional account to `EDUCATION5361@yahoo.com.tw`) matches `filters` and is re-surfaced on every run. The user must manually exclude it each time because there is no `recipient_excludes` field.
- **#76 (cross-project / admin noise)**: the same sender posting to multiple research lines floods every workspace's archive. The user wants subject-based scoping (whitelist a topic) and admin-noise rejection (blacklist by subject substring).

These are the same problem along three axes (sender / recipient / subject) of the same conceptual layer — **post-fetch corpus refinement**, distinct from search-time corpus definition.

## What Changes

Introduces a **two-layer corpus model** for `/archive-mail`:

- **Layer 1 (search-time, existing)**: `filters`, `subject_keywords`, `participant_aliases`, `exclude_mailboxes` — defines what gets pulled from Mail.app at Step 3. Covered by the existing `archive-mail-filter-expansion` spec; no change to its requirements.
- **Layer 2 (post-fetch, new)**: 6 new optional opt-in config fields applied in Step 4 after the corpus is built, before dedup. Covered by a new `archive-mail-corpus-refinement` spec.

The 6 new fields, all under `.claude/.mail/config.yaml`:

- `sender_includes` — keep only emails whose sender contains at least one listed substring (case-insensitive)
- `sender_excludes` — drop emails whose sender contains any listed substring
- `recipient_includes` — keep only emails with at least one recipient containing at least one listed substring
- `recipient_excludes` — drop emails with any recipient containing any listed substring
- `subject_includes` — keep only emails whose bare subject (after stripping `Re:` / `RE:` / `Fwd:` / `FW:` / `转发:` / `轉寄:` prefixes) contains at least one listed substring
- `subject_excludes` — drop emails whose bare subject contains any listed substring

Behavior contract (full normative form in the new spec):

- Unset or empty list = no filter applied on that axis; 100% backward compatible.
- Per-axis includes act as whitelist; when non-empty, at least one listed substring must appear for the email to pass.
- Excludes act as blacklist; if any listed substring appears, the email is dropped — excludes win over includes when both are set on the same axis.
- All matching is case-insensitive substring matching, consistent with the existing `filters` / `subject_keywords` semantics.
- Coherence is applied at **thread granularity**: any message in a thread matching includes → the whole thread is kept; any matching excludes → the whole thread is dropped. Avoids partial threads landing in the archive.
- Step 4 dedup logic is unchanged. Refinement runs **before** dedup so excluded threads do not consume index slots.
- Step 4.5 Phase 2 preview gains a stats line: `Corpus refinement (includes/excludes): {kept} / {dropped} threads`.

Step 1 config parsing gains awk parsers for the 6 new fields, mirroring the existing `exclude_mailboxes` sequence-parse pattern (lines ~91–113).

Closes #76 and #84 when applied.

## Non-Goals

See `design.md` Goals / Non-Goals section.

## Capabilities

### New Capabilities

- `archive-mail-corpus-refinement`: Defines the Layer 2 post-fetch corpus-refinement contract — the 6 opt-in config fields (sender / recipient / subject × includes / excludes), per-thread coherence rule, excludes-precedence rule, empty-list-as-unset semantics, and the interaction with the existing Layer 1 search-time corpus definition.

### Modified Capabilities

(none)

## Impact

- Affected specs:
  - New: `openspec/specs/archive-mail-corpus-refinement/spec.md`
- Affected code:
  - `plugins/che-apple-mail-mcp/commands/archive-mail.md` — Step 1 config parsing (~line 91–113), Step 4 filter (~467–499), Step 4.5 Phase 2 preview (~510–525), top config field table (~line 31), search-extension examples section (~line 1048–1067).
  - `plugins/che-apple-mail-mcp/CHANGELOG.md` — new entry.
  - `plugins/che-apple-mail-mcp/.claude-plugin/plugin.json` — version bump 2.19.7 → 2.20.0 (feature = minor).
- Resolves: #76, #84 (both closed when change applied).
- No breaking changes — all 6 fields are opt-in with no-default semantics; existing configs continue to behave identically.
- Test infrastructure gap: `commands/archive-mail.md` is a markdown command with embedded awk; the plugin's `tests/` directory currently only covers the session-start hook. Test strategy is deferred to `design.md` (option to extract awk into a sourceable script vs add inline test harness).
