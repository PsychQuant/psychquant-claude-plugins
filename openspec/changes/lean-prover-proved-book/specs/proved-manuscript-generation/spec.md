## Purpose

Builds a document that contains only the propositions Lean has proved, and a report of where the proof work stands, from a Lean-checked theorem-card graph. It exists so that the verified part of a research project reads as one document and grows as proofs are finished.

## ADDED Requirements

### Requirement: Only Lean-checked statuses count

The generator SHALL refuse to run when the graph's `check` field is not `lean`. A graph produced without `--lean` carries statuses from a text scan, and those SHALL NOT be treated as proof status.

#### Scenario: Text-level graph is refused

- **WHEN** the input graph has `check` equal to `text`
- **THEN** the generator exits with a non-zero status and writes no output file
- **AND** the message names `card-graph --lean` as the way to produce a usable graph

### Requirement: Inclusion equals proved

The document SHALL contain exactly the theorem cards whose status is `proved` and whose premises are settled, together with the definitions they use. A card with any other status SHALL NOT appear in the document body.

#### Scenario: Open and unformalized cards are absent

- **WHEN** the graph has theorem cards A (`proved`), B (`open`) and C (`unformalized`)
- **THEN** the document contains the statement of A
- **AND** the document contains neither B nor C

#### Scenario: A newly proved card appears and nothing else changes

- **GIVEN** a document generated from a graph in which B is `open`
- **WHEN** B becomes `proved` and the generator is run again
- **THEN** the new document contains B in addition to everything the first one contained

### Requirement: Inclusion is dependency-closed

A proved theorem card SHALL be included only if at least one of its proof modules has every premise card either `defined` or itself included in the document. A proved card that fails this test SHALL be left out of the body and SHALL be listed in the frontier report under an excluded section with the premises that block it.

#### Scenario: A theorem resting on a held-back theorem is held back too

- **WHEN** card Y is `proved` and its only proof module lists premise E, which is `proved` but held back
- **THEN** Y is not in the document
- **AND** the frontier report lists Y as excluded because E is held back

#### Scenario: Proved card with an unproved premise is held back

- **WHEN** card C is `proved` and its only proof module lists premise B, which is `open`
- **THEN** C is not in the document
- **AND** the frontier report lists C as excluded because B is not proved

### Requirement: Dependency order

Theorem statements SHALL be ordered so that every included premise theorem precedes the theorem that depends on it. Among cards with no order forced by dependencies, the order SHALL follow the position of the card's `block` label in the manuscript source, read through its `\input` files, and then the card id.

#### Scenario: Premise theorem comes first

- **WHEN** theorem T2 has theorem T1 as a premise and T2 appears earlier in the manuscript than T1
- **THEN** T1 precedes T2 in the document

### Requirement: Statement source

Each theorem statement SHALL be the manuscript's own environment for the card's `block` label: the enclosing `theorem`, `lemma`, `proposition`, `corollary` or `definition` environment, up to but not including any proof. If no such environment is found, the generator SHALL use the card's `natural` text, with LaTeX special characters escaped, and SHALL mark that entry as taken from the card text.

#### Scenario: Label found

- **WHEN** a card's `block` is `thm:alpha` and the manuscript has a theorem environment with `\label{thm:alpha}`
- **THEN** the document contains that environment's source and no proof

#### Scenario: Label not found

- **WHEN** a card's `block` matches no label in the manuscript
- **THEN** the document contains the card's `natural` text for that entry
- **AND** the entry carries the marker `statement from card text`

### Requirement: Manuscript reading ignores comments

The generator SHALL treat commands inside TeX comments (an unescaped percent sign to the end of the line) as absent: a commented label SHALL NOT be a label, a commented environment or proof command SHALL NOT bound a statement, and a commented input SHALL NOT be read. A file named by an active input that does not exist SHALL be an error.

#### Scenario: Commented label and proof command

- **WHEN** the manuscript has a commented `\label{thm:a}` before the real one and a commented `\begin{proof}` inside the theorem
- **THEN** the statement is taken from the real label and is not cut at the commented proof command

#### Scenario: Missing input file

- **WHEN** an active `\input{absent}` names a file that does not exist
- **THEN** the generator exits with a non-zero status naming `absent`

### Requirement: Graph edges name known cards

Every conclusion and premise of every edge SHALL be a node of the graph. An edge that names an unknown card SHALL be an error naming the card, and SHALL NOT be read as having fewer premises.

#### Scenario: Unknown premise

- **WHEN** an edge lists a premise `ghost` that is not a node
- **THEN** the generator exits with a non-zero status naming `ghost` and writes no output

### Requirement: Symbols the text font lacks

Text taken from a card SHALL have characters that common text fonts lack (the blackboard and double-struck letters, the transpose sign, superscript and subscript digits, and the succeeds-or-equals signs) set in math mode, so that the compiled document contains no missing-glyph boxes.

#### Scenario: Card text with special symbols

- **WHEN** a definition card's `natural` text contains a superscript five and a subscript four
- **THEN** the generated source contains them as math-mode superscript and subscript and no longer contains the original characters

### Requirement: Definitions used

The document SHALL include, before the theorems, each definition card that is a premise of an included theorem, once, using the card's `natural` text. A definition card that no included theorem uses SHALL NOT appear.

#### Scenario: Shared definition appears once

- **WHEN** two included theorems both have definition D as a premise
- **THEN** D appears exactly once in the document

### Requirement: Provenance per statement

Each included statement SHALL be accompanied by the Lean declaration name, the card id and the manuscript label, so that a reader can locate the proof without trusting prose.

#### Scenario: Provenance line

- **WHEN** a theorem card with Lean name `Lib.Thm.foo` and id `X` is included
- **THEN** its entry shows `Lib.Thm.foo`, `X` and its manuscript label

### Requirement: Frontier report

The generator SHALL write a frontier report as a separate file and SHALL link it from the document header together with the counts of proved theorem cards and of all theorem cards. The report SHALL have separate sections for statements that exist in Lean but are not proved, statements that have no Lean statement, and proved cards excluded from the body. Where a frontier card has no proof module, the report SHALL say that the frontier over-reports until proof edges exist.

#### Scenario: Two layers are separate

- **WHEN** the graph has open cards O1 and O2 and unformalized cards U1, U2 and U3
- **THEN** the report lists O1 and O2 under the section for statements not yet proved
- **AND** the report lists U1, U2 and U3 under the section for statements not yet stated

### Requirement: Reproducible output and check mode

The output SHALL be a function of the graph, the cards and the manuscript source only, with no timestamps, and SHALL be identical across runs on identical input. The generator SHALL offer a check mode that exits non-zero when the files on disk differ from what the input would produce.

#### Scenario: Stale output is detected

- **WHEN** a card becomes proved and the check mode runs against the old output
- **THEN** it exits with a non-zero status and names the stale file

### Requirement: Skill drives the whole run

The skill `/lean-prover:proved-manuscript` SHALL obtain a Lean-checked graph by running `card-graph --lean` unless a saved graph is given, SHALL run the generator, and SHALL report the counts and the output paths. When `card-graph` is not available, the skill SHALL say so and SHALL NOT fall back to a text-level graph.

#### Scenario: card-graph missing

- **WHEN** the skill is run and `card-graph` is not on the path and no graph is given
- **THEN** the skill stops with a message that names `card-graph`
- **AND** no document is written
