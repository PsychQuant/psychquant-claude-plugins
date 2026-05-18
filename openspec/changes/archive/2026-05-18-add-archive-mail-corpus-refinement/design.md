## Context

`/archive-mail` builds its email corpus in two passes today:

1. **Step 3 search-time**: `filters` (sender / recipient / subject substring) drives MCP `search_emails` queries. `subject_keywords` expands the search. `exclude_mailboxes` removes Junk / Drafts / Trash.
2. **Step 4 dedup**: filters out Message-IDs already in the index.

There is no layer between Step 3 (what to search) and Step 4 (already-seen) that lets the user **declaratively narrow or exclude the fetched corpus** by sender, recipient, or subject content. Two open issues hit this gap from different directions:

- **#84**: an email sent from a `filters`-matched account but to an unrelated recipient (institutional account → supplementary school) re-surfaces every run with no way to permanently exclude it without breaking `filters`.
- **#76**: a sender posting to multiple research lines floods every workspace; user wants subject-based whitelist / blacklist for topic scoping.

Both want the same mechanism — declarative axis-based refinement applied **after** Step 3 fetch and **before** Step 4 dedup — along three axes (sender, recipient, subject). #76 framed it as a subject-only feature; #84 framed it as a sender/recipient-only feature. They were filed as separate issues but represent one design surface.

Existing schema convention in `.claude/.mail/config.yaml` already leans noun-first: `subject_keywords`, `attachment_routing`, `participant_aliases`, `dedup_strategy`, `output_dir`, `last_archived`. Only `exclude_mailboxes` is verb-first — a historical outlier from a different conceptual layer (search-time mailbox switch, not corpus refinement).

## Goals / Non-Goals

**Goals:**

- Add 6 opt-in config fields (sender / recipient / subject × includes / excludes) that refine the post-Step-3 corpus before Step 4 dedup.
- Preserve 100% backward compatibility — unset or empty lists behave identically to the current skill.
- Keep the refinement layer conceptually distinct from search-time `filters`: refinement narrows what was fetched, it does not reshape what gets fetched.
- Apply refinement at thread granularity to avoid partial threads landing in the archive.
- Close #76 and #84 in a single change so the naming convention and thread-coherence rules cannot diverge between the two axes' implementations.
- Spec-level separation of the two layers (Layer 1 `archive-mail-filter-expansion`, Layer 2 new `archive-mail-corpus-refinement`) so future readers can locate refinement rules in one place.

**Non-Goals:**

- Not retro-renaming `exclude_mailboxes` to `mailbox_excludes`. It is a shipped verb-first field at a different conceptual layer (search-time, not refinement); renaming is a breaking change with low payoff.
- Not introducing `mailbox_includes` (whitelist of mailboxes to search). Out of scope for this change; `filters` plus per-mailbox MCP behavior already covers the common case.
- Not deprecating `subject_keywords`. It is a Layer 1 **search expansion** mechanism (broadens corpus), orthogonal to the new `subject_includes` Layer 2 **restriction** mechanism (narrows fetched corpus). Both stay.
- Not building a separate test harness for `commands/archive-mail.md` in this change. The plugin's `tests/` covers only the session-start hook; awk snippets are embedded in the markdown command. Test strategy is captured under Open Questions; per-feature TDD harness can land as a follow-up change.
- Not extending refinement into the MCP search query itself. Refinement is strictly post-fetch by design — the Mail.app MCP `search_emails` does not support NOT-substring queries cleanly, and pushing refinement search-side would couple `filters` and `*_excludes` into one mental model that the two-layer design deliberately keeps apart.

## Decisions

### Single change covering both #76 and #84

