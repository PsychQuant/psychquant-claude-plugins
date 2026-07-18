#!/usr/bin/env bash
# compile_check.sh — compile a LaTeX record twice to a temp dir and report health.
# Compiling proves the LaTeX is well-formed; it does NOT prove the transcription is
# correct — you still must read the compiled PDF back and visual-diff it vs the
# source. This script just makes the "0 errors" gate fast and repeatable.
#
# Usage: compile_check.sh <record.tex>
# Prints error/overfull/page counts + the temp PDF path (for you to read back).
set -uo pipefail

TEX="${1:-}"
if [ -z "$TEX" ] || [ ! -f "$TEX" ]; then
  echo "usage: compile_check.sh <record.tex>" >&2
  exit 2
fi

if ! command -v pdflatex >/dev/null 2>&1; then
  echo "✗ pdflatex not found (install a TeX distribution: MacTeX / TeX Live)." >&2
  exit 3
fi

DIR="$(cd "$(dirname "$TEX")" && pwd)"
BASE="$(basename "$TEX" .tex)"
OUT="$(mktemp -d "${TMPDIR:-/tmp}/texcheck.XXXXXX")"

run() {
  ( cd "$DIR" && pdflatex -interaction=nonstopmode -halt-on-error \
      -output-directory="$OUT" "$BASE.tex" ) >"$OUT/run$1.log" 2>&1
}

run 1 && echo "run 1 OK" || echo "run 1 FAIL (see $OUT/run1.log)"
run 2 && echo "run 2 OK" || echo "run 2 FAIL (see $OUT/run2.log)"

LOG="$OUT/run2.log"
[ -f "$LOG" ] || LOG="$OUT/run1.log"

ERRORS=$(grep -c '^! ' "$LOG" 2>/dev/null || echo 0)
OVERFULL=$(grep -c 'Overfull' "$LOG" 2>/dev/null || echo 0)
UNDEF=$(grep -c 'Undefined control sequence' "$LOG" 2>/dev/null || echo 0)
PAGES="?"
if [ -f "$OUT/$BASE.pdf" ] && command -v pdfinfo >/dev/null 2>&1; then
  PAGES=$(pdfinfo "$OUT/$BASE.pdf" 2>/dev/null | awk '/^Pages/{print $2}')
fi

echo "---"
echo "errors:            $ERRORS"
echo "undefined cmds:    $UNDEF"
echo "overfull hboxes:   $OVERFULL"
echo "pages:             $PAGES"
echo "compiled PDF:      $OUT/$BASE.pdf"
if [ "$ERRORS" -gt 0 ] || [ "$UNDEF" -gt 0 ]; then
  echo ""
  echo "--- first errors ---"
  grep -nE '^! |Undefined control sequence|Missing|Runaway' "$LOG" 2>/dev/null | head
  exit 1
fi
echo ""
echo "NEXT: read $OUT/$BASE.pdf back as images and visual-diff against the source pages."
