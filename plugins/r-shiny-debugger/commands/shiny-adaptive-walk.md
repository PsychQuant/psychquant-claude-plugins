---
description: Self-converging adaptive walker for MP165 dashboard testing — discovers defects via safari-browser + LLM judge, auto-mutates test infra, files real bugs as /idd-issue. Spectra: adaptive-dashboard-test-loop (#653)
argument-hint: <COMPANY> [--budget N] [--max-iter N] [--no-pr]
---

# Shiny Adaptive Walk

Self-converging test-builder loop for MP165 dashboard rendering acceptance. Each iteration:

1. Walks the company dashboard via **safari-browser** (visible to user, real renderer = ground truth)
2. LLM judges each rendered screenshot for defects
3. Bifurcates per defect:
   - **test_infra_gap** → skill auto-mutates `qef_design.yaml` / `contracts.R` / `run_smoke_lite.R`
   - **real_bug** → skill files `/idd-issue` (does NOT touch production code)
4. Runs existing test suite + mechanical gate to confirm no regression
5. Repeats until CONVERGED / PLATEAUED / DIMINISHING

Refs: spectra change `adaptive-dashboard-test-loop` (issue #653) / sister of `/shiny-debug` (interactive debug, single-pass) / MP165 v1.2 Track B (adaptive overlay vs Track A declarative baseline).

## 使用方式

```
/shiny-adaptive-walk QEF_DESIGN                    # default config
/shiny-adaptive-walk QEF_DESIGN --budget 50        # cap LLM calls at 50
/shiny-adaptive-walk QEF_DESIGN --max-iter 3       # cap iterations at 3 (default 5)
/shiny-adaptive-walk QEF_DESIGN --no-pr            # don't open PR after converge
```

Required argument: `<COMPANY>` matching `app_config.yaml` company code (QEF_DESIGN / D_RACING / MAMBA / WISER / kitchenMAMA).

## 核心原則

| Rule | Detail |
|------|--------|
| **Visible discovery** | safari-browser (real macOS Safari) — user can watch each iter. Per principle `08-shiny-testing.md` narrow exception clause for adaptive-walker. |
| **Mechanical regression** | agent-browser (headless Chromium) — confirms mutations don't break existing tests + new contracts catch defects. |
| **Mutation boundary** | Skill CAN edit test infra (`98_test/e2e/**`, `23_deployment/dashboard_presence_gate.R`, `04_utils/fn_debug_mode.R`). Skill MUST NOT touch production code (`10_rshinyapp_components/`, `16_derivations/`, `04_utils/fn_analysis_*.R`, `update_scripts/ETL/`, `update_scripts/DRV/`) → files `/idd-issue` instead. |
| **Atomic per-iter commit** | Each iteration ships as ONE commit `iter-N: <summary> (refs <#issue>)`. If post-mutation tests fail, `git reset --hard HEAD~1` reverts the iter. |
| **LLM budget cap** | `MP165_ADAPTIVE_BUDGET=100` env var (default 100 calls per session). Short-circuit DIMINISHING when exhausted. |
| **Branch isolation** | Skill operates on `idd/<N>-adaptive-test-loop` feature branch from main. NEVER pushes to remote during loop (Phase 6 final action: open PR for human review). |
| **Issue dedup** | Real bugs filed with composite signature `<company>:<module>:<sub_tab>:<defect_class>:<key_phrase>`. Skill `gh issue list --search` before filing — match → comment on existing instead of new issue. |

---

## 執行步驟

### Step 0: Pre-flight checks

```bash
# Required tools
which safari-browser || abort "safari-browser CLI required (macOS only). See $L4_ENT/.../08-shiny-testing.md Live URL section"
which agent-browser  || abort "agent-browser CLI required. npm install -g agent-browser && agent-browser install"
which gh             || abort "gh CLI required"
command -v Rscript   || abort "R + Rscript required"

# Required env
COMPANY="${1:?company required (QEF_DESIGN / D_RACING / MAMBA / WISER / kitchenMAMA)}"
BUDGET="${MP165_ADAPTIVE_BUDGET:-100}"
MAX_ITER="${MP165_MAX_ITER:-5}"
OPEN_PR="${OPEN_PR:-true}"
```

Parse flags:
- `--budget N` → override `MP165_ADAPTIVE_BUDGET` to N
- `--max-iter N` → override `MP165_MAX_ITER` (default 5)
- `--no-pr` → skip auto-PR at end

### Step 1: Working tree + branch setup

```bash
# Must start clean
test -z "$(git status --porcelain)" || abort "uncommitted changes; commit or stash first"

# Determine parent issue for branch name (default #653, can override)
PARENT_ISSUE="${PARENT_ISSUE:-653}"

# Branch: idd/<N>-adaptive-test-loop[-2|-3...]
BASE_BRANCH="idd/${PARENT_ISSUE}-adaptive-test-loop"
BRANCH="$BASE_BRANCH"
suffix=2
while git rev-parse --verify "$BRANCH" >/dev/null 2>&1; do
  BRANCH="${BASE_BRANCH}-${suffix}"
  suffix=$((suffix + 1))
done

git checkout main
git pull origin main
git checkout -b "$BRANCH"
echo "→ Working on branch: $BRANCH"
```

### Step 2: Pre-loop reconnaissance — read existing yaml

```bash
YAML_PATH="shared/global_scripts/98_test/e2e/contracts/$(echo "$COMPANY" | tr '[:upper:]' '[:lower:]').yaml"
test -f "$YAML_PATH" || YAML_NEW=1

# Snapshot pre-state for dedup
PRE_CONTRACTS_HASH=$(test -f "$YAML_PATH" && sha256sum "$YAML_PATH" | cut -d' ' -f1 || echo "missing")
```

If `$YAML_PATH` doesn't exist (e.g., wiser / kitchenmama), skill will CREATE it during first iter with the standard schema header + reserved `# === auto-suggested ===` block.

### Step 3: Iteration loop (max `$MAX_ITER`)

```
ITER=1
LLM_CALLS_USED=0
PREV_DEFECTS_HASH=""

while [ $ITER -le $MAX_ITER ]; do
  echo "═══ Iteration $ITER / $MAX_ITER ═══"
  echo "Budget remaining: $((BUDGET - LLM_CALLS_USED)) / $BUDGET LLM calls"

  if [ $LLM_CALLS_USED -ge $BUDGET ]; then
    VERDICT="DIMINISHING"
    REASON="budget exhausted at iter $ITER"
    break
  fi

  iter_result=$(run_iteration $ITER)

  case "$iter_result" in
    "converged")      VERDICT="CONVERGED"; break ;;
    "plateaued")      VERDICT="PLATEAUED"; break ;;
    "diminishing")    VERDICT="DIMINISHING"; break ;;
    "rollback")       echo "  iter $ITER rolled back due to regression"; ITER=$((ITER + 1)) ;;
    "progress")       ITER=$((ITER + 1)) ;;
  esac
done

if [ -z "$VERDICT" ]; then
  VERDICT="MAX_ITER_REACHED"
fi
```

#### Step 3a: Discovery walk (safari-browser, visible to user)

```bash
discover_defects() {
  # 1. Start Shiny app via nohup
  cd "$COMPANY_DIR"
  pkill -TERM -f "Rscript app.R" 2>/dev/null
  sleep 1
  mkdir -p .shiny-debug
  rm -f .shiny-debug/shiny.log
  SHINY_DEBUG_MODE=TRUE nohup Rscript app.R > .shiny-debug/shiny.log 2>&1 &
  APP_PID=$!

  # 2. Wait for "Listening on" marker
  for i in $(seq 1 60); do
    if grep -q "Listening on" .shiny-debug/shiny.log 2>/dev/null; then break; fi
    sleep 1
  done
  URL=$(grep "Listening on" .shiny-debug/shiny.log | tail -1 | grep -oE "http://[^[:space:]]+")
  URL_SUBSTR=$(echo "$URL" | sed -E 's#https?://##; s#/$##')

  # 3. Open in safari-browser with --url lock (per 08-shiny-testing.md narrow exception)
  safari-browser open "$URL" --url "$URL_SUBSTR"
  sleep 2

  # 4. Login
  safari-browser snapshot -i --url "$URL_SUBSTR" > /tmp/snap_login.txt
  PWD_REF=$(extract_ref_from_snap /tmp/snap_login.txt "textbox.*密碼|textbox.*password")
  SUBMIT_REF=$(extract_ref_from_snap /tmp/snap_login.txt "button.*進入|button.*Login")
  safari-browser fill "${PWD_REF:-@e1}" VIBE --url "$URL_SUBSTR"
  safari-browser click "${SUBMIT_REF:-@e2}" --url "$URL_SUBSTR"
  sleep 3

  # 5. Walk top-level + sub-tabs, screenshot each
  SCREENSHOTS=()
  for tab in "總覽儀表板" "TagPilot" "Marketing Vital-Signs" "BrandEdge" "InsightForge 360" "報告中心"; do
    safari-browser snapshot -i --url "$URL_SUBSTR" > "/tmp/snap_${tab}.txt"
    TAB_REF=$(extract_ref_from_snap "/tmp/snap_${tab}.txt" "link.*${tab}")
    [ -n "$TAB_REF" ] || continue

    safari-browser click "$TAB_REF" --url "$URL_SUBSTR"
    sleep 2.5  # bs4Dash accordion settle

    # Take screenshot for top-level
    safari-browser screenshot "/tmp/walk_iter${ITER}_${tab}.png" --url "$URL_SUBSTR"
    SCREENSHOTS+=("/tmp/walk_iter${ITER}_${tab}.png")

    # Re-snap to find sub-tabs (reuse run_smoke_lite.R::.smoke_extract_sub_tab_refs)
    SUB_REFS=$(R -e "source('shared/global_scripts/98_test/e2e/run_smoke_lite.R'); cat(.smoke_extract_sub_tab_refs(snap_text, '$tab', remaining_tabs))")
    for sub_ref in $SUB_REFS; do
      safari-browser click "$sub_ref" --url "$URL_SUBSTR"
      sleep 1
      safari-browser screenshot "/tmp/walk_iter${ITER}_${tab}_${sub_ref}.png" --url "$URL_SUBSTR"
      SCREENSHOTS+=("/tmp/walk_iter${ITER}_${tab}_${sub_ref}.png")
    done
  done

  kill -TERM "$APP_PID" 2>/dev/null
}
```

#### Step 3b: LLM judge classification (per screenshot)

For each screenshot in `${SCREENSHOTS[@]}`, classify defects using hybrid rule + LLM:

**Hard rules (deterministic, no LLM call needed)**:
- Text content contains `Error:` / `[object Object]` / `<NA>` / `NaN` → `real_bug` (production-visible error)
- KPI card value is `--` / `-` / `N/A` → `real_bug` (data path broken)
- Title contains TitleCase English (4+ chars, not in DT controls whitelist) → `real_bug` (i18n regression)
- Sub-tab visible in safari but absent from `$YAML_PATH` contracts → `test_infra_gap`

**LLM judgment (for ambiguous cases)**:

```
Prompt template (for each screenshot):

  You are evaluating a Shiny dashboard screenshot for defects.

  Context:
  - Company: $COMPANY
  - Tab: $TAB_NAME / $SUB_TAB
  - Product line: $PRODUCT_LINE
  - Reference healthy state: $HEALTHY_REF_SCREENSHOT (when available)

  Classify each visible defect:
  - real_bug: user-visible error, missing data, broken render
  - test_infra_gap: render is OK but test contracts don't cover this element
  - acceptable: empty state with explanatory message (e.g., "請先選擇產品線")

  Return JSON: { "defects": [{"signature": "...", "class": "real_bug|test_infra_gap|acceptable", "evidence": "..." }] }
```

Increment `LLM_CALLS_USED += 1` per LLM invocation. Use Claude Haiku 4.5 (per CLAUDE.md performance rule: lightweight + high-frequency).

#### Step 3c: Mutation bifurcation

```bash
for defect in $defects_json; do
  signature=$(echo "$defect" | jq -r .signature)
  class=$(echo "$defect" | jq -r .class)
  evidence=$(echo "$defect" | jq -r .evidence)

  case "$class" in
    "real_bug")
      handle_real_bug "$signature" "$evidence"
      ;;
    "test_infra_gap")
      handle_test_infra_gap "$signature" "$evidence"
      ;;
    "acceptable")
      # No action; just log
      echo "  $signature: acceptable empty state, no defect"
      ;;
  esac
done
```

##### `handle_real_bug` — file `/idd-issue` with dedup

```bash
handle_real_bug() {
  local sig="$1"  # e.g., "QEF_DESIGN:insightforge:market_track:error_object:coefficient"
  local evidence="$2"

  # Dedup: search existing issues
  existing=$(gh issue list --repo kiki830621/ai_martech_global_scripts \
    --state open --search "in:body \"$sig\"" --json number -q '.[0].number')

  if [ -n "$existing" ]; then
    # Re-observed during this run; comment instead of new issue
    gh issue comment "$existing" --repo kiki830621/ai_martech_global_scripts \
      --body "Re-observed during \`/shiny-adaptive-walk\` iter $ITER ($(date -u +%Y-%m-%d)). Signature: \`$sig\`"
    FILED_ISSUES+=("$existing (re-observed)")
  else
    # New issue
    new_url=$(gh issue create --repo kiki830621/ai_martech_global_scripts \
      --title "[bug][$COMPANY] $(echo "$evidence" | head -1)" \
      --label "bug,confidence:confirmed,priority:P2,company:$COMPANY" \
      --body "$(cat <<EOF
## Problem

Discovered during \`/shiny-adaptive-walk $COMPANY\` iteration $ITER.

**Defect signature**: \`$sig\`

**Evidence**: $evidence

## Source

Surfaced during \`/shiny-adaptive-walk\` adaptive testing loop (refs spectra change \`adaptive-dashboard-test-loop\`, parent issue #$PARENT_ISSUE). Per IC_R011 commercial low-bar filing — skill files this rather than fixing because production code is OUTSIDE mutation boundary.

## Files NOT touched by skill

- \`shared/global_scripts/10_rshinyapp_components/**\`
- \`shared/global_scripts/16_derivations/**\`
- \`shared/global_scripts/04_utils/fn_analysis_*.R\`
- \`shared/update_scripts/ETL/**\`
- \`shared/update_scripts/DRV/**\`

Bug fix is human responsibility.
EOF
)")
    FILED_ISSUES+=("$new_url")
  fi
}
```

##### `handle_test_infra_gap` — mutate test framework

```bash
handle_test_infra_gap() {
  local sig="$1"
  local evidence="$2"

  # Parse signature to identify which file + what mutation
  module=$(echo "$sig" | cut -d: -f2)
  sub_tab=$(echo "$sig" | cut -d: -f3)
  gap_type=$(echo "$sig" | cut -d: -f4)

  case "$gap_type" in
    "missing_contract")
      # Append to # === auto-suggested === block in yaml
      append_yaml_contract "$YAML_PATH" "$module" "$sub_tab" "$evidence"
      ;;
    "weak_primitive")
      # New primitive or strengthen existing in contracts.R
      add_contracts_primitive "$evidence"
      ;;
    "walker_miss")
      # Strengthen run_smoke_lite.R walker logic
      strengthen_walker "$evidence"
      ;;
    *)
      log_warn "  Unknown gap_type '$gap_type', skipping mutation"
      ;;
  esac
}
```

Auto-suggested yaml append pattern:

```yaml
# === auto-suggested by adaptive walker (2026-MM-DD iter N) ===
modules:
  insightforge:
    enabled: true
    sub_tabs:
      market_track:
        active_product_lines: [hsg, sfg, ...]  # detected from app config
        contracts:
          - selector: "insightforge_market-kpi_track_champion"
            assertion: "no_error_placeholder"
            severity: critical
          - selector: "insightforge_market-table_track_analysis"
            assertion: "no_error_text"
            severity: critical
```

Skill **must** preserve hand-maintained sections of yaml above the `# === auto-suggested ===` marker. Diff-aware: walker only modifies content AFTER the marker.

#### Step 3d: Per-iter safety gate

```bash
run_safety_gate() {
  # 1. Existing test suite
  echo "  Running existing test suite..."
  if ! NOT_CRAN=true Rscript -e "testthat::test_dir('shared/global_scripts/98_test/e2e', reporter='summary')" > /tmp/test_dir.log 2>&1; then
    echo "  ✗ Existing tests broke — iter $ITER will rollback"
    return 1
  fi

  # 2. Mechanical gate against current company
  echo "  Running mechanical gate..."
  if ! Rscript shared/global_scripts/23_deployment/dashboard_presence_gate.R \
    --company "$COMPANY" \
    --app-dir "$COMPANY_DIR" \
    --allow-warnings \
    --password VIBE \
    --timeout 90 > /tmp/gate.log 2>&1; then
    echo "  ✗ Mechanical gate failed — iter $ITER will rollback"
    return 1
  fi

  return 0
}

# Commit + safety check + rollback if needed
if [ -n "$(git status --porcelain)" ]; then
  git add -A
  git commit -m "iter-$ITER: $ITER_SUMMARY (refs #$PARENT_ISSUE)" 2>&1

  if ! run_safety_gate; then
    git reset --hard HEAD~1
    echo "  ROLLBACK: iter $ITER mutations reverted"
    iter_result="rollback"
  else
    iter_result="progress"
  fi
fi
```

#### Step 3e: Convergence detection

```bash
# Defect signatures this iter
CURRENT_DEFECTS_HASH=$(echo "${DEFECT_SIGNATURES[@]}" | sort | sha256sum | cut -d' ' -f1)

# Real-bug ratio
REAL_BUG_RATIO=$(echo "scale=2; ${#FILED_ISSUES[@]} / (${#DEFECT_SIGNATURES[@]} + 0.001)" | bc)

if [ ${#DEFECT_SIGNATURES[@]} -eq 0 ]; then
  iter_result="converged"
  REASON="0 defects this iter, mutations from iter $((ITER-1)) all PASS regression"
elif [ "$CURRENT_DEFECTS_HASH" = "$PREV_DEFECTS_HASH" ]; then
  iter_result="plateaued"
  REASON="same defect set 2 consecutive iters; user intervention needed"
elif (( $(echo "$REAL_BUG_RATIO > 0.8" | bc -l) )); then
  iter_result="diminishing"
  REASON="${#FILED_ISSUES[@]} real bugs filed vs only ${#MUTATIONS_THIS_ITER[@]} test gaps — test infra converged, await bug fixes"
fi

PREV_DEFECTS_HASH="$CURRENT_DEFECTS_HASH"
```

### Step 4: PLATEAUED handling — AskUserQuestion

When `VERDICT="PLATEAUED"`, surface to user before exit:

```
AskUserQuestion:
  question: "Loop plateaued at iter $ITER on $defect_count same defects 2 iters. How to handle?"
  options:
    - "force-converge: accept current state, exit"
    - "bulk-file: file remaining defects as omnibus issue"
    - "abort: leave branch as-is, user investigates manually"
```

### Step 5: Final report

```
══════════════════════════════════════════
/shiny-adaptive-walk $COMPANY — $VERDICT
══════════════════════════════════════════

Iterations:    $ITER / $MAX_ITER
LLM calls:     $LLM_CALLS_USED / $BUDGET
Branch:        $BRANCH
Walk time:     ${ELAPSED}s total

Test framework mutations:
$(printf '  - %s\n' "${MUTATIONS[@]}")

Real bugs filed (per IC_R011 commercial low-bar):
$(printf '  - %s\n' "${FILED_ISSUES[@]}")

Rollbacks:     $ROLLBACK_COUNT
Reason:        $REASON

Next: review git diff main..$BRANCH + open PR for human review
```

### Step 6: Open PR (if `--no-pr` not specified)

```bash
if [ "$OPEN_PR" = "true" ]; then
  git push -u origin "$BRANCH"
  gh pr create --repo kiki830621/ai_martech_global_scripts \
    --base main --head "$BRANCH" \
    --title "[adaptive-test] $COMPANY iter $ITER $VERDICT (refs #$PARENT_ISSUE)" \
    --body "$(cat <<EOF
Refs #$PARENT_ISSUE — \`/shiny-adaptive-walk $COMPANY\` run

## Convergence
- Verdict: **$VERDICT**
- Iterations: $ITER / $MAX_ITER
- LLM budget: $LLM_CALLS_USED / $BUDGET

## Mutations
$(printf '- %s\n' "${MUTATIONS[@]}")

## Real bugs filed
$(printf '- %s\n' "${FILED_ISSUES[@]}")

## Cross-co (IC_P002)
Single-co run for $COMPANY. Verified: trailer requires running on 5 cos (per parent spectra change adaptive-dashboard-test-loop Phase 5).

🤖 Generated by /shiny-adaptive-walk
EOF
)"
fi
```

---

## Mutation boundary spec (CRITICAL)

### Mutable zone (skill CAN edit)

| Path glob | Why |
|-----------|-----|
| `shared/global_scripts/98_test/e2e/contracts/*.yaml` | Auto-emit contracts to `# === auto-suggested ===` block |
| `shared/global_scripts/98_test/e2e/contracts/contracts.R` | Add new primitives when existing 5 + 3 (Phase 1) insufficient |
| `shared/global_scripts/98_test/e2e/run_smoke_lite.R` | Strengthen walker when navigation gaps surface |
| `shared/global_scripts/98_test/e2e/test-*.R` | Add new regression test files for discovered defects |
| `shared/global_scripts/23_deployment/dashboard_presence_gate.R` | Add new gate logic / flags |
| `shared/global_scripts/04_utils/fn_debug_mode.R` | Strengthen NULL detection or add new debug-mode signals |

### Immutable zone (skill MUST file `/idd-issue` instead)

| Path glob | Reason for immutability |
|-----------|-------------------------|
| `shared/global_scripts/10_rshinyapp_components/**` | UI component source code — code-under-test |
| `shared/global_scripts/16_derivations/**` | Business logic derivations |
| `shared/global_scripts/04_utils/fn_analysis_*.R` | Analysis functions |
| `shared/update_scripts/ETL/**` | ETL pipeline scripts |
| `shared/update_scripts/DRV/**` | Derivation execution scripts |
| `shared/global_scripts/01_db/**` | Database connection / DDL |
| Any `.qmd` principle file | Principle changes require explicit human decision |

**Pre-mutation check**: before any file edit, verify path is in mutable zone via hard glob match. Refuse mutation if file is in immutable zone — file issue instead.

---

## Convergence model (mirrors `/glue-bridge` MP102 v1.3)

| Verdict | Trigger | Action |
|---------|---------|--------|
| **CONVERGED** | 0 new defects this iter AND previous iter's mutations all PASS regression | Exit success. Test infra has full coverage of currently-observable defects. |
| **PLATEAUED** | Same defect signature set 2 consecutive iters | AskUserQuestion 3-option (force-converge / bulk-file / abort) |
| **DIMINISHING** | >80% real_bug classifications this iter (test gaps mostly resolved, remaining defects are code bugs awaiting human fix) | Exit success with list of filed bugs. Test infra is converged for what's testable. |
| **MAX_ITER_REACHED** | Hit `$MAX_ITER` without other terminal state | Exit partial. User can re-invoke to continue. |
| **BUDGET_EXHAUSTED** | `LLM_CALLS_USED >= BUDGET` mid-iter | Short-circuit DIMINISHING. User can re-invoke with `--budget` override. |

---

## Examples

### Today's #653 F1-F5 retroactive walkthrough

If `/shiny-adaptive-walk QEF_DESIGN` were run against current main (assuming Phase 1+2 already merged), expected behavior:

**Iter 1**:
- Discovery walks 6 top + 8 sub-tabs (Phase 2 walker)
- LLM judge classifies:
  - F1 InsightForge 市場賽道 `Error: [object Object]` → **real_bug** (hard rule)
  - F2 InsightForge 精準行銷 `--` KPI → **real_bug** (hard rule)
  - F3 InsightForge 時間分析 `0/0/--/0` → **real_bug** (LLM judges as broken data path)
  - F4 BrandEdge KFE `Key Factor Evaluation` hardcoded English → **real_bug** (hard rule)
  - F5 BrandEdge 理想點分析 hardcoded English subtitle → **real_bug** (hard rule)
  - meta: InsightForge sub-tabs absent from `qef_design.yaml` → **test_infra_gap**

Skill actions:
- File `/idd-issue` for F1+F2+F3 (combined or separate, dedup against #655 if exists)
- File `/idd-issue` for F4+F5 (dedup against #656)
- Mutate `qef_design.yaml` — append InsightForge module to `# === auto-suggested ===` block with contracts using `assert_no_error_text` + `assert_kpi_no_error_placeholder`
- Commit `iter-1: file 5 bugs + add InsightForge contracts (refs #653)`
- Run safety gate — confirm new contracts catch F1-F5 + existing tests pass

**Iter 2**:
- Discovery walks again
- Same F1-F5 defects appear (no code fix yet)
- LLM judge classifies all as **real_bug** — but dedup finds existing issues, skip filing
- No new test_infra_gap (yaml already has contracts)
- DIMINISHING verdict (100% real_bug, no new mutations)

**Final report**: CONVERGED on test infra, 5 bugs filed awaiting human fix.

### Empty company (already-covered)

If `/shiny-adaptive-walk D_RACING` runs and walker finds no new defects:

**Iter 1**:
- Walks 6 tabs + sub-tabs
- LLM judge: 0 defects across all screenshots
- No mutations needed, no bugs filed
- CONVERGED at iter 1

Final yaml `# === auto-suggested ===` block contains `# (none — already covered)`.

---

## Anti-patterns

| Don't | Do |
|-------|----|
| Edit production code (UI components, business logic) | File `/idd-issue` — skill respects bug ownership boundary |
| Use `agent-browser` for discovery walk | Use `safari-browser` (real renderer, visible to user, principle exception) |
| Skip per-iter regression gate | ALWAYS run test_dir + mechanical gate; auto-rollback on failure |
| File duplicate bug issues | Compute composite signature + `gh issue list --search` before filing |
| Run on dirty working tree | Refuse start with uncommitted changes (per Step 1) |
| Auto-merge PR | NEVER push directly to main; only feature branch + PR for human review |
| Ignore budget | Short-circuit DIMINISHING when `LLM_CALLS_USED >= BUDGET` |

---

## Configuration reference

| Env var | Default | Effect |
|---------|---------|--------|
| `MP165_ADAPTIVE_BUDGET` | 100 | Max LLM judge calls per skill session |
| `MP165_MAX_ITER` | 5 | Max iterations before MAX_ITER_REACHED |
| `PARENT_ISSUE` | 653 | Issue # used in branch name + commit refs |
| `OPEN_PR` | true | If "false", skill doesn't auto-create PR at end |

### Flags

| Flag | Effect |
|------|--------|
| `--budget N` | Override `MP165_ADAPTIVE_BUDGET` to N |
| `--max-iter N` | Override `MP165_MAX_ITER` to N |
| `--no-pr` | Skip auto-PR (sets `OPEN_PR=false`) |

---

## Cross-references

- **Sister skill**: `/shiny-debug` — single-pass interactive functional debug (this skill = self-converging adaptive loop)
- **Parent spectra change**: `adaptive-dashboard-test-loop` in `kiki830621/ai_martech_global_scripts` repo (`openspec/changes/adaptive-dashboard-test-loop/`)
- **Parent issue**: kiki830621/ai_martech_global_scripts#653
- **MP165 v1.2 amendment**: codifies dual-track architecture (Track A declarative `qef_design.yaml` baseline + Track B adaptive walker overlay)
- **Prior art**: `/glue-bridge` MP102 v1.3 self-converging review pattern (CONVERGED / PLATEAUED / DIMINISHING verdicts)
- **Principle exception**: `00_principles/.claude/rules/08-shiny-testing.md` narrow exception clause permits safari-browser on local for adaptive-walker discovery (real-renderer ground truth)
- **Bug filing discipline**: IC_R011 commercial low-bar filing

---

## Troubleshooting

### safari-browser missing or wrong version

```bash
safari-browser --version
# If missing: not installed (macOS only). agent-browser is fallback for local dev,
# but skill REQUIRES safari-browser for real-renderer ground truth visibility.
```

### Branch collision

If `idd/<N>-adaptive-test-loop` already exists, skill auto-suffixes to `-2`, `-3`, etc. (per Step 1).

### LLM judge returns inconsistent classification

Skill caches LLM responses per screenshot (content hash). Re-running iter N with same screenshots reuses cache. To invalidate: `rm -rf /tmp/adaptive_walk_cache_*`.

### git status not clean after iter

If `git status` shows untracked files (e.g., new test fixture in `98_test/e2e/test-foo-fixture-iter1.png`), those are skill artifacts. Commit them as part of the iter's mutations OR add to `.gitignore`. Skill should NEVER leave dirty state mid-loop — debug if encountered.
