## ADDED Requirements

### Requirement: Subject-keyword search expands email corpus

After the sender-based search (Step 3), the skill SHALL perform a second search pass using each entry in the optional `subject_keywords` config field. Results are unioned with the sender-based results and deduplicated by Message-ID.

#### Scenario: Subject keyword finds internal-only thread

- **WHEN** `/archive-mail tatsuma` runs with `subject_keywords: [taxometric]` and an internal email between Che and Lay has subject "Re: Taxometric indicator selection" (no "tatsuma" in sender/to)
- **THEN** that email is included in the archive corpus because "taxometric" matches the subject

#### Scenario: No subject_keywords configured skips second pass

- **WHEN** `.claude/emails.md` has no `subject_keywords` field
- **THEN** only the sender-based search results are used (backward compatible)

---

### Requirement: Thread-subject expansion discovers sibling messages

For each email found by the initial sender-based search, the skill SHALL extract the bare subject (strip `Re:` / `RE:` / `Fwd:` / `FW:` prefixes), then search for additional messages with the same bare subject. This captures reply-chain siblings where the original filter string does not appear in sender/to.

#### Scenario: Internal reply to external thread is captured

- **WHEN** the sender search finds "Tatsuma → Lay: Re: Taxometric Analysis" and thread-subject expansion searches for bare subject "Taxometric Analysis"
- **THEN** "Lay → Che: Re: Taxometric Analysis" (internal, no Tatsuma) is also captured

#### Scenario: Unrelated email with similar subject is deduplicated

- **WHEN** thread-subject expansion finds a duplicate (same Message-ID already in corpus)
- **THEN** the duplicate is skipped without error

---

### Requirement: Participant aliases config field

`.claude/emails.md` SHALL support an optional `participant_aliases` YAML field mapping email addresses to canonical names. This field is informational for the current Phase 2 scope (used in audit reports and future display) but does not change search behavior.

#### Scenario: Alias present in config

- **WHEN** `.claude/emails.md` contains `participant_aliases: { "b08801008@ntu.edu.tw": "Pei-Chi" }`
- **THEN** the skill acknowledges the alias for audit reporting purposes

#### Scenario: No aliases configured

- **WHEN** `.claude/emails.md` has no `participant_aliases` field
- **THEN** the skill operates normally without alias resolution
