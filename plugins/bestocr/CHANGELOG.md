# Changelog

## 0.1.0 — 2026-07-18

- Initial release with one skill: `latex-article-record`.
  - Journal / reference PDF → faithful LaTeX "article record" saved as
    `<year>_<Author>_<slug>_record.tex` next to the source PDF.
  - Decision tree: `probe_pdf.sh` classifies born-digital vs scanned;
    born-digital PDFs are text-layer-extracted, never OCR'd (math fidelity).
  - Math transcribed from page images (true 2-D layout), equations keep the
    paper's own numbers via `\tag{}`.
  - Verification loop: `compile_check.sh` (pdflatex ×2 to temp dir) + read the
    compiled PDF back and visual-diff against the source pages.
  - Verbatim discipline: original typos / ambiguous glyphs are flagged in an
    editorial-notes section, never silently corrected.
  - `_record` filename suffix is load-bearing: same-stem `.tex` next to the
    source PDF gets clobbered by editor auto-compile (learned the hard way).
