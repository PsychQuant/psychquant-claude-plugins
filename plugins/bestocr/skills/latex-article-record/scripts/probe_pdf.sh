#!/usr/bin/env bash
# probe_pdf.sh — classify a PDF as born-digital (has text layer) vs scanned
# (image-only), so the caller knows whether to extract text (accurate) or OCR.
#
# Usage: probe_pdf.sh <file.pdf>
# Prints a short report + a final VERDICT line the caller can grep.
set -euo pipefail

F="${1:-}"
if [ -z "$F" ] || [ ! -f "$F" ]; then
  echo "usage: probe_pdf.sh <file.pdf>" >&2
  exit 2
fi

echo "=== $F ==="

# Basic info
if command -v pdfinfo >/dev/null 2>&1; then
  pdfinfo "$F" 2>/dev/null | grep -E '^(Title|Author|Pages|Page size|Producer|Creator):' || true
fi
echo ""

# Embedded fonts = strong signal of a real text layer.
FONT_LINES=0
if command -v pdffonts >/dev/null 2>&1; then
  echo "--- fonts (pdffonts) ---"
  pdffonts "$F" 2>/dev/null | sed -n '1,12p' || true
  # data rows = total lines minus the 2 header rows
  FONT_LINES=$(pdffonts "$F" 2>/dev/null | sed '1,2d' | grep -c . || true)
  echo "embedded font rows: $FONT_LINES"
else
  echo "(pdffonts not installed — install poppler for reliable detection)"
fi
echo ""

# Extractable text sample.
TEXT_CHARS=0
if command -v pdftotext >/dev/null 2>&1; then
  SAMPLE="$(pdftotext -f 1 -l 2 "$F" - 2>/dev/null | tr -d '[:space:]' || true)"
  TEXT_CHARS=${#SAMPLE}
  echo "--- text sample (first non-empty lines, pages 1-2) ---"
  pdftotext -f 1 -l 2 "$F" - 2>/dev/null | grep -m 8 . || echo "(no extractable text)"
  echo "extractable chars (pp.1-2, whitespace-stripped): $TEXT_CHARS"
else
  echo "(pdftotext not installed — install poppler)"
fi
echo ""

# Verdict: born-digital if it has fonts AND meaningful extractable text.
# The thresholds are deliberately loose — a title page alone clears ~200 chars.
if [ "$FONT_LINES" -gt 0 ] && [ "$TEXT_CHARS" -gt 100 ]; then
  echo "VERDICT: born-digital  → extract the text layer; DO NOT OCR."
  echo "         (prose via pdftotext; read pages as IMAGES for any math)"
elif [ "$TEXT_CHARS" -gt 100 ]; then
  echo "VERDICT: text-present-but-no-fonts  → likely extractable; inspect before OCR."
else
  echo "VERDICT: scanned / image-only  → OCR needed (ocrmypdf or tesseract),"
  echo "         then correct the OCR output against the page images."
fi
