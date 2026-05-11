---
name: doc-synth
description: |
  Semantic synthesis between 2+ document versions (not git-style line merge).
  Input: N source docs (.tex / .md / .ipynb / .docx). User specifies dimension-level
  take/leave decisions (e.g., "structure from A, methodology section from B, conclusion
  from C"). Plugin produces synthesized output with provenance tracking.
  Use when: combining advantages from multiple drafts, integrating reviewer suggestions
  with original draft, merging student work + teacher reference into best-of-both.
  Differs from: git merge (mechanical line-level), revise (single source improved),
  ensemble (output averaging — this picks dimensions, not averages outputs).
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Grep
  - Glob
  - AskUserQuestion
  - TaskCreate
  - TaskUpdate
---

# doc-synth — Semantic Synthesis Between Document Versions

## Purpose

把 N 個 document version 的優點按維度 (section / cell / dimension) 整合進一個新版本，**不是 line-level git merge，是 semantic blend**。

典型 use case：
- ASSG / paper revision：W-tex 的 self-aware caveats + Gong reference 的 procedural strictness → 新版本各取所長
- ML notebook：W-Py 的 Part 0-4 rubric structure + Gong 的 Pipeline + ColumnTransformer engineering → final.ipynb
- 報告整合：兩位審稿者意見 + 原 draft → revised draft
- Lecture handout：去年版 + 今年新加章節 → 完整版

**不適用**：
- 同一份文件版本演進（用 `git diff` + `Edit` 即可）
- 完全重寫（沒有「保留 N 個 source 的 dimension」概念，直接用 `perspective-writer` 之類）
- Pure ensemble（model averaging 不挑 dimension — 用其他工具）

## Vocabulary

| 詞 | 意義 |
|---|---|
| **source** | 輸入的某個 document version（A / B / C / ...） |
| **dimension** | 可獨立挑選的內容單位（.tex section / .md heading / .ipynb cell / .docx section） |
| **take decision** | per-dimension 決定該維度從哪個 source 來（A only / B only / hybrid / custom） |
| **provenance** | 輸出 doc 內 metadata，記錄每個 dimension 從哪個 source 來 |
| **synthesis output** | 整合後的新 doc，附 provenance |

## Execution Steps

### Step 0: Bootstrap Stage Task List（強制）

```
TaskCreate(name="parse_arguments", description="解析 N 個 source path + 目標輸出格式 + 任何 dimension hint")
TaskCreate(name="validate_sources", description="檢查 N ≥ 2 個 source 存在 + 格式一致（.tex / .md / .ipynb / .docx）")
TaskCreate(name="extract_dimensions", description="依格式 dispatch extractor 抽 dimension list（.tex \\section / .md headings / .ipynb cells / .docx sections via che-word-mcp）")
TaskCreate(name="show_comparison_table", description="per-dimension 印 N 個 source side-by-side preview，user 看完才決定")
TaskCreate(name="gather_take_decisions", description="AskUserQuestion 或 batch mode：每個 dimension take A / B / hybrid / custom")
TaskCreate(name="synthesize_output", description="按 take decisions assemble 輸出 doc，每個 dimension 加 provenance comment")
TaskCreate(name="validate_output", description="格式驗證（.tex 編譯 / .ipynb JSON valid / .md render check）")
TaskCreate(name="write_provenance_log", description="輸出 sidecar `<output>.synth.json` 記錄完整 take decision log")
```

完成每一步立即 `TaskUpdate → completed`。**靜默完成 = 違規**。

### Step 1: Parse Arguments

支援的呼叫形式：

```
/docflow:doc-synth                                    # interactive，問所有參數
/docflow:doc-synth A.tex B.tex                        # 2 source，輸出格式自動偵測
/docflow:doc-synth A.tex B.tex C.tex --out merged.tex # 3 source 明確輸出
/docflow:doc-synth A.ipynb B.ipynb --plan synth.json  # batch mode 讀預先寫好的 take decisions
```

### Step 2: Validate Sources

```bash
# Check N ≥ 2
[ "$N_SOURCES" -ge 2 ] || abort "doc-synth requires ≥ 2 source documents"

# Check format consistency
EXTS=$(echo "$SOURCES" | xargs -n1 basename | sed 's/.*\.//' | sort -u)
[ "$(echo "$EXTS" | wc -l)" -eq 1 ] || abort "All sources must be same format (got: $EXTS)"

# Check files exist
for s in $SOURCES; do [ -f "$s" ] || abort "Source not found: $s"; done
```

### Step 3: Extract Dimensions（per-format dispatch）

| Format | Dimension definition | Extractor |
|---|---|---|
| `.tex` | `\section` / `\subsection` 之間的 chunk | regex on `\\(sub)*section\\{[^}]+\\}` |
| `.md`  | `## H2` / `### H3` 之間的 chunk | regex on `^#+\s+(.+)$` |
| `.ipynb` | individual cells（markdown + code） | parse JSON `cells[]` |
| `.docx` | `Heading 1` / `Heading 2` 之間的 chunk | `mcp__plugin_che-word-mcp_word__get_all_sections` |

每個 source 抽完後得到 dimension list:

```python
{
  "A.tex": [
    {"id": "section:Introduction", "title": "Introduction", "content": "..."},
    {"id": "section:Method", "title": "Method", "content": "..."},
    ...
  ],
  "B.tex": [
    {"id": "section:Introduction", "title": "Introduction", "content": "..."},
    ...
  ]
}
```

**Dimension matching**：
- Identical title (case-insensitive) → match
- Similar title (Levenshtein < 3) → ask user to confirm
- Unique to one source → flag as "source-only", user decide keep/drop

### Step 4: Show Comparison Table

對每個 matched dimension 印 side-by-side preview：

```
Dimension: "Method"
======================================================
[A.tex]                          | [B.tex]
------------------------------------------------------
We estimate FE using plm,        | We compare Pooled, RE,
clustering SE on individual...   | FE, FD using plm with
                                 | cluster-robust SE (HC0)...
======================================================
```

User 看完才決定 take。

### Step 5: Gather Take Decisions

對每個 dimension，AskUserQuestion 四選一（或 batch mode 從 plan JSON 讀）：

| Option | 行為 |
|---|---|
| `take A` | 完全用 A 的內容 |
| `take B` | 完全用 B 的內容 |
| `hybrid` | 進 sub-flow：user 指定怎麼 blend（A 主體 + B 補一段 / 兩邊各取一半 / etc） |
| `custom` | user 手寫該 dimension 內容（會 spawn `Write` flow） |
| `skip` | drop 這個 dimension（不進 output） |

把所有 decisions 累積成 plan JSON：

```json
{
  "version": "1.0",
  "created": "2026-05-12T...",
  "sources": ["A.tex", "B.tex"],
  "output": "merged.tex",
  "decisions": [
    {"dimension": "Introduction", "take": "A", "reason": "A 的 framing 較緊湊"},
    {"dimension": "Method", "take": "B", "reason": "B 完整 Pooled/RE/FE/FD"},
    {"dimension": "Discussion", "take": "hybrid", "hybrid_spec": "A 段 1+2 + B 段 3-4 + A 段 5"},
    ...
  ]
}
```

### Step 6: Synthesize Output

依 plan assemble 輸出 doc。每個 dimension 在 output 前加 provenance comment：

```tex
% [docflow:doc-synth provenance]
% dimension: Method
% source: B.tex
% take: full
% timestamp: 2026-05-12T...
\section*{Method}
...
```

`.ipynb` 用 cell metadata（不入內容）：

```json
{
  "cell_type": "markdown",
  "metadata": {
    "docflow_synth": {
      "dimension": "Method",
      "source": "B.ipynb",
      "take": "full"
    }
  },
  "source": [...]
}
```

### Step 7: Validate Output

| Format | Validation |
|---|---|
| `.tex` | 試跑 `xelatex -interaction=nonstopmode`，看有沒有 fatal error |
| `.md`  | render check（用 `cmark` 或 `pandoc -o /dev/null`）|
| `.ipynb` | JSON parse + `jupyter nbconvert --to notebook --execute --inplace --dry-run`（如果有 kernel）|
| `.docx` | che-word-mcp `open_document` + `get_document_info`，看 structure intact |

驗證失敗 → 不 abort，把 error log 寫進 `.synth.json`，user 可手動修。

### Step 8: Write Provenance Sidecar

輸出 `<output_name>.synth.json` 完整記錄：

- Sources（path + sha256）
- Output（path + sha256）
- Decisions（per-dimension take + reason）
- Validation result
- Timestamp + docflow version

未來要 audit「為什麼 merged.tex 的 Method 段是這樣？」直接看 `.synth.json` → 看到「take=B, source=B.tex」就知道。

## Edge Cases

### N = 1（只 1 個 source）
Refuse — 用 `Edit` 或 `perspective-writer` 之類 single-source 工具，doc-synth 是 multi-source。

### Sources 格式不一致
Refuse — 例如 `A.tex` 跟 `B.ipynb` 沒有 well-defined dimension matching。先用 `pandoc` 等 convert 到同格式再來。

### Dimension 完全 disjoint（無 matching）
Warn + 全列 source-only，user 決定 keep/drop 順序拼起來。

### `.docx` 沒有 heading structure
Fall back 到段落層 split（每 N 段一個 dimension），但提醒 user 結構粗略 — 建議先在 Word 內加 heading style。

### `.ipynb` cell 順序不同
Use cell metadata `id` 而非 index 配對；若兩邊都沒 ID（古早 ipynb），用 cell content hash 配對。

## TODO（v1.0 ship 後）

- [ ] **Batch plan mode**：predefined plan JSON 跳過 interactive
- [ ] **3+ source merge**：當前流程支援 2，3+ 需要決定 take 用 winner-takes-all 還是 majority vote
- [ ] **Hybrid spec DSL**：當前 hybrid 是 free-form text，未來可寫成 `A[1-2] + B[3-4] + A[5]` DSL
- [ ] **Round-trip**：merged doc 改了之後能 propagate 回 sources（類似 git rebase backwards）
- [ ] **Multi-language sync**：merge 中英版時保持兩邊對齊
- [ ] **Diff visualization**：merge 前印 unified diff（git-style）讓 user 看 dimension-level 改動

## Related skills（future docflow plugin expansion）

| Skill | 用途 | 對應本 session 經驗 |
|---|---|---|
| `doc-compare` | 兩版本 N 維度 side-by-side comparison.md 自動產出 | ASSG3 / ASSG4 / ML HW2 comparison.md × 3 |
| `doc-verdict` | N 版本 per-question master_verdict.md 表格產出 | ASSG3 master_verdict.md |
| `doc-multiimpl` | 強制 N alternative 都跑完整 implementation 再 commit | #13 IDD 升級 + #15 ASSG3 dogfood |
| `doc-synth`（本 skill） | semantic merge 整合多 source 優點 | ML HW2 #14 hypothetical final_v2 |

## References

- 設計起源：kiki830621/2026-winston session 對話（ASSG3 retrospective + ML HW2 #14 won't-fix + 「merge vs synthesis vs revision」術語討論）
- 對應 IDD pattern：`#13` multi-implementation 升級
- 與 `che-word-mcp` 整合：`.docx` extraction 用 `get_all_sections` / `get_paragraphs`
- 與 `perspective-writer` 區別：後者單 source 改寫，本 skill 多 source synthesis
