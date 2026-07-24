# Proposition Extraction Prompt

This document specifies the LLM prompt for converting `manuscript/main.tex`
sentences into structured `propositions` per SCHEMA.md. Used for initial
extraction + ongoing maintenance when adding new sections.

## Granularity modes

The extractor supports **two granularity modes** — caller picks via the
"=== GRANULARITY ===" header in the per-call prompt:

| Mode | When | Phase | Issue |
|------|------|-------|-------|
| `heterogeneous` (Phase 1) | Default for initial extraction; mixes sentence-level / multi-sentence / theorem-stmt / byte-range fallback as needed for fast prototype | Phase 1 (current state) | #69 (prototype) |
| `clause-level` (Phase 2) | Spinoza Ethics / Wittgenstein Tractatus style — split at `.`, `,`, `;`, `:`; connectives + references explicitly tagged | Phase 2 target | #77 (re-extraction) |

The Phase 1 heterogeneous mode shipped 293 props for the whole manuscript but
left 35 props (12%) as byte-range fallback because author paraphrase didn't
substring-match `.tex`. Phase 2 clause-level mode eliminates this by extracting
at the level where every clause is verbatim-findable in `.tex`.

## System prompt (paste into LLM session) — heterogeneous mode

```
You are a mathematical-philosophy proposition extractor. Given a LaTeX
section from a math psychology paper, decompose it into atomic propositions
following the bijection contract in SCHEMA.md.

CRITICAL RULES (heterogeneous mode):
1. **Bijection**: every declarative sentence in the .tex maps to exactly 1
   proposition. No skipping, no merging two sentences into one prop.
2. **Verbatim text**: the `text` field MUST quote the source sentence
   character-for-character (including inline LaTeX math like $\xi_s(x)$).
   Do NOT paraphrase. Do NOT remove LaTeX escapes.
3. **Display math handling**: if a sentence ends in `:` or `,` and the next
   visual unit is `\[...\]` or `\begin{equation}...\end{equation}`, treat
   the display as part of the same proposition (concatenate text).
4. **Structural elements**: section headings, `\emph{Step N (...).}` proof
   markers, comments `%`, and standalone `\label{...}` lines are NOT
   propositions — skip them.
5. **claim_type** must be one of: axiom, definition, hypothesis, claim,
   case_split, display_equation, restatement, commentary, example.
6. **id**: emit a freshly generated UUID v7 (RFC 9562 §5.7) per proposition,
   canonical 8-4-4-4-12 lowercased hex with version field `7`. Do NOT
   emit sequential `P<NNN>` ordinals — display ordinals are derived at view
   time by the validator (sort by `(containing_block, file-position)`,
   file-position being the prop's line index in the JSONL). See SCHEMA.md
   §View-time ordinal derivation.
7. **cites**: only include prior proposition UUIDs that the proposition
   LOGICALLY depends on. Cite by UUID v7 string, never by display ordinal.
   If uncertain, omit (validator reports orphan props as warning, not error).
8. **asserts**: 1-3 atomic claims in plain-text-with-light-LaTeX form.
   Strip surrounding rhetoric ("we observe that", "it is clear that").
9. **mathematical_objects**: list the symbols / functions / sets the
   proposition mentions. Use bare LaTeX (xi_s, eta, H, S°). For multi-char
   identifiers (xi_s), no spaces.

Output JSONL only (one proposition per line, no enclosing array, no markdown
fencing). Each proposition follows the SCHEMA.md per-proposition schema.
Emit props in main.tex reading order — the JSONL line order IS the
proposition ordering, so no ordinal fields are stored:

{"id":"01910b9c-d4f0-7000-8000-...","text":"...","location":"main.tex:L91","claim_type":"commentary",...}
{"id":"01910b9c-d4f0-7001-8000-...","text":"...","location":"main.tex:L96","claim_type":"commentary",...}

Metadata wrapper (`schema_version`, `source`, `coverage`, `axioms`) lives in
`_meta.json` separately — your job is just to produce the per-line props
for this section, in main.tex reading order.
```

