## ADDED Requirements

### Requirement: Coverage audit validates attachment completeness

After the main archive flow (Step 7 report), the skill SHALL run a coverage audit (Step 8) that:

1. Calls `list_attachments_batch` on all newly archived emails
2. Compares the reported attachment count per email against actual files on disk in the corresponding attachment directory
3. Reports any mismatches as warnings

#### Scenario: All attachments present on disk

- **WHEN** an email reports 2 attachments and both files exist on disk in the expected directory
- **THEN** the audit reports no warning for that email

#### Scenario: Missing attachment detected

- **WHEN** an email reports 3 attachments but only 2 files exist on disk
- **THEN** the audit emits a warning: `⚠️ {email_stem}: 1 attachment missing (expected 3, found 2)`

---

### Requirement: Thread completeness check identifies potential gaps

The coverage audit SHALL, for each unique bare subject in the archive, search for additional messages with that subject that were NOT archived. These are reported as "potential missing thread siblings" for user review.

#### Scenario: Missing sibling detected

- **WHEN** the archive contains 3 emails with subject "Re: Taxometric Analysis" but a search finds 5 total messages with that bare subject
- **THEN** the audit reports: `⚠️ Thread "Taxometric Analysis": 2 potential missing siblings (archived 3/5)`

#### Scenario: Complete thread

- **WHEN** all messages with a given subject are already in the archive
- **THEN** no thread-completeness warning is emitted for that subject

---

### Requirement: Audit report format

The audit output SHALL be appended after the Step 7 archive report, in a clearly separated section:

```
Archive Coverage Audit
═══════════════════════════════════════════
Attachment coverage: 15/15 (100%)
Thread coverage: 3 threads, 2 complete, 1 with gaps

Issues:
  ⚠️ {email_stem}: 1 attachment missing
  ⚠️ Thread "Subject": 2 potential missing siblings

Run /archive-mail with expanded subject_keywords to fill gaps.
═══════════════════════════════════════════
```

#### Scenario: Clean audit

- **WHEN** all attachments are present and all threads are complete
- **THEN** the audit section shows `Attachment coverage: N/N (100%)` and `Thread coverage: M threads, M complete, 0 with gaps` with no Issues section

#### Scenario: Issues found

- **WHEN** the audit finds 1 missing attachment and 1 incomplete thread
- **THEN** the Issues section lists both warnings with actionable guidance
