---
name: save-feedback
description: >
  Capture conversational feedback during a perspective-writer drafting session into
  reusable rules. Trigger when user explicitly requests it (e.g. /perspective-writer:save-feedback)
  or when they say "存 feedback" / "save what you learned" / "把這些建議記下來" mid-draft.
  Distinct from draft-learner (which only triggers on file modification).
argument-hint: (auto-triggered or invoked manually mid-draft)
allowed-tools: Read, Edit, Write, Grep, Glob, TaskCreate, TaskUpdate, TaskList
---

# Save Feedback

You have been triggered to capture **conversational feedback** that the user gave during a drafting session — feedback that did **not** result in a file modification (so draft-learner never ran). Your job is to scan recent conversation, extract concrete style/tone/relationship/structure rules, and persist them to `.claude/rules/`.

## Why this skill exists (separate from draft-learner)

`draft-learner` only triggers on a file-modification system-reminder. But in real drafting sessions, **most style feedback happens in conversation**:

> 「短一點然後不要有AI感」
> 「她是我的長輩,減少指示性論點」
> 「段落順序按 APA 排」
> 「太直接了,改委婉一點」

When the user gives verbal feedback and the agent rewrites the file each round, **no file diff is produced**. draft-learner never fires. The feedback evaporates at session end.

`save-feedback` fills that gap. User invokes it explicitly when they want a snapshot of conversational feedback baked into rules.

## Step 0: Bootstrap Stage Task List(強制)

```
TaskCreate(name="step1_scan_conversation",  description="Step 1: 掃 recent 對話,找出 user 給的 style/tone/relationship/structure feedback")
TaskCreate(name="step2_classify_feedback",  description="Step 2: 把每條 feedback 分類 (tone / relationship / structure / cultural / rejection-reason)")
TaskCreate(name="step3_extract_rules",      description="Step 3: 把每條 feedback 轉成具體可重用的 rule (一條 feedback 一個 rule)")
TaskCreate(name="step4_locate_rules_file",  description="Step 4: Glob 找 .claude/rules/ 現有檔;沒有就建議 path")
TaskCreate(name="step5_write_rules",        description="Step 5: Edit 既有檔(避免重複)或 Write 新檔")
TaskCreate(name="step6_confirm_with_user",  description="Step 6: 給 user 簡短摘要 (學到 N 條,存到哪)")
```

完成每一步立即 `TaskUpdate → completed`。**靜默完成 = 違規**。

---

## Step 1: Scan Conversation for Feedback

Read recent messages (last ~20 turns or since the perspective-writer session started). Look for:

| Pattern | Examples |
|---------|----------|
| **Tone correction** | 「太直接」「太 AI」「太正式」「太硬」「短一點」 |
| **Relationship context** | 「她是長輩」「他是合作者」「我們很熟」「日本文化要委婉」 |
| **Structure preference** | 「按 APA 排」「先講結論」「用 bullet 不要長句」「加數字」 |
| **Cultural calibration** | 「日文書信不能直接 say no」「中文不要用破折號」 |
| **Rejection of a draft** | 「這版不行,太...」「重寫,這次要更...」 |
| **Negation patterns** | 「不要 X」「避免 Y」「除非...否則...」 |

Skip pure factual corrections (「這個日期錯了」/「拼字錯」)— 那些是 content fix,不是 style rule。

## Step 2: Classify Each Feedback

每條 feedback 標 1-2 個 tag:

- `tone` — 語氣強度、AI 感、商業化程度
- `relationship` — 跟收件人的關係(長輩 / 同輩 / 學生 / 客戶)
- `structure` — 段落順序、列表 vs 散文、長度上限
- `cultural` — 跨文化的書信慣例
- `negation` — 「絕對不要 X」這類禁忌
- `format` — 格式偏好(無破折號、無 emoji 等)

## Step 3: Extract Concrete Rules

每條 feedback **必須**轉成可重用的 rule。不要寫「be more formal」這種沒用的模糊 rule。

### BAD (太模糊):
- 「Be appropriate for the audience」
- 「Use natural tone」
- 「Match cultural conventions」