## System prompt — clause-level mode (Phase 2, #77)

```
You are a mathematical-philosophy proposition extractor producing CLAUSE-LEVEL
propositions in the Spinoza / Wittgenstein tradition. Given a LaTeX section,
split EVERY sentence at clause boundaries and emit one proposition per clause.

CRITICAL RULES (clause-level mode — strict bijection):

1. **Clause boundary detection**: split sentences at the following punctuation:
   - **Strong**: `.` (period — sentence end)
   - **Strong**: `;` (semicolon — independent clause)
   - **Strong**: `:` (colon — usually intro + content)
   - **Medium**: `,` BEFORE conjunction (and, but, or, hence, therefore, thus,
     so, then, while, where, which) — split BEFORE the conjunction
   - **NOT a boundary**: `,` inside math (e.g. `$P_x(y) = F((u-v)/σ)$` —
     internal commas are math syntax), `,` in lists of objects (e.g.
     "u, v strictly monotonic" is one clause), `,` in citation (e.g.
     "Doble & Hsu, 2020")
   - **Hyphen-conjunction note**: parenthetical clauses (e.g. "(not
     constant on any subinterval)") count as ONE prop attached to the
     preceding clause as scope_qualifier OR as its own commentary prop
     depending on substantive content

2. **claim_type taxonomy (clause-level)** — extends the 9 heterogeneous types
   with 2 new structural types:
   - **NEW**: `connective` — pure linguistic connector with no propositional
     content. Examples: "Hence", "Therefore", "Thus", "And", "But", "However",
     "It follows that", "We observe that", "In particular", "Then,". These
     props have empty asserts list + claim_type=connective.
   - **NEW**: `reference` — pure cross-reference / citation with no
     propositional content. Examples: "(Section~\ref{sec:setup})", "see
     Lemma~\ref{lem:foo}", "by Theorem~\ref{thm:bar}",
     "\citep{DobleHsu2020}", "see also above". These props have empty asserts
     list + claim_type=reference + cites field may reference target prop.
   - Existing 9 types (axiom, definition, hypothesis, claim, case_split,
     display_equation, restatement, commentary, example) unchanged.

3. **Verbatim text**: each clause's `text` MUST be verbatim from `.tex`
   (including leading whitespace if relevant for unique identification).
   Include the boundary punctuation if it's terminal (e.g. "Hence,").
   Inline math preserved as in source (`$\eta(\lambda, s)$`). DO NOT
   paraphrase — that goes in `asserts`.

4. **Display math (clause-level)**:
   - Display equation `\[...\]` standalone (no prose) → claim_type=display_equation
   - Display equation immediately preceded by `:` in prose → BOTH the prose
     and the display are separate clauses (NOT concatenated — clause-level
     boundary on `:`). The prose clause's last assert is "introduces equation
     below" + the equation's text is the verbatim `\[ ... \]` content.

5. **Scope qualifiers as clauses**: subordinate clauses providing scope
   ("for every s ∈ S", "on the relevant sub-intervals", "where applicable")
   are SEPARATE clauses with their own prop. They cite the parent clause
   and have claim_type=scope_qualifier (NEW) OR commentary.

   - **NEW**: `scope_qualifier` — subordinate clause attaching scope/quantifier
     to a parent claim. Example: "for every $s \\in S$" after "$f(s) = s$".
     `asserts: ["scope: for every s in S"]`. cites parent claim.

6. **Connectives + references DO get IDs + locations**: even though they
   have no propositional content, they're part of the bijection. R1
   substring match relies on every clause being findable in `.tex`.

7. **Empty asserts list is legal** for connective + reference types.
   For substantive types (axiom/definition/hypothesis/claim/case_split/etc.),
   asserts must have ≥1 item.

8. **Granularity goal**: expansion ratio ~2-4x vs heterogeneous mode. If
   you're producing <1.5x, you're under-splitting (likely still at
   sentence level). If you're producing >5x, you're over-splitting (likely
   splitting inside math expressions or treating noun phrases as clauses).

9. **Clause ordering**: emit clauses in source reading order. The JSONL file
   line order IS the proposition ordering — clauses from the same source
   sentence appear as consecutive lines. No ordinal fields are stored; the
   validator derives display ordinals from `(containing_block, file-position)`.

Output JSONL only (one prop per line, no enclosing array, no markdown fencing).
```

