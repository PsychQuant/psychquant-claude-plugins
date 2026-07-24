#!/usr/bin/env bash
# run-audit.sh — Full manuscript consistency audit orchestrator.
#
# Runs four audit passes (R1 symbols, R2 + R2-bis citations, R3 code-manuscript drift,
# R4 proposition-iso bijection check) and writes a merged dated report to
# manuscript/docs/audit/audit-YYYY-MM-DD.md. R4 is skipped if neither
# propositions/main.jsonl nor legacy propositions/main.json is present (only
# manuscripts that opt into Locke-project proposition tracking will have one).
#
# See .claude/rules/manuscript-consistency-audit.md §8 for pre-flight + post-flight steps.
#
# Usage:
#   ./scripts/run-audit.sh <manuscript-root> [--code-root analysis/]
#
# Exit code:
#   0 — clean (zero findings across all passes)
#   1 — at least one finding (any severity)
#   2 — tool error

set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <manuscript-root> [--code-root <code-root>]" >&2
  exit 2
fi

MANUSCRIPT_ROOT="$1"
shift
CODE_ROOT="analysis"
# F5 fix: validate --code-root has a value before consuming it; previously
# `./run-audit.sh manuscript --code-root` with missing value would crash with
# rc=1 due to set -u + unbound $2, but SOP §8 contract says missing args = rc=2.
while [[ $# -gt 0 ]]; do
  case "$1" in
    --code-root)
      if [[ $# -lt 2 ]] || [[ "$2" == --* ]]; then
        echo "error: --code-root requires a value" >&2
        exit 2
      fi
      CODE_ROOT="$2"
      shift 2
      ;;
    *)
      echo "Unknown arg: $1" >&2
      exit 2
      ;;
  esac
done

# L3 fix: validate inputs BEFORE creating AUDIT_DIR to avoid polluting empty
# dirs when a pre-flight check would fail anyway.
if [[ ! -d "$MANUSCRIPT_ROOT" ]]; then
  echo "error: manuscript root not found: $MANUSCRIPT_ROOT" >&2
  exit 2
fi
if [[ ! -d "$CODE_ROOT" ]]; then
  echo "error: code root not found: $CODE_ROOT" >&2
  exit 2
fi

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
AUDIT_DIR="$MANUSCRIPT_ROOT/docs/audit"
DATE_TAG="$(date +%F)"
REPORT="$AUDIT_DIR/audit-${DATE_TAG}.md"

mkdir -p "$AUDIT_DIR"

# Capture manuscript snapshot for audit trail
SNAPSHOT="(no git info)"
if (cd "$MANUSCRIPT_ROOT" && git rev-parse HEAD &>/dev/null); then
  SNAPSHOT="$(cd "$MANUSCRIPT_ROOT" && git rev-parse HEAD)"
fi

PYTHON="${PYTHON:-python3}"
R1_OUT="$(mktemp)"
R2_OUT="$(mktemp)"
R3_OUT="$(mktemp)"
R4_OUT="$(mktemp)"
trap 'rm -f "$R1_OUT" "$R2_OUT" "$R3_OUT" "$R4_OUT"' EXIT

R1_RC=0
R2_RC=0
R3_RC=0
R4_RC=0
R4_SKIPPED=0

"$PYTHON" "$REPO_ROOT/scripts/audit-symbols.py" \
  --manuscript-root "$MANUSCRIPT_ROOT" --report-format md > "$R1_OUT" || R1_RC=$?
"$PYTHON" "$REPO_ROOT/scripts/audit-citations.py" \
  --manuscript-root "$MANUSCRIPT_ROOT" --report-format md > "$R2_OUT" || R2_RC=$?
"$PYTHON" "$REPO_ROOT/scripts/audit-code-manuscript.py" \
  --manuscript-root "$MANUSCRIPT_ROOT" --code-root "$CODE_ROOT" --report-format md > "$R3_OUT" || R3_RC=$?

# R4 proposition-iso bijection check (Phase 1 prop-subset-check + smoke tests)
# Skip if manuscript has not opted into Locke-project proposition tracking
PROPS_JSONL="$MANUSCRIPT_ROOT/propositions/main.jsonl"
PROPS_META="$MANUSCRIPT_ROOT/propositions/_meta.json"
PROPS_JSON_LEGACY="$MANUSCRIPT_ROOT/propositions/main.json"
MAIN_TEX="$MANUSCRIPT_ROOT/main.tex"
if [[ -f "$PROPS_JSONL" ]] && [[ -f "$MAIN_TEX" ]]; then
  META_FLAG=()
  [[ -f "$PROPS_META" ]] && META_FLAG=(--meta "$PROPS_META")
  "$PYTHON" "$REPO_ROOT/scripts/validate-propositions.py" \
    --jsonl "$PROPS_JSONL" "${META_FLAG[@]}" --tex "$MAIN_TEX" > "$R4_OUT" 2>&1 || R4_RC=$?
elif [[ -f "$PROPS_JSON_LEGACY" ]] && [[ -f "$MAIN_TEX" ]]; then
  "$PYTHON" "$REPO_ROOT/scripts/validate-propositions.py" \
    --json "$PROPS_JSON_LEGACY" --tex "$MAIN_TEX" > "$R4_OUT" 2>&1 || R4_RC=$?
else
  R4_SKIPPED=1
  echo "_R4 proposition-iso: SKIPPED (propositions/main.jsonl, legacy main.json, or main.tex not found)_" > "$R4_OUT"
fi

# Bail on tool error (rc=2) from any pass
if [[ "$R1_RC" -ge 2 ]] || [[ "$R2_RC" -ge 2 ]] || [[ "$R3_RC" -ge 2 ]] || [[ "$R4_RC" -ge 2 ]]; then
  echo "error: at least one audit pass failed with rc=2" >&2
  exit 2
fi

# F2 fix: aggregate Summary counts per SOP §7 (Definite / Likely / Suspicious / FYI)
# by extracting "## <Sev> (N)" headers from each pass's md output and summing.
# Falls back to "(no data)" if a pass produced no per-severity section.
count_severity() {
  local file="$1" sev="$2"
  # Match "## Definite (N)", "## Likely (N)", etc. (case-insensitive on Sev)
  local n
  n=$(grep -i -E "^## ${sev} \\(([0-9]+)\\)" "$file" 2>/dev/null | sed -E "s/.*\\(([0-9]+)\\).*/\\1/" | head -1)
  echo "${n:-0}"
}

R1_DEF=$(count_severity "$R1_OUT" "Definite")
R1_LIK=$(count_severity "$R1_OUT" "Likely")
R1_SUS=$(count_severity "$R1_OUT" "Suspicious")
R2_DEF=$(count_severity "$R2_OUT" "Definite")
R2_LIK=$(count_severity "$R2_OUT" "Likely")
R3_DEF=$(count_severity "$R3_OUT" "Definite")
R3_FYI=$(count_severity "$R3_OUT" "Fyi")
# R4 reports rule-level PASS/FAIL not Definite/Likely. Count `ERROR(s)` /
# `WARNING(s)` blocks from validate-propositions.py output as proxy.
if [[ "$R4_SKIPPED" -eq 1 ]]; then
  R4_ERR="—"
  R4_WARN="—"
else
  R4_ERR=$(grep -E "^=== [0-9]+ ERROR\\(s\\)" "$R4_OUT" | head -1 | sed -E "s/.*=== ([0-9]+) ERROR.*/\\1/" || echo 0)
  R4_WARN=$(grep -E "^=== [0-9]+ WARNING\\(s\\)" "$R4_OUT" | head -1 | sed -E "s/.*=== ([0-9]+) WARNING.*/\\1/" || echo 0)
  R4_ERR="${R4_ERR:-0}"
  R4_WARN="${R4_WARN:-0}"
fi
TOTAL_DEF=$((R1_DEF + R2_DEF + R3_DEF))
TOTAL_LIK=$((R1_LIK + R2_LIK))
TOTAL_SUS=$R1_SUS
TOTAL_FYI=$R3_FYI

# Merge into dated report
{
  echo "# Manuscript Consistency Audit — ${DATE_TAG}"
  echo
  echo "**Manuscript snapshot**: \`${SNAPSHOT}\`"
  echo "**Tool versions**: audit-symbols.py 0.1.0 / audit-citations.py 0.1.0 / audit-code-manuscript.py 0.1.0 / validate-propositions.py 0.1.0"
  echo "**Exit codes**: R1=${R1_RC} / R2=${R2_RC} / R3=${R3_RC} / R4=${R4_RC}$([[ $R4_SKIPPED -eq 1 ]] && echo ' (skipped)')"
  echo
  echo "## Summary"
  echo
  echo "| Severity | R1 (symbols) | R2 (citations) | R3 (code↔manuscript) | Total |"
  echo "|----------|--------------|----------------|----------------------|-------|"
  echo "| Definite | ${R1_DEF} | ${R2_DEF} | ${R3_DEF} | ${TOTAL_DEF} |"
  echo "| Likely | ${R1_LIK} | ${R2_LIK} | — | ${TOTAL_LIK} |"
  echo "| Suspicious | ${R1_SUS} | — | — | ${TOTAL_SUS} |"
  echo "| FYI | — | — | ${R3_FYI} | ${TOTAL_FYI} |"
  echo
  echo "## R4 proposition-iso (separate counts: rule-level PASS/FAIL not severity)"
  echo
  echo "| Pass | Errors | Warnings |"
  echo "|------|--------|----------|"
  echo "| R4   | ${R4_ERR} | ${R4_WARN} |"
  echo
  echo "---"
  echo
  cat "$R1_OUT"
  echo
  echo "---"
  echo
  cat "$R2_OUT"
  echo
  echo "---"
  echo
  cat "$R3_OUT"
  echo
  echo "---"
  echo
  echo "## R4: Proposition-iso (validate-propositions.py)"
  echo
  echo '```'
  cat "$R4_OUT"
  echo '```'
} > "$REPORT"

echo "→ Audit report: $REPORT"
echo "→ Pass exit codes: R1=${R1_RC} R2=${R2_RC} R3=${R3_RC} R4=${R4_RC}$([[ $R4_SKIPPED -eq 1 ]] && echo ' (skipped)')"

# Aggregate exit: 1 if any pass found findings
if [[ "$R1_RC" -eq 1 ]] || [[ "$R2_RC" -eq 1 ]] || [[ "$R3_RC" -eq 1 ]] || [[ "$R4_RC" -eq 1 ]]; then
  exit 1
fi
exit 0
