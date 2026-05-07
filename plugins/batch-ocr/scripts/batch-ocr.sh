#!/usr/bin/env bash
# batch-ocr — Folder-level OCR pipeline orchestrator.
#
# Wraps macdoc CLI with: PDF→PNG split (pdftoppm) → parallel OCR (xargs -P)
# → per-page md merge → idempotent resume → structured logging.
#
# Usage:
#   batch-ocr.sh <dir-of-pdfs> [--parallel N] [--host HOST] [--model M] [--dpi D] [--resume]

set -u
set -o pipefail

# --- Argument parsing --------------------------------------------------------
INPUT_DIR=""
PARALLEL="${BATCH_OCR_PARALLEL:-4}"
HOST="${BATCH_OCR_HOST:-localhost:11500}"
MODEL="${BATCH_OCR_MODEL:-glm-ocr}"
DPI="${BATCH_OCR_DPI:-200}"
REMOTE_HOST="${BATCH_OCR_REMOTE_HOST:-kyle}"
RESUME=0
SESSION_ID="${BATCH_OCR_SESSION_ID:-$(date +%Y%m%d-%H%M%S)}"

while (( $# > 0 )); do
    case "$1" in
        --parallel) PARALLEL="$2"; shift 2 ;;
        --host) HOST="$2"; shift 2 ;;
        --model) MODEL="$2"; shift 2 ;;
        --dpi) DPI="$2"; shift 2 ;;
        --remote-host) REMOTE_HOST="$2"; shift 2 ;;
        --resume) RESUME=1; shift ;;
        --session) SESSION_ID="$2"; shift 2 ;;
        -*)
            echo "Unknown flag: $1" >&2
            exit 2
            ;;
        *)
            if [[ -z "$INPUT_DIR" ]]; then
                INPUT_DIR="$1"
            else
                echo "Unexpected extra argument: $1" >&2
                exit 2
            fi
            shift
            ;;
    esac
done

if [[ -z "$INPUT_DIR" ]]; then
    echo "Usage: batch-ocr.sh <dir-of-pdfs> [options]" >&2
    exit 2
fi
if [[ ! -d "$INPUT_DIR" ]]; then
    echo "Error: '$INPUT_DIR' is not a directory" >&2
    exit 2
fi

# --- Session paths -----------------------------------------------------------
SESSION_DIR="${INPUT_DIR}/.batch-ocr/${SESSION_ID}"
mkdir -p "$SESSION_DIR"
LOG="${SESSION_DIR}/log"
FAILURES="${SESSION_DIR}/failures.log"
PERMANENT="${SESSION_DIR}/permanent_failures.log"
: > "$FAILURES"

log() {
    echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')] $*" | tee -a "$LOG"
}

# --- Phase 0: ensure SSH tunnel ---------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ "$HOST" == localhost:* ]] && [[ -n "$REMOTE_HOST" ]]; then
    LOCAL_PORT="${HOST##*:}"
    log "Phase 0: ensure SSH tunnel localhost:${LOCAL_PORT} → ${REMOTE_HOST}"
    "${SCRIPT_DIR}/ensure-tunnel.sh" "$LOCAL_PORT" "$REMOTE_HOST" 11434 || {
        log "FATAL: SSH tunnel could not be established"
        exit 3
    }
fi