### Expanded claim_type taxonomy (clause-level)

| Type (clause-level additions) | When | Example |
|------|------|---------|
| `connective` | Pure linguistic connector, no propositional content | "Hence," / "Therefore," / "In particular," |
| `reference` | Pure cross-reference / citation, no propositional content | "(Section~\\ref{sec:setup})" / "\\citep{DobleHsu2020}" |
| `scope_qualifier` | Subordinate scope/quantifier attaching to parent claim | "for every $s \\in S$" / "on the relevant sub-intervals" |

These 3 new types are ONLY used in clause-level mode (Phase 2). Heterogeneous
mode (Phase 1) absorbs scope qualifiers into the parent claim's text + asserts.

## Pre-extraction sanity check (env boundary discipline)

> **Why this section exists**: #97 surfaced that the Phase 1 pilot extractor
> mistook Theorem 1's statement boundary. The root cause was "extractor judged
> statement end by intuitive reading (where the prose stops) instead of by
> physical `\begin{theorem}` / `\end{theorem}` token boundary". Without this
> discipline, future Stage 3+ extraction will repeat the same misjudgment.

Before splitting any section of `main.tex` for extraction, the extractor (LLM
or human) MUST follow these three rules.

### Rule 1: Always grep first

Never trust your visual sense of where a theorem/lemma/proof "ends". Run:

```bash
grep -n "\\begin{<env>}\\|\\end{<env>}" manuscript/main.tex
```

