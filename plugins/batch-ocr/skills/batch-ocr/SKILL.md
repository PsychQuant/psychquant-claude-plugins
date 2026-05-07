---
name: batch-ocr
description: |
  Batch OCR pipeline orchestrator wrapping macdoc — PDF→PNG split, parallel OCR with
  SSH tunnel health check + auto-retry, per-page → per-PDF markdown merge, idempotent
  resume from interruption. Trigger when user says "batch OCR", "OCR all the PDFs in
  this folder", "do OCR on 50+ PDFs", "transcript exam OCR", or invokes /batch-ocr.
argument-hint: <directory-of-pdfs> [--parallel N] [--host kyle] [--model glm-ocr]
allowed-tools: Bash, Read, Write, Edit, Grep, Glob, TaskCreate, TaskUpdate, TaskList
---

# batch-ocr — Folder-level OCR pipeline

Wraps the boilerplate every "OCR a folder of PDFs" task otherwise re-derives. macdoc CLI handles single-file OCR; this skill orchestrates the surrounding pipeline.

## Why this skill exists

實戰: 77 個轉學考 PDF batch OCR 任務累積出近 100 行 shell pipeline (SSH tunnel health check, PDF→PNG split, xargs parallel, per-page merge, retry on failure, idempotent resume, progress tracking). 每次類似任務都重刻一次。本 plugin package 這個 pipeline,把它變成 single-command workflow。

## Pipeline 三階段

```
PDFs/ (input)
  │
  ▼  Phase 1: split (pdftoppm -r DPI)
PDFs/{name}/page-1.png, page-2.png, ...
  │
  ▼  Phase 2: parallel OCR (xargs -P N | macdoc ocr)
PDFs/{name}/page-1.md, page-2.md, ...
  │
  ▼  Phase 3: merge (cat per-page → per-PDF)
PDFs/{name}.md
```

## Step 0: Bootstrap Stage Task List(強制)

```
TaskCreate(name="ensure_tunnel",     description="Phase 0: SSH tunnel 到遠端 Ollama 建立/檢查 (per scripts/ensure-tunnel.sh)")
TaskCreate(name="phase1_split",      description="Phase 1: pdftoppm 拆 PDFs/ 下每個 *.pdf 為 *.png 子目錄")
TaskCreate(name="phase2_ocr",        description="Phase 2: xargs -P N | macdoc ocr 並行 OCR 每個 .png → .md")
TaskCreate(name="phase3_merge",      description="Phase 3: 每個 PDF 的 per-page md → per-PDF md (cat 合併)")
TaskCreate(name="report",            description="Step 4: 印 success/failure/skipped 統計 + 引導 /batch-ocr-status / /batch-ocr-resume 後續")
```

完成每一步立即 `TaskUpdate → completed`。**靜默完成 = 違規**。

## Configuration (config-style frontmatter or CLI flags)

| Field | Default | Source priority |
|-------|---------|-----------------|
| `host` | `localhost:11500` | CLI `--host` > `.claude/.batch-ocr/config.md` > default |
| `model` | `glm-ocr` | CLI `--model` > config > default |
| `dpi` | `200` | CLI `--dpi` > config > default |
| `parallel` | `4` | CLI `--parallel` > config > default |
| `remote_host` | `kyle` | CLI `--remote-host` > config > default (用於 SSH tunnel) |
| `tunnel_port_local` | `11500` | config > default |
| `tunnel_port_remote` | `11434` | config > default (Ollama default port) |

`.claude/.batch-ocr/config.md` 範例:

```yaml
---
host: localhost:11500
model: glm-ocr
dpi: 200
parallel: 4
remote_host: kyle
---
```

## Idempotency / resume rules

- 若 final `<dir>/<name>.md` 存在且非空 → skip 整個 PDF
- 若 per-page `<dir>/<name>/page-N.md` 存在 → skip 該頁 OCR
- `--resume` flag 強制只跑沒對應 `.md` 的 `.png`(失敗重跑)
- 結構化 log 寫入 `.batch-ocr/<session-id>/log` (session-id = ISO timestamp)

## Phase 1: PDF → PNG split