Both issues touch the same Step 4 code region, the same `.claude/.mail/config.yaml` schema, and the same thread-coherence rule. Splitting them into two changes risks divergent naming (`subject_excludes` from #76 vs `sender_excludes` from #84 with different rules) and two passes over the same code. Bundling them ensures the 6-field surface is designed coherently in one review.

**Alternative considered**: two changes (#84 first, #76 later). Rejected — same Step 4 filter touched twice, and the naming-convention decision would need cross-change coordination anyway, just less visibly.

### Six fields (3 axes × 2 directions)

The full set: `sender_includes`, `sender_excludes`, `recipient_includes`, `recipient_excludes`, `subject_includes`, `subject_excludes`.

**Alternatives considered**:

- Excludes only (3 fields). Drops `subject_includes` which is #76's stated workspace-scoping use case. Rejected — #76 would not close.
- Four fields (drop `sender_includes` / `recipient_includes` only). Argued that they duplicate `filters` for sender / recipient. Rejected — see the next decision; the two-layer model makes them orthogonal, not redundant.

### Two-layer model — `filters` (search-time) vs `*_includes` (post-fetch restriction)

`filters` shapes the search query (Step 3 MCP call); it defines what enters the fetched corpus. `*_includes` operates after the corpus is fetched (Step 4) and acts as a whitelist filter — keep only emails where at least one axis substring matches. The two are orthogonal:

- `filters: ["yfhsu"]` + `sender_includes: ["@gate.sinica"]` → cast wide net (anything mentioning yfhsu in sender / recipient / subject), then narrow to only those whose sender contains `@gate.sinica`. Useful for collaborator-scoped multi-axis filtering that a single search-time substring cannot express.
- `filters: ["yfhsu"]` alone → all yfhsu correspondence. Today's behavior, unchanged.

This is the same semantic shape as #76's original `subject_includes` proposal (post-search restriction). The new model generalizes it to all three axes.

**Alternative considered**: single-layer model where `filters` and `*_includes` co-apply at search-time with AND semantics. Rejected — `filters` is currently OR across its list and across sender / recipient / subject; layering AND on top creates a three-way config interaction (`filters` × `sender_includes` × `recipient_includes`) whose test matrix is large and surprising. Two layers separated by execution stage is mentally cleaner.

### Noun-first naming (`<axis>_<direction>`)

`sender_excludes` not `exclude_senders`. Consistent with the 6 existing noun-first fields in the schema; the single verb-first outlier `exclude_mailboxes` lives at a different conceptual layer and is justified by its "search-time switch" semantics ("exclude X from search") vs the new fields' "refinement filter" semantics ("filter corpus by X").

**Alternative considered**: A2 verb-first (`exclude_senders` etc.) for alignment with `exclude_mailboxes`. Rejected — dominant pattern matters more than alignment with one outlier, and the same-axis paired fields (`sender_includes` / `sender_excludes`) read more naturally when the axis name is the prefix.

### Substring case-insensitive matching

Each list entry matches if it appears as a case-insensitive substring of the target field (sender email, recipient email, or bare subject). Same semantic as the existing `filters` and `subject_keywords`.

**Alternative considered**: exact match (full email or full subject). Rejected — inconsistent with two existing search fields, and the common use cases (`@yahoo` for domain-wide exclude, partial subject keywords) need substring.

### Excludes win when both axes set

When `<axis>_includes` and `<axis>_excludes` are both non-empty and an email matches both, the email is dropped. Conceptually: includes narrow the candidate set, excludes drop matches from that narrowed set.

**Alternative considered**: includes wins (explicit-keep overrides exclude). Rejected — most general-purpose filter engines default to deny-wins / blacklist-wins because it is the safer behavior under accidental overlap. The user can always tighten an include pattern to avoid the overlap if they want fine-grained exemption.

### Per-thread coherence

Refinement is applied at thread granularity. If any message in a thread matches `*_includes`, the whole thread is kept. If any message matches `*_excludes`, the whole thread is dropped. Threads are identified by bare subject (after stripping `Re:` / `RE:` / `Fwd:` / `FW:` / `转发:` / `轉寄:` prefixes), consistent with the existing thread-key logic.

**Trade-off**: a thread whose mostly-legitimate messages contain one stray CC to an excluded address gets dropped entirely. The mitigation is to tune the exclude pattern (e.g., exclude a more specific substring), which is exactly what the user does today with `filters`.

**Alternative considered**: per-message refinement (each message judged independently). Rejected — produces partial threads in the archive (some messages of a thread present, others missing), which breaks the `threads.json` invariant that every archived message of a thread is co-located. The skill's existing thread-handling assumes thread-level atomicity.

### New spec `archive-mail-corpus-refinement` (not extending `archive-mail-filter-expansion`)

The existing `archive-mail-filter-expansion` spec defines Layer 1 search-time expansion (subject keyword, participant aliases, thread-subject expansion). The new fields are Layer 2 post-fetch refinement. Cramming Layer 2 requirements into a spec named "filter-expansion" creates a semantic mismatch — expansion broadens corpus, refinement narrows it.

**Alternative considered**: extend `archive-mail-filter-expansion`, possibly rename to `archive-mail-filtering`. Rejected — renaming a published spec is a breaking change for anyone referencing it; not renaming leaves the spec name lying about its scope.

## Implementation Contract

**Observable behavior**

A user with the following `.claude/.mail/config.yaml`:

```yaml
filters:
  - che830621@as.edu.tw

recipient_excludes:
  - EDUCATION5361@yahoo.com.tw

subject_excludes:
  - 講義
```

runs `/archive-mail`. Any thread whose recipient list contains `EDUCATION5361@yahoo.com.tw` (substring match, case-insensitive) on at least one message, OR whose bare subject contains `講義` on at least one message, is dropped from the corpus before Step 4 dedup. The Step 7 report and Step 4.5 Phase 2 preview both surface the drop counts.

Subsequent runs with the same config produce identical exclusion — the dropped threads' Message-IDs never enter the index, so they cannot re-surface as "new" unless the user removes the exclude entry.

**Interface — config schema**

Six new optional top-level keys in `.claude/.mail/config.yaml`. Each is a YAML sequence of strings; absent key or empty sequence both mean "no refinement on this axis":

```yaml
sender_includes:    [<substring>, ...]
sender_excludes:    [<substring>, ...]
recipient_includes: [<substring>, ...]
recipient_excludes: [<substring>, ...]
subject_includes:   [<substring>, ...]
subject_excludes:   [<substring>, ...]
```

Substring matching is case-insensitive (the comparison lowercases both the config entry and the target field). For sender / recipient, the target is the bare email address (display name stripped). For subject, the target is the bare subject after `Re:` / `RE:` / `Fwd:` / `FW:` / `转发:` / `轉寄:` prefix stripping.

**Step 4 pipeline shape**

Refinement runs as a sub-step inserted between corpus fetch and dedup. Pseudocode:

```python
fetched = step3_search()        # Layer 1 corpus
refined = apply_refinement(fetched, config)  # Layer 2 (this change)
new_emails = step4_dedup(refined, index)     # existing
```

`apply_refinement` groups `fetched` by thread, evaluates each thread against the 6 fields, drops the thread entirely if it matches an exclude or fails an include whitelist.

**Step 4.5 Phase 2 preview line**

Existing preview gains a stats line, surfaced only when at least one of the 6 fields is non-empty:

```
Corpus refinement (includes/excludes): {kept} / {dropped} threads
  Dropped by sender_excludes:    {N} threads
  Dropped by recipient_excludes: {N} threads
  Dropped by subject_excludes:   {N} threads
  Filtered out by includes:      {N} threads
```

Zero-count rows are omitted to keep the preview compact.

**Failure modes**

- Malformed YAML value (e.g., a string instead of a sequence) for any of the 6 fields → skill aborts at Step 1 with `Error: <field> must be a YAML sequence of strings` and exits non-zero. Same posture as the existing `exclude_mailboxes` parse error path.
- Substring matches nothing → silent no-op (refined corpus same as fetched). Expected behavior; users discover via the Phase 2 preview line.
- Substring matches everything → refined corpus is empty, Step 4.5 Phase 2 preview shows `kept=0` and `dropped=<total>`; skill warns and prompts user before continuing.

**Acceptance criteria**

- An archive run with all 6 fields unset is byte-identical to the same run on the prior skill version (excluding version-bump and timestamp differences).
- An archive run with `recipient_excludes: ["EDUCATION5361@yahoo.com.tw"]` drops the 274139 thread that motivates #84; the dropped thread does not appear in `communications/intake/` or in `email_index.json`.
- An archive run with `subject_excludes: ["經費"]` drops admin threads matching the #76 use case; the dropped threads do not appear in the archive.
- Phase 2 preview surfaces the drop counts when refinement is active; omits the section entirely when all 6 fields are unset.
- Spec analyzer (`spectra analyze`) reports no Critical findings against the new `archive-mail-corpus-refinement` spec.
- `archive-mail-filter-expansion` spec is unchanged.

**Scope boundaries**

- In scope: 6 new config fields, Step 1 awk parsing, Step 4 refinement sub-step, Step 4.5 Phase 2 preview line, top-of-skill config field table, search-extension examples section, CHANGELOG, version bump, new spec file.
- Out of scope: dedup logic changes, threads.json schema changes, Step 5+ markdown writer changes, attachment routing changes, search-side MCP query changes, `exclude_mailboxes` migration, `subject_keywords` deprecation.

## Risks / Trade-offs

- **Substring over-match** → Mitigation: document the case-insensitive substring semantic in the search-extension examples section; recommend using `@yahoo.com.tw` over `yahoo` when scoping by domain.
- **Stray-CC drops thread** (mid-thread CC to excluded address drops the whole thread) → Mitigation: document the thread-coherence rule in the spec and the skill's example section; user can tighten exclude substring to avoid hitting the stray address.
- **Three-way config interaction confusion** (`filters` × `<axis>_includes` × `<axis>_excludes`) → Mitigation: the two-layer model documentation in the new spec; concrete example in the skill's search-extension examples section showing a `filters` + `sender_includes` pairing.
- **No test harness for command-embedded awk** → Mitigation: documented as Open Question; manual acceptance testing in this change, follow-up change to extract awk into sourceable script for future TDD.
- **Refinement runs before dedup** → If excluded threads were previously archived (Message-IDs in index), they are still in the on-disk archive. Refinement does not retroactively prune. → Mitigation: document; users can manually remove the old archive entries if they want a clean slate.

## Migration Plan

- No data migration required — all 6 fields are opt-in with backward-compatible empty defaults.
- Version bump: `plugins/che-apple-mail-mcp/.claude-plugin/plugin.json` 2.19.7 → 2.20.0 (semver minor for a feature add).
- CHANGELOG entry under `[Unreleased]` describes the new fields and links to #76, #84.
- Closing #76 and #84 happens when the change is applied (close as part of the apply-side commits, linked to the change branch's PR).
- Rollback: revert the change branch; the 6 new fields become unrecognized YAML keys but the existing awk parsers ignore unknown keys silently. No config-file migration needed to roll back.

## Open Questions

- **Test harness for `commands/archive-mail.md`**: should the implementing change include awk-extraction to a sourceable script (e.g., `bin/archive-mail-helpers.sh`) so the 6-field parsing can have unit coverage? Or defer entirely to a follow-up dedicated to testability? Recommendation: defer to follow-up — this change's scope is the feature, not the test infra rebuild.
- **Empty-string-in-list semantics**: `sender_excludes: [""]` (a list containing an empty string) would substring-match every email. Should the parser warn or silently drop empty entries? Recommendation: silently drop empty entries at parse time; document in the spec; defer warning to a future config-validator change.