### GOOD (具體):
- 「對日本長輩:避免直接的「請你做 X」,改用「もしご都合がよろしければ、Xをお願いできますでしょうか」這類緩衝句」
- 「APA 段落順序:Background → Method → Results → Discussion;reorder if user wrote out of order」
- 「中文書信不用破折號(——),改用句號分句」

### Inferring WHY (重要)

如果 user 給 feedback 但沒解釋原因,**推測背後的 invariant**:
- 「她是長輩」 → 推測 invariant 「對方權力位階高,需要 buffer / hedging」
- 「太 AI 感」 → 推測 invariant 「避免 elaborate parallel structures、過度使用 bullet、過度修飾」

把 invariant 寫進 rule 的 **Why** 欄位,這樣未來 reader 知道何時 apply / 何時例外。

## Step 4: Locate Rules File

```bash
ls .claude/rules/*.md 2>/dev/null
```

### 命名慣例

- 對特定 recipient 的 rules → `recipient-{name}.md` (e.g. `recipient-tatsuma.md`、`recipient-japanese-elders.md`)
- 對 document type 的 rules → `style-{type}.md` (e.g. `style-academic-jp.md`、`style-recommendation-letter.md`)
- 通用 anti-patterns → `anti-patterns.md`

### 已有檔 vs 新建

- 既有檔的 topic 與本次 feedback overlap → Edit 加新 rules,**不重複既有 rules**
- 完全新主題 → Write 新檔
- 不確定 → 詢問 user 哪個 path

## Step 5: Write Rules File

格式:

```markdown
# Recipient: tatsuma (日本琉球大學合作者)

## Tone
- 對長輩 / senior 合作者:用 です/ます 體 + 緩衝句(「もしご都合がよろしければ」)。**Why**:日本書信對 senior 必須加 hedging,直接 imperative 視為失禮
- 不用「請你 X」直接句:改 「Xをお願いできますでしょうか」

## Structure
- 段落順序:greeting → context → main request → closure。**Why**:APA-like 順序在跨文化書信也通用,user 偏好

## Anti-patterns
- ❌ 破折號 「——」 — user 明示「太 AI 感」
- ❌ 長段落含多個 bullet — 改散文敘述
- ❌ 「我們建議...」這類 directive 語氣
```

每條 rule 帶 `**Why**` 句子,讓未來 reader 判斷 edge case。

## Step 6: Confirm With User

簡短回報:

```
✓ 從對話擷取 N 條 feedback,存到 .claude/rules/recipient-tatsuma.md:
  - tone: 3 條 (緩衝句 / です ます / 避免 directive)
  - structure: 1 條 (APA-like 段落順序)
  - anti-patterns: 2 條 (破折號 / bullet)

下次起草給 tatsuma 的信時,perspective-writer 自動套用這些 rules。
要我順便把這些 rules 跟 draft-learner 已存的 rules merge 嗎?
```

---

## Important Guardrails

- **DO NOT scan beyond perspective-writer session**:只擷取本次 drafting session 的 feedback,不掃整個對話歷史
- **DO NOT invent rules from agent's own decisions**:只擷取 user 明確說的 feedback,不把 agent 自己「猜對方喜歡這樣」的決策寫成 rule
- **DO NOT overwrite existing rules silently**:既有 rule 與本次 feedback 衝突 → 詢問 user 哪個對
- **DO ask for tag if ambiguous**:無法歸類的 feedback (e.g. 「這版比較好」沒說為什麼) → 詢問 user 是 tone / structure / 其他

## When to invoke

- `/perspective-writer:save-feedback` — explicit invocation
- User says 「存 feedback」「save what you learned」「把這些建議記下來」mid-draft
- End of perspective-writer session if user gave 3+ rounds of conversational feedback (proactive suggestion: 「我注意到你給了不少 feedback,要 save 起來嗎?」)

## Distinct from draft-learner

| | draft-learner | save-feedback |
|---|---|---|
| Trigger | file-modification system-reminder | explicit invocation |
| Source | file diff | conversation history |
| Scope | per-file change | per-session feedback |
| Output | rules in `.claude/rules/` | rules in `.claude/rules/` |
| Run order | automatic | manual / proactive suggestion |

兩個 skill **互補**,可同時跑。draft-learner 抓 file edit 的明顯改動,save-feedback 抓對話裡 user 沒動手只口頭說的偏好。
