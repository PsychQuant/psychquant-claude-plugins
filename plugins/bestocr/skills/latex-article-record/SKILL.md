---
name: latex-article-record
description: >-
  Turn a journal / reference article PDF into a faithful, compile-verified LaTeX
  "article record" — metadata frontmatter + every theorem, definition and numbered
  equation (original numbers preserved) + references + flagged editorial notes —
  saved next to the PDF as year_author_title.tex. Reach for this whenever the user
  wants to transcribe, OCR, extract, "make a record of", or pull the theorems /
  equations out of a paper or PDF into LaTeX, or adds a reference PDF and wants it
  turned into a structured .tex — even when they literally say "OCR it": this skill
  checks for a text layer first and deliberately avoids OCR on born-digital PDFs,
  because re-recognizing rendered math is less accurate than reading the embedded
  text. Especially valuable for math-heavy papers where equation fidelity matters.
---

# LaTeX article record

Produce a faithful, verifiable LaTeX transcription of a published article PDF. The
output is a self-contained `.tex` "record" that reproduces the paper's math and
metadata so a collaborator (or a later AI) can cite `(19)` or `Theorem 2.6` and hit
the same thing the paper does — without re-opening the PDF.

The hard part is not writing LaTeX (the model already does that). The value this
skill adds is **discipline**: choosing the right extraction path, reading math from
the true 2-D layout instead of a flattened text stream, verifying by compiling and
looking, and refusing to silently "fix" the original. Follow the loop and the record
will be trustworthy; skip a step and it becomes a plausible-looking guess.

## When this fires

- "把這篇 PDF 轉成 tex / LaTeX / article record / 記錄", "transcribe this paper"
- "OCR this article" → still start here; **check for a text layer first** (see Step 1)
- "extract the theorems / equations from this paper into LaTeX"
- Dropping a reference PDF into `references/` and wanting a structured record

## The loop

```
1. Probe      → is the PDF born-digital (text layer) or scanned (images)?
2. Extract    → text layer for prose; READ PAGES AS IMAGES for any math
3. Transcribe → LaTeX record: metadata + statements + all numbered eqs, \tag'd
4. Verify     → compile → read the compiled PDF back → visual-diff vs source
5. Name+place → year_author_title.tex next to the source
```

### Step 1 — Probe the PDF

Run `scripts/probe_pdf.sh <file.pdf>`. It reports whether the PDF has an embedded
text layer (via `pdffonts`) and samples the extractable text.

- **Born-digital** (fonts listed, `pdftotext` returns real prose) → the characters
  already exist precisely; extract them. **Do not OCR.** OCR rasterizes the page and
  re-guesses each glyph, which for math fonts (Computer Modern, etc.) reliably
  mis-reads `ρ`↔`p`, `−`↔`-`, and sub/superscript positions. The embedded text is
  strictly better.
- **Scanned / image-only** (no fonts, `pdftotext` empty) → OCR is genuinely needed.
  Use `ocrmypdf` if available, else `tesseract`, then **correct against the page
  images** — OCR of math is error-prone, so treat its output as a draft to fix, not
  ground truth.

### Step 2 — Get the content at the right fidelity

Prose can come from `pdftotext` (fast, faithful characters). **Math cannot.**
`pdftotext` flattens 2-D structure: fractions become `a/b`, exponents fall inline
(`x^{ζ(ρ)}` → `xζ(ρ)`), bracket scope is lost. Working from that stream means
*guessing* which token is a superscript vs a coefficient.

So for any page containing equations, **read the PDF page as an image** (open it
visually) and transcribe from what you see. You get the real fraction bars,
sub/superscripts, and bracket ranges. This one habit is what separates a faithful
record from a confident-but-wrong one.

### Step 3 — Transcribe into the record

Use `references/record-template.tex` as the skeleton. Fill in:

- **Metadata comment block** (grep-able): bibkey, authors, title, journal, volume,
  year, pages, DOI/ISSN, MSC/subject codes, keywords, source PDF filename, and a
  **PROVENANCE** note stating it was transcribed + how it was verified.
