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
