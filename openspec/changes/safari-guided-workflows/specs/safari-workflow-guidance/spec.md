## ADDED Requirements

### Requirement: Recall workflow
The main skill SHALL describe source order, broad candidate collection, exact-URL deduplication, sorting and cross-source comparison. A read-only helper SHALL preserve distinct URLs with identical titles, query strings and fragments; retain source clues and unknown dates; and expose source caps and candidate pagination. Failed commands or invalid JSON/schema SHALL fail without a partial success report. Browser data SHALL remain in memory during collection. The helper SHALL query existing bookmarks JSON without requiring the newer CLI search flag, merge full-URL evidence before local matching, and retain nonmatching title aliases for a matching URL. Reading List state SHALL remain unknown without bookmark evidence. The main skill SHALL NOT add a blanket Python auto-approval rule.

#### Scenario: Repeated visits and identical titles
- **WHEN** history contains repeated visits to URL A and a separate URL B with the same title, and bookmarks also contains A
- **THEN** A is one candidate with both sources and B remains separate.

#### Scenario: Retrieval is limited or unavailable
- **WHEN** history returns its requested limit or the CLI reports a missing source on stderr
- **THEN** coverage preserves the cap or diagnostic and the workflow does not claim that an absent candidate proves the page was never seen.

### Requirement: Command result handling
The skill SHALL require checking each exit code and stderr's first line while retaining full diagnostics. Nonzero exits or a blocking-dialog warning SHALL stop subsequent actions. JSON SHALL be parsed only from stdout. Pipelines SHALL enable pipefail and SHALL NOT use head/tail to prematurely cut a running command's combined output. A stopped action SHALL NOT be automatically retried.

#### Scenario: Read succeeds while dialog is present
- **WHEN** a command returns exit zero, valid stdout and a blocking-dialog warning
- **THEN** the example stops before the next action and directs the caller to inspect the dialog and choose a named button only within the user's authorization.

### Requirement: Google Forms handoff
The site playbook SHALL follow the existing six-section and frontmatter contract. It SHALL distinguish visible upload controls from guessed private question codes, verify SPA changes from current page state, and hand off inaccessible file picking to the user. Upload completion SHALL be verified by the attached file state, and submission by the form's actual confirmation state. A formResponse URL alone SHALL establish neither submission nor non-submission.

#### Scenario: Upload picker appears
- **WHEN** an upload question has no usable file input and opens a Picker that cannot be accessed through the current DOM path
- **THEN** the playbook pauses for user selection, verifies the attachment afterward, and does not substitute text or retry submission blindly.

### Requirement: Consistent plugin packaging
The plugin and its marketplace entry SHALL publish the same version and description. New skill naming SHALL use a domain fragment and action verb, and its description SHALL explicitly identify Google Forms in Safari.

#### Scenario: Packaged guidance
- **WHEN** the new skill and references are packaged
- **THEN** safari-google-fill has six ordered nonempty sections, valid required frontmatter and a matching directory name, and Safari plugin version metadata is consistent.