(Or use the mechanical baseline doc — `manuscript/propositions/_stage3_baseline.md`,
generated by `scripts/audit-theorem-boundaries.py`, see #98.)

Take the **physical line range** from grep output. Do NOT type line ranges from
memory or visual approximation.

### Rule 2: Boundary disclosure in prompt

The `=== SECTION TO EXTRACT ===` block in the per-call structure MUST be
preceded by an explicit `=== TARGET ENV ===` header that names the env and
quotes its real begin/end lines verified by grep:

```
=== TARGET ENV ===
theorem (label: thm:eta-s)
begin: main.tex:L469 (grep-verified)
end:   main.tex:L550 (grep-verified)
proof env (separate): main.tex:L560-L714

=== SECTION TO EXTRACT ===
[paste lines L469-L550 of main.tex here, the full theorem statement]
```

Reject any prompt that omits the `TARGET ENV` header or whose `begin/end`
lines were not verified by grep.

### Rule 3: Reject "intuitive end"

Extractor MUST NOT stop extracting at:

- The end of the hypothesis paragraph
- The end of the setup block
- The first prose paragraph that "feels" like the statement is done
- Any blank line within the env

The statement only ends at the **physical `\end{<env>}` token**. Cases /
sub-clauses / `\begin{align*}` blocks / numbered enumeration that sit
between the hypothesis and `\end{theorem}` are ALL part of the statement
and MUST be extracted.

### Anti-pattern: pilot's #97 misjudgment

`main.tex` Theorem 1 (`thm:eta-s`) has this structure:

```latex
\begin{theorem}[Gain-control with $\eta(\lambda,s)=f(s)$]    % L469
\label{thm:eta-s}
Suppose ... admits a gain-control representation ...          % L471-L489 hypothesis
with the following equivalence:                               % L490 transition
\begin{enumerate}[label=\textup{(\Alph*)}]                     % L498 (cases A-D enumeration begin)
  \item (Log-root case) ...
  ...
\end{enumerate}                                                % L539 (cases A-D enumeration end)
% L540-L549 post-enum closing prose (still inside theorem)
\end{theorem}                                                  % L550
```

(Line numbers grep-verified against current `main.tex` HEAD via `scripts/audit-theorem-boundaries.py`.)

**Pilot extraction (WRONG)** — stopped at L489 hypothesis end, treated cases
A-D enumeration (L498-L539) + post-enum closing prose (L540-L549) as
"post-statement narrative":

```
containing_block: thm:eta-s
location: main.tex:L469-L489    ← truncated! missed L490-L549 (60 lines)
```

**Correct extraction** — `\end{theorem}` at L550 is the only legitimate
boundary;cases A-D enumeration AND post-enum closing prose are both part
of the statement:

```
containing_block: thm:eta-s
location: main.tex:L469-L550    ← full env
(individual case props get location L498-L539 sub-ranges inside the
 \begin{enumerate}; post-enum prose at L540-L549 gets its own props)
```

### Worked example: Theorem 1 real boundary

Run audit script to get authoritative range. To see both the statement env
AND its matching proof env, query the JSON output (proof rows print as
`(no-label)` in text format, but their target binding is in `--format json`):

```bash
# Statement env (text format, grep by label):
python3 scripts/audit-theorem-boundaries.py manuscript/main.tex --format text \
    | grep "thm:eta-s"
# theorem         469    550  thm:eta-s

# Statement + proof association (json format):
python3 scripts/audit-theorem-boundaries.py manuscript/main.tex --format json \
    | python3 -c "import json,sys; \
        envs = json.load(sys.stdin); \
        [print(e) for e in envs if e.get('label') == 'thm:eta-s' or e.get('proof_target') == 'thm:eta-s']"
# {'type': 'theorem', 'begin_line': 469, 'end_line': 550, 'label': 'thm:eta-s', 'proof_target': None}
# {'type': 'proof',   'begin_line': 560, 'end_line': 714, 'label': None,        'proof_target': 'thm:eta-s'}
```

Then build extraction prompt:

```
=== TARGET ENV ===
theorem (label: thm:eta-s)
begin: main.tex:L469 (grep-verified)
end:   main.tex:L550 (grep-verified)
proof env (separate, handle next call): main.tex:L560-L714

=== SECTION TO EXTRACT ===
[paste lines L469-L550 here — full statement including hypothesis L471-L489
and the cases A-D enumeration L498-L539 plus post-enum closing prose L540-L549]
```

Result: clause-level extraction produces multiple props covering
hypothesis + setup + cases enumeration + closing prose. Concrete count
depends on the source file path:
- `_stage2/theorem1.jsonl` (Phase 2 canonical clause-level): the statement
  scope spans 16 source sentences per `EXTRACTION-WORKFLOW.md`'s map
- `main.jsonl` (Phase 1 heterogeneous, partly migrated): different count
  due to Phase 1 granularity heterogeneity + the 14 known boundary
  mismatches tracked as #114

The proof env is handled in a separate extraction call with its own
`containing_block: thm:eta-s/proof/<step>` sub-paths.

### See also

- `scripts/audit-theorem-boundaries.py` (#98) — mechanical LaTeX env parser
  with `--jsonl <path>` cross-check mode that asserts `prop.location` falls
  within real env boundaries. Run after extraction as acceptance gate.
- `manuscript/propositions/_stage3_baseline.md` (#98) — frozen inventory of
  all 7 numbered envs in current `main.tex`. Use as quick reference when
  extracting any theorem-like env.
- `manuscript/propositions/_stage2/EXTRACTION-WORKFLOW.md` § Pre-extraction
  sanity check (#98) — workflow-level discipline complementing this
  prompt-level rule.

## Per-call structure

```
User prompt:
=== GRANULARITY ===
heterogeneous | clause-level

=== TARGET ENV ===
<env-type> (label: <label>)
begin: main.tex:L<begin> (grep-verified or audit-script-verified)
end:   main.tex:L<end>   (grep-verified or audit-script-verified)
proof env (separate, if applicable): main.tex:L<pbegin>-L<pend>

(Required when extracting a numbered theorem-like env per
§ Pre-extraction sanity check Rule 2. Skip when target is a section
like sec:setup with no env boundary.)

=== SECTION TO EXTRACT ===
[paste lines L83-330 of main.tex here]

=== ID SCHEME ===
UUID v7 (RFC 9562 §5.7) — emit a freshly generated UUID per prop, lowercased
hex 8-4-4-4-12 layout with version field `7`. Do NOT emit sequential P/C
ordinals; display ordinals are derived at view time by the validator.

=== CONTAINING_BLOCK PREFIX ===
sec:setup
(used for first ~30 props; switch to lem:affine-bijection when entering Lemma A)
```

## Output format example (JSONL — one prop per line)

Every example below shows the **schema v1.2+ id contract** (UUID v7 lowercased
hex). Real extracted UUIDs will differ — these illustrate the expected layout.

```jsonl
{"id":"01910b9c-d4f0-7008-8aaa-000000000008","text":"Let $I, J, S \\subset \\R$ be intervals of positive length with $1 \\in I \\cap J$ and $I \\cdot J \\subset I$, $J \\cdot J \\subset J$.","location":"main.tex:L138-L139","containing_block":"sec:setup","claim_type":"axiom","asserts":["I, J, S are real intervals of positive length","1 belongs to both I and J","I·J is a subset of I","J·J is a subset of J"],"mathematical_objects":["I","J","S"],"introduces":["I","J","S"],"cites":[],"scope_qualifiers":{},"evidence_class":"conventional"}
```

Clause-level mode example (one source sentence split into 3 clauses; note the
cites field uses UUID v7 strings, not legacy C-prefix ordinals):

```jsonl
{"id":"01910b9c-d4f0-7c01-8aaa-000000000001","text":"Suppose $P_x(y)$ admits the gain-control representation","location":"main.tex:L466-L467","containing_block":"thm:eta-s","claim_type":"hypothesis","asserts":["Theorem stipulates: P_x(y) admits a gain-control representation"],"mathematical_objects":["P_x","y"],"cites":[],"scope_qualifiers":[],"evidence_class":"hypothesized"}
{"id":"01910b9c-d4f0-7c02-8aaa-000000000002","text":"$P_x(y) = F((u(y) - v(x))/\\sigma(x))$","location":"main.tex:L467","containing_block":"thm:eta-s","claim_type":"definition","asserts":["gain-control representation form: P_x(y) = F((u(y) - v(x))/sigma(x))"],"mathematical_objects":["P_x","F","u","v","sigma","x","y"],"introduces":["F","u","v","sigma"],"cites":["01910b9c-d4f0-7c01-8aaa-000000000001"],"scope_qualifiers":[],"evidence_class":"definitional"}
{"id":"01910b9c-d4f0-7c03-8aaa-000000000003","text":"with $u, v$ strictly monotonic and continuous,","location":"main.tex:L467-L468","containing_block":"thm:eta-s","claim_type":"hypothesis","asserts":["u and v are strictly monotonic and continuous"],"mathematical_objects":["u","v"],"cites":["01910b9c-d4f0-7c02-8aaa-000000000002"],"scope_qualifiers":[],"evidence_class":"hypothesized"}
```

## Curation checklist (human pass)

After LLM extraction, walk through each prop and check:

- [ ] `text` is verbatim match against `.tex` (grep-verify)
- [ ] `claim_type` is right (LLMs over-use "commentary"; downgrade meta-text
      to commentary but upgrade structurally-load-bearing sentences to claim
      or axiom)
- [ ] `cites` references resolve to existing IDs
- [ ] `asserts` captures the semantic content (not just verbose paraphrase)
- [ ] Boundary conditions appear in their own dedicated `axiom` prop (not
      buried in claim props) — these are validator hotspots

## When schema evolves

If a new field is added to SCHEMA.md, this prompt MUST be updated to
include it. Re-run extraction on already-extracted sections by feeding LLM
the old props + new field expectation, OR add via post-processing pass.

## See also

- SCHEMA.md — full per-proposition spec + bijection contract
- AI4o `bg-memory-proposition.md` — sibling extraction prompt for chat
  memory (different domain, same structural pattern)
