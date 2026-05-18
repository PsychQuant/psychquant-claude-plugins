## 1. Config parsing (Step 1)

- [x] 1.1 Implement awk parsers for the Six opt-in corpus-refinement fields (the Six fields (3 axes × 2 directions) under `<axis>_<direction>` noun-first naming) inside Step 1 Config parsing, so each of `sender_includes` / `sender_excludes` / `recipient_includes` / `recipient_excludes` / `subject_includes` / `subject_excludes` is read as a YAML sequence of strings; verified by a config-parse fixture test that asserts each of the six parsed lists matches the fixture YAML.
- [x] 1.2 Enforce the Malformed refinement value aborts with explicit error contract — when any refinement field is present but not a sequence, abort at Step 1 with an explicit `Error: <field> must be a YAML sequence of strings` message and non-zero exit; verified by running `/archive-mail` against a fixture with `sender_excludes: "@yahoo"` (scalar) and asserting non-zero exit plus stderr matches the error message.
- [x] 1.3 Treat empty-list and empty-string entries as no-op so `sender_excludes: []` and `sender_excludes: [""]` both produce zero refinement on the axis, per the spec's empty-list equivalence example; verified by a config-parse fixture comparing the parsed effective list against the omit-field baseline.

## 2. Step 4 corpus refinement

- [x] 2.1 Insert an `apply_refinement(fetched, config)` sub-step between Step 3 fetch and Step 4 dedup that realizes the Two-layer model — `filters` (search-time) vs `*_includes` (post-fetch restriction), so refinement runs strictly after the corpus is fetched and never reshapes the MCP query; verified by an integration fixture where an email matching `filters` but dropped by `recipient_excludes` is absent from the archive output and from `email_index.json`.
- [x] 2.2 Implement the Per-axis includes whitelist and excludes blacklist with excludes-precedence rule so that on each axis the include list acts as whitelist (any-substring match → keep), the exclude list acts as blacklist (any-substring match → drop), and when both lists match the same email on the same axis the email is dropped (Excludes win when both axes set); verified by asserting every row of the excludes-precedence truth table from the spec passes against synthetic email fixtures.
- [x] 2.3 Apply refinement atomically at thread granularity so the Per-thread coherence rule holds — any single message in a thread matching `<axis>_includes` keeps the whole thread; any single message matching `<axis>_excludes` drops the whole thread; verified by the spec's "Stray CC drops whole thread" and "One-message match keeps whole thread" scenarios as integration tests.
- [x] 2.4 Implement Case-insensitive substring matching with bare-value normalization — Substring case-insensitive matching against the bare email address (display-name stripped) for sender / recipient axes and against the bare subject (leading `Re:` / `RE:` / `Fwd:` / `FW:` / `转发:` / `轉寄:` prefixes stripped) for the subject axis; verified by running the 4-row bare-subject computation example table from the spec as parameterized assertions.
- [x] 2.5 Ensure Refinement executes after fetch and before dedup so excluded threads' Message-IDs never enter `email_index.json` and never consume slots in `threads.json`, and so a subsequent `/archive-mail` run with the same refinement config drops the same threads again without re-surfacing them; verified by the spec's "Excluded thread does not enter index" and "Subsequent run does not re-surface" scenarios as two-pass integration tests.

## 3. Step 4.5 Phase 2 preview

- [x] 3.1 Extend Step 4.5 Phase 2 preview so the Phase 2 preview surfaces refinement statistics block appears (with kept / dropped totals and per-category breakdown) when at least one refinement field is non-empty and is omitted entirely when all six are unset; verified by capturing Phase 2 output against two fixtures (one with `subject_excludes: ["經費"]` active and one with all fields unset) and asserting the block is present-with-correct-counts vs. absent respectively, and that zero-drop categories are omitted from the breakdown.

## 4. Spec artifacts

- [x] 4.1 Land `openspec/specs/archive-mail-corpus-refinement/spec.md` with the 7 requirements above so this is the New spec `archive-mail-corpus-refinement` (not extending `archive-mail-filter-expansion`), realizing the Single change covering both #76 and #84 contract; verified by `spectra validate add-archive-mail-corpus-refinement` exit 0 and `spectra analyze` reporting zero Critical findings.
- [x] 4.2 Leave the existing `archive-mail-filter-expansion` spec unchanged so Layer 1 search-time semantics carry no implicit modification from this change; verified by `git diff openspec/specs/archive-mail-filter-expansion/` returning empty after all apply-side commits.

## 5. Command-file documentation

- [x] 5.1 Add the 6 new fields to the top-of-command config field table in `plugins/che-apple-mail-mcp/commands/archive-mail.md` using Noun-first naming (`<axis>_<direction>`) per the design decision; verified by content review of the field table containing 6 new rows in the form `\`<axis>_<direction>\` | ...`.
- [x] 5.2 Extend the search-extension examples section with a concrete config example pairing `filters` and `sender_includes` to illustrate the Two-layer model — `filters` (search-time) vs `*_includes` (post-fetch restriction) interaction so users see when to reach for which layer; verified by content review and matching the example against the two-layer-model integration fixture from task 2.1.

## 6. Release

- [x] 6.1 Bump `plugins/che-apple-mail-mcp/.claude-plugin/plugin.json` from version 2.19.7 to 2.20.0 (feature add → semver minor); verified by `jq -r .version plugins/che-apple-mail-mcp/.claude-plugin/plugin.json` returning `2.20.0`.
- [x] 6.2 Add a CHANGELOG entry under `[Unreleased]` describing the 6 new refinement fields, the two-layer model framing, and the resolutions of `#76` and `#84`; verified by content review and (if available) `changelog-tools:changelog-validate` reporting no Keep-a-Changelog violations.

## 7. Issue closure

- [x] 7.1 Reference `#76` and `#84` with `Closes #76` and `Closes #84` trailers in the apply-side PR description so both issues close automatically on PR merge per the Single change covering both #76 and #84 contract; verified by GitHub auto-closing both issues immediately after the merge commit lands on `main`.
