---
name: clarity-audit
description: >-
  Fix clarity problems in math/stats writing at ANY scale — one confusing sentence up to a whole section, not just whole-manuscript passes. Trigger when the reader stalls on a technical passage: unclear / abrupt / "太突兀" / "看不懂" / "怎麼來的" / "這是正式說法嗎" / "難連結", or "proofread / 整理 this derivation", or "is this the same as <standard result>". Names the specific stall (unanchored term, definition-away-from-use, claim-without-reason, notation clash, non-standard terminology) and rewrites the passage self-contained. This is the readability axis — distinct from proofread (per-proposition correctness). Reach for it even for a single sentence, over an ad-hoc inline rewrite.
---

# Math Writing Clarity Audit

## The one idea

Almost every "I can't follow this" in a derivation has the same root cause: **a
named or asserted thing is not connected to its concrete referent or its
reason.** The reader meets a symbol, a term of art, or a claim, and is silently
expected to supply the missing link. When they can't, they stall.

So the whole job is: **find the missing links and supply them — one at a time.**
You are simultaneously a *reader-stumble detector* (read as someone meeting this
cold, and notice where you'd stop) and a *bridge-builder* (write the one
sentence or formula that connects the named thing to what it actually is).

This is not grammar or style copy-editing. A passage can be grammatically
perfect and still unreadable because the connective tissue is missing.

## When you're invoked

- **Reactive** (most common): the user quotes a passage and signals a stumble —
  "看不懂", "太突兀", "怎麼來的", "這是正式說法嗎", "難連結", "這跟 X 一樣嗎".
  Fix *that* passage.
- **Proactive**: "proofread / 整理 this derivation", "read §3 and check it's
  coherent". Sweep for stumbles, then fix.

In both cases the deliverable is the same: a diagnosis the user can see, plus a
rewrite that removes the stumble.

## Relationship to the other math-tools skills

math-tools audits a manuscript along several axes; this skill owns *readability*.
Don't confuse it with its siblings — they answer different questions:

| Skill | Question it answers | Driven by |
|-------|--------------------|-----------|
| `propositions` | Are the claims extracted atomically, with a valid dependency DAG? | JSONL + R1-R8 |
| `proofread` | Is each proposition true, faithful, correctly typed and cited? | JSONL, per-prop L1-L5 |
| `manuscript-audit` | Do main.tex / jsonl / code / bib stay consistent with each other? | cross-artifact R1-R4 |
| **`clarity-audit`** (this) | **Can a human reader follow the prose?** | **free-form, no JSONL needed** |

The practical tell: if the complaint is "this is *wrong* / inconsistent / a
citation is off", that's `proofread` / `manuscript-audit`. If the complaint is
"this is *right* but I can't follow it", that's this skill. clarity-audit is
lightweight — it works on a pasted paragraph with no side-file, so it's the tool
for a quick "why is this hard to read" pass, not a full per-proposition walk.

## The reader-stumble taxonomy

Diagnose which of these is happening. Most stumbles are the first one.

### 1. Unanchored name or term (the missing bridge — the big one)

A symbol, object, or term of art is used without connecting it to its concrete
form or meaning. The tell: the reader can define the word but can't see *which
concrete thing in front of them it refers to*.

- An increment `δ` is solved for, then the update is written out in full — the
  reader can't see the big expression *is* `α·δ`. → Write `θ⁺ = θ + α δ`, then
  the expanded form: "that is, [full expression]".
- "which is the Gauss–Newton step" — named but not tied to the form the reader
  knows. → "the weighted Gauss–Newton step: ordinary Gauss–Newton with the
  weight `W` inserted; the unweighted case is `W = I`."
- "equivalently Fisher scoring" — asserted, not shown. → give the reason
  (e.g. the Hessian splits into `JᵀWJ` plus a term that vanishes in expectation).
- A term of art ("Armijo step", "ADF weight") dropped with no grounding. → say
  what it *is* in one clause (a backtracking-chosen step length; the empirical
  fourth-moment covariance) and, where possible, name whose result it is.

**Fix:** add the one clause/formula that connects the name to its concrete
referent. Prefer showing the reduction to a familiar special case.

### 2. Definition away from first use

