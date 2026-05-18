# archive-mail-corpus-refinement Specification

## Purpose

Defines how `/archive-mail` refines the fetched email corpus after Step 3 search and before Step 4 dedup, using six opt-in config fields (`sender_includes`, `sender_excludes`, `recipient_includes`, `recipient_excludes`, `subject_includes`, `subject_excludes`). Refinement is post-fetch and thread-coherent, distinct from search-time corpus definition (`filters`, `subject_keywords`, `exclude_mailboxes`).

## Requirements

- Six opt-in corpus-refinement fields read from `.claude/.mail/config.yaml` as YAML multi-line block-style sequences of strings; unset and empty sequences both equal no refinement on that axis (100% backward compat)
- Per-axis includes act as whitelist (any-substring match keeps the thread); excludes act as blacklist (any-substring match drops the thread); excludes win when both lists are non-empty and the same email matches both on the same axis
- Per-thread coherence — refinement is applied atomically at the thread level: any message in a thread matching includes keeps the whole thread; any message matching excludes drops the whole thread
- Case-insensitive substring matching with bare-value normalization: display-name prefix stripped for sender / recipient axes; bare subject computed by stripping leading `Re:` / `RE:` / `Fwd:` / `FW:` / `转发:` / `轉寄:` prefixes for the subject axis
- Refinement runs after Step 3 fetch and before Step 4 dedup; excluded threads' Message-IDs do not enter `email_index.json` or `threads.json`, so subsequent runs with the same config drop the same threads without re-surfacing them as new
- Phase 2 preview surfaces a refinement statistics block (kept / dropped totals and per-category breakdown) when at least one refinement field is non-empty; the block is omitted entirely when all six fields are unset; zero-count categories are omitted from the breakdown
- Malformed refinement value (non-sequence YAML scalar or unsupported inline list other than `[]`) aborts at Step 1 with explicit `Error: <field> must be a YAML multi-line block-style sequence of strings ...` message and non-zero exit; empty-string entries within a sequence (`[""]`) are silently dropped at parse time

### Requirement: Six opt-in corpus-refinement fields

`/archive-mail` SHALL recognize six optional top-level fields in `.claude/.mail/config.yaml` that refine the fetched email corpus before dedup: `sender_includes`, `sender_excludes`, `recipient_includes`, `recipient_excludes`, `subject_includes`, `subject_excludes`. Each field SHALL be a YAML sequence of strings. An absent field and an empty sequence SHALL both produce no refinement on that axis.

#### Scenario: All six fields unset

- **WHEN** `/archive-mail` runs with a config that defines `filters` but none of the six refinement fields
- **THEN** the archived corpus SHALL be identical to the corpus produced by the same `filters` value on the prior skill version
- **AND** Step 4.5 Phase 2 preview SHALL NOT include the refinement stats line

#### Scenario: Field present with empty list

- **WHEN** `/archive-mail` runs with `sender_excludes: []`
- **THEN** no email SHALL be dropped on the basis of `sender_excludes`
- **AND** the behavior SHALL be indistinguishable from omitting `sender_excludes` entirely

##### Example: empty list equivalence

| Config snippet | Behavior |
| --- | --- |
| `(field omitted)` | no refinement on axis |
| `sender_excludes: []` | no refinement on axis |
| `sender_excludes: [""]` | empty entry SHALL be silently dropped at parse; equivalent to `sender_excludes: []` |
| `sender_excludes: ["@yahoo"]` | refinement active with one substring |

---
### Requirement: Per-axis includes whitelist and excludes blacklist with excludes-precedence

For each axis (sender, recipient, subject), `/archive-mail` SHALL apply the following filter logic to the fetched corpus:

- When `<axis>_includes` is non-empty, an email SHALL pass the include filter on that axis if and only if the axis-target value contains at least one listed substring.
- When `<axis>_excludes` is non-empty, an email SHALL fail the exclude filter on that axis if the axis-target value contains any listed substring.
- When both `<axis>_includes` and `<axis>_excludes` are non-empty and the same email both passes the include filter and fails the exclude filter on the same axis, the email SHALL be dropped (excludes take precedence over includes on the same axis).

An email passes refinement if and only if it passes the include filter and does not fail the exclude filter on every axis with at least one non-empty field.

#### Scenario: Includes match keeps email; no match drops it

- **WHEN** `subject_includes: ["Schultz"]` is set and an email's bare subject is `Schultz scale 12 items`
- **THEN** the email SHALL pass refinement on the subject axis

#### Scenario: Excludes match drops email regardless of includes

- **WHEN** `recipient_includes: ["@stat.sinica"]` and `recipient_excludes: ["EDUCATION5361@yahoo"]` are both set
- **AND** an email's recipient list contains both `che@stat.sinica.edu.tw` and `EDUCATION5361@yahoo.com.tw`
- **THEN** the email SHALL be dropped (excludes win on same axis)

##### Example: excludes-precedence truth table

| `sender_includes` match | `sender_excludes` match | Outcome |
| --- | --- | --- |
| n/a (unset) | n/a (unset) | pass |
| n/a (unset) | true | drop |
| n/a (unset) | false | pass |
| true | n/a (unset) | pass |
| false | n/a (unset) | drop |
| true | true | **drop** (excludes win) |
| true | false | pass |
| false | true | drop |
| false | false | drop |

---
### Requirement: Per-thread coherence

Refinement SHALL be applied at thread granularity. A thread is the set of emails sharing the same bare subject (computed per the Subject Normalization requirement below). If any message in a thread passes the include filter on an axis where `<axis>_includes` is non-empty, the whole thread SHALL be treated as passing that axis's include filter. If any message in a thread fails the exclude filter on an axis where `<axis>_excludes` is non-empty, the whole thread SHALL be dropped regardless of the other messages.