```bash
for pdf in "${INPUT_DIR}"/*.pdf; do
    base="${pdf%.pdf}"
    name="$(basename "$base")"
    page_dir="${INPUT_DIR}/${name}"

    # Skip if final md already done
    [ -s "${INPUT_DIR}/${name}.md" ] && continue

    mkdir -p "$page_dir"
    pdftoppm -r "${DPI:-200}" -png "$pdf" "${page_dir}/page"
done
```

## Phase 2: Parallel OCR

```bash
# Find all PNGs that don't yet have a corresponding .md
find "${INPUT_DIR}" -name "page-*.png" | while read png; do
    [ -f "${png}.md" ] && continue
    echo "$png"
done | xargs -P "${PARALLEL:-4}" -I{} bash -c '
    macdoc ocr "$1" --output "$1.md" --host "$2" --model "$3" \
        || { echo "FAIL: $1" >> "$4/failures.log"; }
' _ {} "${HOST}" "${MODEL}" "${SESSION_DIR}"
```

當 `macdoc ocr --parallel N` (PsychQuant/macdoc#73) 落地後,此段可改為單一 `macdoc ocr-batch ... --parallel N`,移除 xargs。

## Phase 3: Merge per-page → per-PDF

```bash
for pdf in "${INPUT_DIR}"/*.pdf; do
    base="${pdf%.pdf}"
    name="$(basename "$base")"
    page_dir="${INPUT_DIR}/${name}"
    output="${INPUT_DIR}/${name}.md"

    [ -d "$page_dir" ] || continue
    [ -s "$output" ] && continue  # idempotent: skip if already merged

    # Sort per-page md by page number (page-1.md, page-10.md, ... 數字 sort)
    find "$page_dir" -name 'page-*.png.md' | sort -V | while read pmd; do
        cat "$pmd"
        echo ""
    done > "$output"
done
```

## SSH tunnel health check

由 `scripts/ensure-tunnel.sh` 處理。每次 OCR 前 health check,失敗自動 reconnect:

```bash
ensure_tunnel() {
    local local_port="$1" remote_host="$2" remote_port="$3"
    if curl -s --max-time 3 "http://localhost:${local_port}/api/tags" >/dev/null 2>&1; then
        return 0
    fi
    # Kill any stale ssh listening on local_port
    lsof -ti:"${local_port}" 2>/dev/null | xargs -r kill 2>/dev/null
    ssh -fN -L "${local_port}:localhost:${remote_port}" "${remote_host}"
    sleep 2
    curl -s --max-time 3 "http://localhost:${local_port}/api/tags" >/dev/null 2>&1
}
```

## Failure retry

第一輪 OCR 跑完後,看 `${SESSION_DIR}/failures.log`:
- 若有 failure → 自動跑第二輪只處理 failure 清單
- 第二輪仍失敗 → 寫入 `${SESSION_DIR}/permanent_failures.log`,user 可後續用 `/batch-ocr-resume` 手動重試

## Skill 自身的 entry point

User invokes `/batch-ocr <dir>` → command 呼叫 `scripts/batch-ocr.sh`,後者引用本 SKILL.md 的 logic。

## Distinct from macdoc skill

| | macdoc skill | batch-ocr skill |
|---|---|---|
| Granularity | Single-file OCR (`macdoc ocr file.pdf`) | Folder-level pipeline |
| SSH tunnel | docs only | active health-check + auto-reconnect |
| Parallelism | future `--parallel` flag | current `xargs -P` wrapper |
| Resume | manual | built-in idempotent rules |
| Progress | none | structured log + status command |

互補,batch-ocr 呼叫 macdoc 作為單封 OCR 後端。

## Migration path

當 `macdoc ocr --parallel N` 落地 (PsychQuant/macdoc#73):
- Phase 2 從 `xargs -P` 改成 `macdoc ocr-batch ... --parallel N`
- 失敗重試由 macdoc CLI 內建處理
- batch-ocr 仍負責 PDF→PNG / merge / resume / status

## Related

- `psychquant-claude-plugins#5` — macdoc skill 並行章節 (相互引用)
- `PsychQuant/macdoc#73` — CLI `--parallel` 支援 (本 plugin 將優先使用)