# --- Phase 1: PDF → PNG split -----------------------------------------------
log "Phase 1: split PDFs in '$INPUT_DIR' to PNG (DPI=$DPI)"
PHASE1_NEW=0
PHASE1_SKIP=0
shopt -s nullglob
for pdf in "$INPUT_DIR"/*.pdf; do
    base="${pdf%.pdf}"
    name="$(basename "$base")"
    page_dir="${INPUT_DIR}/${name}"
    final_md="${INPUT_DIR}/${name}.md"

    if [[ -s "$final_md" ]] && [[ "$RESUME" -eq 0 ]]; then
        PHASE1_SKIP=$((PHASE1_SKIP + 1))
        continue
    fi

    if [[ -d "$page_dir" ]] && compgen -G "${page_dir}/page-*.png" >/dev/null; then
        # Already split — skip
        PHASE1_SKIP=$((PHASE1_SKIP + 1))
        continue
    fi

    mkdir -p "$page_dir"
    if pdftoppm -r "$DPI" -png "$pdf" "${page_dir}/page" 2>>"$LOG"; then
        PHASE1_NEW=$((PHASE1_NEW + 1))
    else
        log "FAIL Phase 1: $pdf"
        echo "$pdf" >> "$FAILURES"
    fi
done
log "Phase 1 done: ${PHASE1_NEW} split, ${PHASE1_SKIP} skipped"

# --- Phase 2: parallel OCR --------------------------------------------------
log "Phase 2: OCR PNGs in parallel (P=$PARALLEL, host=$HOST, model=$MODEL)"
PHASE2_TOTAL=0
PHASE2_PENDING_LIST=$(mktemp)
trap 'rm -f "$PHASE2_PENDING_LIST"' EXIT

while IFS= read -r png; do
    [[ -f "${png}.md" ]] && continue
    PHASE2_TOTAL=$((PHASE2_TOTAL + 1))
    echo "$png"
done < <(find "$INPUT_DIR" -name 'page-*.png' -type f) > "$PHASE2_PENDING_LIST"

if [[ "$PHASE2_TOTAL" -gt 0 ]]; then
    log "Phase 2: ${PHASE2_TOTAL} pages pending"
    xargs -P "$PARALLEL" -I{} bash -c '
        png="$1"; host="$2"; model="$3"; failures="$4"; logfile="$5"
        if macdoc ocr "$png" --output "${png}.md" --host "$host" --model "$model" 2>>"$logfile"; then
            echo "[$(date +%H:%M:%S)] OK: $png" >> "$logfile"
        else
            echo "[$(date +%H:%M:%S)] FAIL: $png" >> "$logfile"
            echo "$png" >> "$failures"
        fi
    ' _ {} "$HOST" "$MODEL" "$FAILURES" "$LOG" < "$PHASE2_PENDING_LIST"
else
    log "Phase 2: nothing to OCR (all pages already have .md)"
fi

# --- Phase 3: merge per-page → per-PDF md -----------------------------------
log "Phase 3: merge per-page md → per-PDF md"
PHASE3_NEW=0
PHASE3_SKIP=0
for pdf in "$INPUT_DIR"/*.pdf; do
    base="${pdf%.pdf}"
    name="$(basename "$base")"
    page_dir="${INPUT_DIR}/${name}"
    output="${INPUT_DIR}/${name}.md"

    [[ -d "$page_dir" ]] || continue
    if [[ -s "$output" ]] && [[ "$RESUME" -eq 0 ]]; then
        PHASE3_SKIP=$((PHASE3_SKIP + 1))
        continue
    fi

    pages=$(find "$page_dir" -name 'page-*.png.md' -type f 2>/dev/null | sort -V)
    if [[ -z "$pages" ]]; then
        # No per-page md yet — skip merge for this PDF
        continue
    fi

    {
        while IFS= read -r pmd; do
            cat "$pmd"
            echo ""
        done <<<"$pages"
    } > "$output"

    if [[ -s "$output" ]]; then
        PHASE3_NEW=$((PHASE3_NEW + 1))
    fi
done
log "Phase 3 done: ${PHASE3_NEW} merged, ${PHASE3_SKIP} skipped"

# --- Failure retry (one round) ----------------------------------------------
if [[ -s "$FAILURES" ]]; then
    log "Retry round: ${PERMANENT} pending"
    cp "$FAILURES" "${FAILURES}.round1"
    : > "$FAILURES"
    while IFS= read -r png; do
        [[ -f "${png}.md" ]] && continue
        if macdoc ocr "$png" --output "${png}.md" --host "$HOST" --model "$MODEL" 2>>"$LOG"; then
            log "RETRY OK: $png"
        else
            log "RETRY FAIL: $png"
            echo "$png" >> "$PERMANENT"
        fi
    done < "${FAILURES}.round1"
fi

# --- Report ------------------------------------------------------------------
log "Session ${SESSION_ID} complete."
log "  Phase 1: ${PHASE1_NEW} split / ${PHASE1_SKIP} skipped"
log "  Phase 2: ${PHASE2_TOTAL} pages OCRed"
log "  Phase 3: ${PHASE3_NEW} merged / ${PHASE3_SKIP} skipped"
if [[ -s "$PERMANENT" ]]; then
    log "  Permanent failures: $(wc -l < "$PERMANENT") (run /batch-ocr-resume)"
    exit 1
fi
exit 0