#### Scenario: Stray CC drops whole thread

- **GIVEN** a thread with five messages, four of which have recipients only within `@stat.sinica.edu.tw`, and one of which CCs `EDUCATION5361@yahoo.com.tw`
- **WHEN** `recipient_excludes: ["EDUCATION5361@yahoo"]` is set
- **THEN** all five messages of the thread SHALL be dropped from the refined corpus

#### Scenario: One-message match keeps whole thread

- **GIVEN** a thread with three messages, only one of which has a subject containing `Schultz`
- **WHEN** `subject_includes: ["Schultz"]` is set
- **THEN** all three messages SHALL pass refinement on the subject axis

---
### Requirement: Case-insensitive substring matching with bare-value normalization

All refinement matching SHALL be case-insensitive substring matching. The skill SHALL lowercase both the configured list entries and the axis-target value before comparison. The axis-target value SHALL be normalized as follows:

- For `sender_includes` / `sender_excludes`: the email address only, with any display-name prefix stripped (e.g., `"Che Cheng" <che@as.edu.tw>` SHALL be matched against `che@as.edu.tw`).
- For `recipient_includes` / `recipient_excludes`: the email address of each recipient in turn, with display-name prefixes stripped.
- For `subject_includes` / `subject_excludes`: the bare subject, computed by stripping any leading sequence of `Re:`, `RE:`, `Fwd:`, `FW:`, `转发:`, or `轉寄:` prefixes (each followed by optional whitespace).

#### Scenario: Mixed-case match

- **WHEN** `sender_excludes: ["@YAHOO.COM"]` is set
- **AND** an email's sender is `Foo Bar <foo@yahoo.com.tw>`
- **THEN** the email SHALL be dropped (lowercase comparison: `@yahoo.com` substring of `foo@yahoo.com.tw`)

#### Scenario: Subject prefix stripping

- **WHEN** `subject_excludes: ["經費"]` is set
- **AND** an email's raw subject is `Re: 經費補助通知`
- **THEN** the bare subject SHALL be computed as `經費補助通知` and the email SHALL be dropped

##### Example: bare-subject computation

| Raw subject | Bare subject |
| --- | --- |
| `Schultz scale 12 items` | `Schultz scale 12 items` |
| `Re: Schultz scale 12 items` | `Schultz scale 12 items` |
| `Re: Re: Fwd: Schultz scale` | `Schultz scale` |
| `RE: 轉寄: 經費補助` | `經費補助` |

---
### Requirement: Refinement executes after fetch and before dedup

Refinement SHALL run after the Step 3 search-time corpus fetch and before the Step 4 Message-ID dedup. Threads dropped by refinement SHALL NOT have their Message-IDs added to `email_index.json` and SHALL NOT consume slots in `threads.json`. As a consequence, a subsequent `/archive-mail` run with the same refinement config SHALL drop the same threads again without re-surfacing them as new.

#### Scenario: Excluded thread does not enter index

- **GIVEN** `recipient_excludes: ["EDUCATION5361@yahoo"]` is set
- **WHEN** `/archive-mail` runs and one fetched thread has a recipient matching the substring
- **THEN** the thread SHALL be absent from the output directory after the run
- **AND** the thread's Message-IDs SHALL be absent from `email_index.json`
- **AND** the thread SHALL be absent from `threads.json`

#### Scenario: Subsequent run does not re-surface

- **GIVEN** a prior `/archive-mail` run dropped a thread by `recipient_excludes`
- **WHEN** `/archive-mail` runs again with the same config
- **THEN** the same thread SHALL be dropped again
- **AND** Step 7 SHALL NOT report it as newly archived

---
### Requirement: Phase 2 preview surfaces refinement statistics

When at least one of the six refinement fields is non-empty, Step 4.5 Phase 2 preview SHALL include a refinement statistics block listing the number of threads kept, the total dropped, and a per-category breakdown (`sender_excludes`, `recipient_excludes`, `subject_excludes`, `includes` filtered-out). Categories with zero drops SHALL be omitted from the breakdown. When all six fields are unset, the refinement statistics block SHALL be omitted entirely.

#### Scenario: Active refinement shows stats line

- **WHEN** `/archive-mail` runs with `subject_excludes: ["經費"]` and 3 threads are dropped by the subject_excludes match
- **THEN** Step 4.5 Phase 2 preview SHALL include a line of the form `Corpus refinement (includes/excludes): {kept} / 3 threads`
- **AND** the breakdown SHALL include `Dropped by subject_excludes: 3 threads`
- **AND** the breakdown SHALL omit categories with zero drops

#### Scenario: No refinement active omits the block entirely

- **WHEN** `/archive-mail` runs with all six refinement fields unset or empty
- **THEN** Step 4.5 Phase 2 preview SHALL NOT include any refinement statistics block

---
### Requirement: Malformed refinement value aborts with explicit error

When any of the six refinement fields is present in config but its value is not a YAML sequence of strings, `/archive-mail` SHALL abort at Step 1 with an explicit error message naming the offending field and the expected value shape, and SHALL exit with a non-zero status. The skill SHALL NOT silently coerce, ignore, or partially apply a malformed value.

#### Scenario: Scalar instead of sequence

- **WHEN** the config contains `sender_excludes: "@yahoo"` (scalar string instead of list)
- **THEN** `/archive-mail` SHALL print an error of the form `Error: sender_excludes must be a YAML sequence of strings`
- **AND** SHALL exit with non-zero status before performing any search or write