A symbol is defined pages before (or after) it is first used, so the reader
either forgets it or meets it undefined. The tell: you scan back/forward to find
where something was defined.

**Fix:** move each definition to where the symbol is first used. A symbol used
only in §3 should be defined in §3, not parked next to unrelated definitions in
§2.

### 3. Claim asserted without its reason — and the honest-boundary trap

A design choice or equivalence is stated as fact with no "why". The subtle
failure mode: over-claiming that a *specific* choice is *necessary* when a weaker
condition actually suffices. A sharp reader (or reviewer) will object "but any X
would do — why this one?".

**Fix:** give the reason, and be honest about the boundary. If any vanishing
rate preserves the first-order law, *say so*, then justify the specific rate on
its real grounds (e.g. it matches the sampling noise it regularizes).
Volunteering the weaker sufficient condition and then motivating the choice is
more convincing than hiding it — it disarms the objection instead of inviting it.

### 4. Colliding or overloaded notation

The same letter (up to case) carries two meanings, or two things look alike. The
classic: lowercase `k` as an iteration index and uppercase `K` as a count/family
parameter, with the relation never stated. The tell: the reader conflates them.

**Fix:** state the relation explicitly ("iterate `k = 0,…,K−1` to get the K-step
estimate `θ_K`"). If it stays confusing, rename one symbol.

A quieter variant is an **accent that has gone stale**. Accents carry meaning —
tilde for a √n-consistent preliminary, hat for the refined estimator — so when
the framing changes they need re-auditing. If a reframing promotes the
preliminary from scaffolding to a full member of the family, its tilde now tells
the reader something false. And if one accent is carrying two distinctions at
once (preliminary-versus-refined *and* numerical-output-versus-exact-minimizer),
one of them has to give: keep the accent for the distinction that still earns it,
and let a subscript or superscript carry the other.

### 5. Non-standard terminology

A home-grown phrase where a term of art exists. It reads as understandable but
slightly off, and it fails to plug the passage into the literature the reader
knows. Example: "first-order law" where the field says "first-order equivalent".

**Fix:** use the standard term. Bonus: the term of art often *names a whole
theory* (e.g. "first-order equivalent" invokes one-step-estimator theory), so
the reader places your result for free.

### 6. Un-signposted transition

A new sentence silently assumes the reader carried a result forward. The tell:
"wait, where did this come from?".

**Fix:** one signpost sentence naming the carried thing ("This increment `δ` is
the search direction. Stepping along it gives …").

### 7. Unexpanded abbreviation or unexplained operator

An initialism or operator is used before — or without ever — being expanded:
`PF(0.50)`, `GMM`, `vech`. Unlike category 1 this one is mechanical: list every
capitalised initialism and every custom operator in the document and ask where
each is introduced.

The tell you cannot rely on is your own familiarity. `vech` is invisible to
anyone who works with covariance structures and opaque to everyone else, and it
is often load-bearing: `q = p(p+1)/2` is *the number of entries `vech` returns*,
so a reader who does not know the operator cannot see where `q` came from.

**Fix:** expand at first use, then delete any later duplicate definition. Put the
words before the short form, not after — "the conventional single-start
principal-factor ADF, written PF(0.50)–ADF", not "PF(0.50)–ADF … started from a
principal-factor solution".

### 8. Prose that misdescribes the implementation

The passage documents what the code does, and documents it wrongly. Example: text
saying a comparator starts from "initial communalities at 0.50" when the
implementation sets initial *uniquenesses* to 0.50 times the observed variances.
The two coincide at 0.50 and diverge everywhere else, so the error is invisible
until someone opens the code.

This is the one class you cannot diagnose from the prose. When a passage
documents an implementation — a design grid, an algorithm's constants, a
comparator's definition, a random-number scheme — **read the code**; do not
reason about what the description probably meant.

**Fix:** say what the code does, in the code's own terms.

### 9. Attribution the cited work itself contradicts

"X's algorithm", "the criterion derived by X" — an eponym or credit the cited
source does not support. This is a precision failure, not only a discourtesy, and
it is at its worst when the misattributed person is the reader.

**Fix:** read what the cited paper says about its own contribution. Authors are
usually explicit ("a novel estimator was developed in the early 2000s by …", "we
show that …"), and their own bibliography is the authoritative source for the
metadata of the earlier work — better than reconstructing it from memory, which
is how invented titles and affiliations get in. Credit each layer separately: who
introduced the object, who proved the property, who supplied the form actually
being used.

## Procedure

Work one stumble at a time — do not batch a dozen edits into one pass. Each
fix is small and independently verifiable, and the user is reviewing.

1. **Diagnose out loud.** Name the category and the exact missing link. The user
   learns the pattern and can confirm you've read their intent.
2. **Explain the mathematics first, in chat.** Before touching the manuscript,
   make sure *you* (and the user) actually understand the object. A rewrite built
   on a shaky understanding will be wrong-but-fluent, the worst outcome. If you
   are not sure a claim is true, verify it (derive it, check the sign/direction,
   look up the source) before writing it. Never fluently assert what you have not
   checked.
3. **Rewrite to anchor.** Supply the missing bridge / move the definition / give
   the why / use the standard term. Keep the author's voice.
4. **Verify — and remember that a clean compile is not proof.** If it's LaTeX,
   compile (build → bib → build → build) and confirm 0 undefined refs, 0 errors,
   and that the intended text rendered (spot-check with a PDF-to-text pass).
   That checks what you *added*. It does not check what silently *disappeared*.
   Anything touching the preamble — a package, a font, an encoding — can delete
   content while reporting success: loading `fontspec` into a document whose math
   relies on legacy encodings makes bold Greek capitals resolve against a Unicode
   text font, which drops them. The log says only `Missing character: ^^C`, the
   build exits 0, and 28 symbols are gone from the PDF. So when you touch the
   preamble, **diff the rendered output**: extract the text of the new and old
   PDFs and compare counts for the glyphs the document depends on. A rewrite that
   doesn't compile is not done; a preamble change that wasn't diffed isn't
   verified.
5. **Confirm the connection actually lands.** Re-read the rewritten passage as a
   cold reader: is the named thing now reachable? If not, the bridge is still
   missing.

## Organize last, not first

When asked to "整理" / tidy a long passage, fix the *connective tissue first*
(the bridges above), and only then split into paragraphs. Reason: paragraph
breaks on top of a still-jumpy argument just cut one wall of text into several
smaller walls. Once every named thing is anchored, breaking into one-idea
paragraphs is the finishing move, not the fix.

## Voice and honesty (reference, don't reinvent)

This skill governs *what to fix*, not house-style. For the writing voice —
plain prose, no em-dash asides, no "顯然"/"clearly", no AI-cliché — defer to the
author's own style guide (`colleague-che-cheng-math` and
`colleague-che-cheng-academic`). For higher-level structural rules like
theorem-vs-remark altitude placement, defer to `che-axiom-systems`
`mathematical-writing`. Do not duplicate those here; this skill is the *process*
of finding and closing reader-stumbles.

Two honesty rules are load-bearing enough to restate:
- **Never assert what you haven't verified.** Fluent-but-wrong is worse than a
  visible gap. Check the math, then write it.
- **Concede the weaker sufficient condition.** When a specific choice isn't
  strictly necessary, say what *is* necessary, then motivate the choice. This is
  what makes the writing survive a hostile reader.

## Examples

**Example 1 — unanchored result → connect to the familiar form**
Input: "…gives the update θ_{k+1} = θ_k + α_k (JᵀWJ)⁻¹JᵀW g, which is the
Gauss–Newton step."
Output: "…gives the update θ_{k+1} = θ_k + α_k δ, that is, θ_{k+1} = θ_k +
α_k (JᵀWJ)⁻¹JᵀW g, the weighted Gauss–Newton step: ordinary Gauss–Newton with
the weight W inserted, the unweighted case being W = I."

**Example 2 — asserted claim → honest reason**
Input: "The ridge vanishes as n grows, so the first-order asymptotics are
unchanged."
Output: "Any vanishing rate sends the weight to its target and leaves the
first-order asymptotics unchanged; the order n^{-1/2} is chosen because it
matches the O_p(n^{-1/2}) sampling error of the weight, so the ridge stays the
size of the noise it regularizes."

**Example 3 — notation collision**
Input: update written with index k; family called "K-step method"; relation
never stated.
Output: add "Running the update for k = 0,…,K−1 from the starting point gives
the K-step estimate θ_K."