- **Body**: the verbatim summary/abstract, then the math content organized by the
  paper's own sections. Transcribe **every numbered display equation**, every
  theorem/definition/lemma **statement**, and any tables. You may **condense the
  connecting proof prose** (a reader wanting the full prose has the PDF) — but keep
  all numbered equations, because those are what people cite.
- **References**: transcribe the bibliography verbatim (it's often what you came for).

**Preserve the paper's own numbers.** Use `\tag{4}`, `\tag{19}`, etc. on each display
equation and manual headings like `\paragraph{2.6.\ Theorem.}` so that "(19)" and
"Theorem 2.6" in the record mean exactly what they mean in the paper. Never let
LaTeX auto-number — the numbers would drift from the source and every cross-reference
would rot.

### Step 4 — Verify (this is the anti-fooling step, don't skip it)

Run `scripts/compile_check.sh <record.tex>`. It compiles twice (to a temp dir) and
reports errors / overfull boxes / page count. Fix until it's clean (0 errors).

**Then read the compiled PDF back as images and visually diff it against the source
pages.** Compilation only proves the LaTeX is well-formed — it says nothing about
whether you transcribed the *right* symbols. The visual diff is what catches a
misread `α` vs `a`, a dropped exponent, or a flipped inequality. A record that
compiles but was never eyeballed against the original is not verified.

### Step 5 — Name and place

Save as `<year>_<Author(s)>_<short-title-slug>_record.tex` next to the source PDF
(e.g. `references/journal_articles/`). Two authors → join with a hyphen
(`Falmagne-Lundberg`); many → first author + `-etal`. Keep the title slug short but
meaningful (drop subtitle/dedication). If the source PDF has an opaque name (a DOI
code, `s000100050146.pdf`), rename it and any extracted `.txt` to the shared stem so
the reference set is human-readable and self-consistent.

**The `_record` suffix on the `.tex` is load-bearing, not cosmetic.** If the record
shares the PDF's exact stem (`X.tex` next to `X.pdf`), any LaTeX auto-build — an
editor's compile-on-save (VS Code LaTeX Workshop, latexmk watchers) — writes its
output to `X.pdf` and **silently clobbers the source PDF you transcribed from**.
This happened in the wild on the first use of this workflow: the original 10-page
journal PDF was overwritten by the record's own 6-page render before anyone noticed,
and was only recoverable because a copy survived in `~/Downloads`. The `_record`
suffix makes auto-build output land on `X_record.pdf`, which is harmless. After
finishing, also delete any build residue next to the sources (`.aux`, `.log`,
`.fls`, `.fdb_latexmk`, `.xdv`).

## Verbatim discipline (the guardrails)

The record is an audit artifact — its worth is that it faithfully reflects the paper,
including the paper's warts. So:

- **Flag inconsistencies; never silently fix them.** If the paper says "Theorem 2.5"
  where it clearly means 2.6, or an equation has an obvious typo, transcribe it
  as-printed and note it in an **Editorial / transcription notes** section at the end
  (clearly marked "not part of the original paper"). Silently "correcting" the
  original destroys the record's job and hides a real finding from the reader.
- **Own the hard-to-read spots.** If a glyph is genuinely ambiguous in the source,
  transcribe your best reading, say why (e.g. "forced by eq. (33)"), and note the
  ambiguity. Honest uncertainty beats confident invention.
- **Don't paraphrase math into different notation.** Keep the paper's symbols and
  bracket style (`F[...]` stays `F[...]`); the record should read as the paper, not
  as your restatement of it.

## GitHub-math note (if the record or its notes also go into markdown)

If you surface equations in a GitHub issue/PR/markdown (not just the `.tex`),
variable names with underscores go in backtick code, not math mode, and watch
multiple `$…$` with underscores on one line (KaTeX/emphasis conflicts). Inside the
`.tex` itself this doesn't apply.

## Files

- `scripts/probe_pdf.sh` — classify born-digital vs scanned + sample text-layer quality
- `scripts/compile_check.sh` — pdflatex ×2 to a temp dir; report errors / overfull / pages
- `references/record-template.tex` — the metadata + structure skeleton to fill in
