---
name: perspective-writer
description: >
  Write letters, emails, correspondence, autobiographies, and formal documents by first understanding the
  writer's voice and the recipient's context, then simulating how the writer would actually compose the message.
  Use when the user asks to draft an email, write a letter, compose a message, write an autobiography or
  personal statement, or any task where authentic voice matters. Also trigger when the user says
  "help me write to...", "draft a letter to...", "write an email for...", or expresses frustration with
  AI-generated writing feeling inauthentic. Do NOT trigger for blog posts or technical documentation.
---

# Perspective Writer

You are not writing *about* the user. You are writing *as* the user. The difference matters.

## The Golden Rule: Tarski's T-Schema

Every sentence you write must have a concrete referent. Tarski's T-schema says: "P" is true if and only if P.
Applied to writing: a sentence is meaningful only if it points to something specific and verifiable.

- "I use Python for data processing" → FAILS. What data? What processing? No referent.
- "I used Python to preprocess the four-wave longitudinal dataset" → PASSES. Points to a real thing.
- "extensive experience in statistical modeling" → FAILS. Which models? Which projects?
- "My dissertation required proving identifiability conditions for polychoric models" → PASSES.

AI writing feels hollow because it produces grammatically correct, topically relevant sentences that satisfy
no T-schema. The sentences don't *point to* anything. A human writer, when they write "I use R for simulation,"
is remembering the specific Monte Carlo study they ran last month. You don't have that memory, so you must
reconstruct the referent from the user's materials before writing. If you cannot find a concrete referent
for a claim, either ask the user or don't make the claim.

This principle overrides tone-matching. A sentence with perfect voice but no referent is worse than
an awkward sentence that points to something real.

**Time phrasing is a referent.** Words like "recently", "last week", "前幾天", "上週", "earlier this month"
all assert a specific time. Their referent must come from the writer's *verified* memory, not the AI's
guess. If the writer says 陳老師 mentioned X "前幾天" but the actual conversation happened 6 weeks ago,
the recipient reads "前幾天" and instantly distrusts the letter. Anchor every time-phrase to a specific
date (YYYY-MM-DD) before writing it. See Phase 1 "Temporal anchors" for the questions to ask.

**But T-schema alone is not enough.** Every sentence must simultaneously satisfy two constraints:
1. **T-schema**: it points to something concrete and verifiable.
2. **Writing goal**: it serves the document's purpose at the right level of detail.

A sentence can satisfy T-schema perfectly and still be wrong for the document. "SAS couldn't handle
the GLMM variant for ordinal comparative judgment data so I switched to RStan and used posterior mode
via Bernstein-von Mises to get MLE" has referents for every clause, but if each tool gets this treatment,
the skills section reads like a technical log instead of a narrative. The fix is not to remove referents,
but to find the right *grain size*: anchor claims in specifics without letting each specific become its own story.

In practice: when you draft a sentence, check T-schema first (does it point to something real?), then check
whether the level of detail serves the paragraph's goal. If one sentence has too much referent detail,
compress multiple referents into a single narrative arc
(e.g., "standard software couldn't handle the model → wrote custom estimation in RStan").

## The Fabrication Trap

T-schema says every sentence needs a referent. But there is a subtler failure mode: a sentence
can *appear* to have a referent while actually being fabricated. This happens in two ways:

**1. Embellishing the writer's experience.**

You read the user's CV, see "Statistics TA, 10 semesters," and write: "I guided students through
derivations of hypothesis testing logic." This sounds specific. It has a referent — but the referent
is *your inference*, not something the user actually did. Maybe they ran software labs, not derivations.

The fix: when describing what the user *did* (not what they *know*), treat it like a quote — it must
come from their materials or their own words. If the CV says "Statistics TA" and nothing more,
write "Statistics TA" and nothing more. Do not infer *how* they taught.

**2. Writing claims the user cannot defend.**

You research the recipient's publications and construct a technical connection: "Your D-optimality
framework for fMRI design shares the same Fisher information foundation as my Cramér-Rao bound work."
This may even be mathematically correct. But if the user says "I don't understand this," it cannot
go in the letter. The user will be asked about it in an interview and will not be able to answer.

The fix: before writing any claim that connects the user's work to the recipient's work at a
technical level, ask the user: "Do you understand this connection well enough to discuss it
in an interview?" If no, either simplify to a level they can defend ("I'm interested in learning
about optimal design") or leave it out entirely.

**3. Asserting external facts you haven't verified.**

A letter or CV states facts whose truth lives *outside* the writer — a paper's citation (journal,
volume, pages, DOI), a person's current title, a law's name and date, an institution's official name,
a statistic. These *look* grounded (they point to real-world things), but the writer's memory — or a
slide, transcript, or draft source you're working from — can be wrong: a misremembered volume number,
an outdated title, a rounded-up statistic. An unverified external fact is its own kind of fabrication:
the referent exists, but the sentence gets it wrong, and a recipient who happens to know the real
figure stops trusting the whole letter.

The fix: for any external fact — citation, title, date, official name, statistic — verify it against
an authoritative source (the journal's own page, the institution's site, the government record) before
it goes in. When the writer's memory or your draft source disagrees with the authoritative source,
**the authoritative source wins**. (Real examples: a draft said "the gap narrowed to about ten years"
when the official figure was 8.17 down to 6.19 — use the official one; a cited paper's volume and
pages must match the journal's page, not a slide that reproduced them from memory.)

**The test**: for every factual sentence, ask:
- "Did the user tell me this, or did I infer it?" → If inferred, ask them to confirm.
- "Could the user explain this sentence in their own words?" → If not, don't write it.
- "Is this an external fact (citation, title, date, official name, statistic) I'm asserting from memory or a secondhand source?" → If so, verify it against an authoritative source first; the source wins over memory.

## Why AI Correspondence Fails

AI-generated correspondence describes the writer's qualifications like a product spec sheet.
Real people don't write like that. A real person writing an application email is nervous, strategic, genuine,
and aware of the social dynamics at play. They emphasize what they think the recipient cares about, not what
looks impressive on paper.

Before you write a single word of the actual letter, you must complete two phases of understanding.
Skipping these phases is not allowed. If you don't have enough information, ask.

## Mode: Compose vs. Revise

This skill runs in one of two modes. Identify which one before Phase 0:

- **Compose** — writing a new letter or document from scratch. Run every phase in order.
- **Revise** — iteratively editing an existing draft. The draft may be a file the user points at, text pasted inline, or a draft produced earlier in the conversation; the request is to change a sentence, fix a paragraph, adjust tone, or smooth the logic. Once a first draft exists, this is the most common mode.

**Independent of mode**: whenever prior correspondence with the recipient exists, reading it (Phase 1-2) is mandatory. This also covers the in-between case — replying to an incoming message when no draft yet exists — because a reply is anchored to what the other side actually said, so the prior message is read first.

**The Revise trap.** Once a draft exists it is tempting to skip the understanding phases (Phase 1-3) — "the draft is already here, I already understand the writer and the recipient" — and jump straight to editing. Do not. Phase 1-2 is where the prior correspondence actually gets read (Phase 3 then re-derives the writer's perspective from it). A revision that changes *how the recipient's words are paraphrased*, or *what the writer claims*, is only safe when it is re-anchored to the real interaction history. Wording that merely reads smoothly can still have drifted from what was actually said.

**Revise mode does not skip the understanding phases.** It still reads the prior correspondence — the recipient's actual archived messages, the earlier drafts — before touching the draft. The phases are lighter in Revise mode (you are confirming, not building from nothing), but never skipped.

## Phase 0: Bootstrap Stage Task List（強制）

**在動任何事之前**先用 `TaskCreate` 為這個 stage 建 todo list，確保 7 個 phase 都有被追蹤：

```
TaskCreate(name="phase1_understand_writer",        description="Phase 1: 讀 user 材料（含與收件人的往來歸檔原文）建立 voice model + 問情緒狀態")
TaskCreate(name="phase2_understand_recipient",     description="Phase 2: 讀與收件人的真實往來原文 + 研究背景、power dynamic、cultural context")
TaskCreate(name="phase3_simulate",                 description="Phase 3: 寫出 simulation 段落再開始 draft")
TaskCreate(name="phase4_write_draft",              description="Phase 4: 初稿（Lead with WHY、Voice matching、Pressure calibration）")
TaskCreate(name="phase5_antipatterns_check",       description="Phase 5+5b: 過 anti-pattern checklist、用 horizontal rule 包裹輸出")
TaskCreate(name="phase6_present_and_iterate",      description="Phase 6: 呈現草稿並解釋選擇，等 user 回饋；若編輯檔案 → delegate draft-learner (6b)")
TaskCreate(name="phase7_persist_rules",            description="Phase 7: 徵詢後把通信習慣寫到 .claude/rules/correspondence-[recipient].md")
```

完成每一個 phase 立即 `TaskUpdate → completed`。**靜默完成 = 違規**。

**為什麼強制**：Phase 1-3 是「理解」階段，很容易被跳過直接 Phase 4 寫 draft。強制 TaskList 讓 skip 變得明顯。另外 Phase 7（persist rules）常被忘記，TaskList 收尾時就會提醒還沒做。

**注意**：Phase 5b 是 output format 的格式規範（用 `---` 不用 `>`），併進 `phase5_antipatterns_check`；Phase 6b 是偵測到檔案被改動時 delegate 到 `draft-learner` skill，不算獨立 phase，處理完回到 `phase6_present_and_iterate`。

---

## Phase 1: Understand the Writer

Read the user's existing materials to build a mental model of who they are and how they write.

**Sources to check:**
- Previous sent emails or correspondence — **if a prior-correspondence archive exists, read the actual messages; do not merely ask whether it exists.** This is the ground truth for the writer's voice and for what each side actually said. Reading it is mandatory whenever it exists, not only in Revise mode (see "Mode: Compose vs. Revise").
- Blog posts or personal writing
- The current conversation history (how the user talks to you is how they talk)
- Application materials, CV, academic papers

**What you're looking for:**
- Sentence length and structure (short and direct? long and nuanced?)
- Vocabulary habits (formal Chinese? mixed Chinese-English? casual?)
- How they express uncertainty or deference
- How they talk about their own work (modest? matter-of-fact? enthusiastic?)
- What they choose NOT to say (often more revealing than what they do say)
- **T-schema compliance**: How rigorously does this person ground their claims?
  (See Golden Rule above.) Match their specificity level, not just their voice.

**What you must ask the user directly:**

*Internal state:*
- "What's your actual feeling about this?" (nervous? excited? uncertain?)
- "What do you most want the recipient to take away?"
- "Is there anything you're worried about with this letter?"

*Temporal anchors (critical — see "Time phrasing as referent" under Golden Rule):*
- **Today's date** — explicitly state YYYY-MM-DD as the reference point for every "recently / 前幾天 / 上週 / last month" phrasing. Use system context (currentDate) when available, otherwise ask.
- **Writer's lifecycle stage** — what stage is the writer in right now? (e.g., onboarding week 2 of new postdoc, first semester teaching, mid-sabbatical, post-acceptance pre-start, application phase). This affects self-positioning ("I am..." vs "I will be..."), tense, and how much credentials need explaining.
- **Last contact / event with the recipient** — when, where, what context? Required before writing any "recently / last week / 前幾天 / 上次" phrasing. Convert into a specific date and verify against the writer's memory.

Do not guess any of these. A person's internal state determines their writing tone, and you cannot infer it from their CV. Time phrasings ("recently", "前幾天", "上週") that don't match the recipient's own memory of when an event happened are an immediate AI-generation tell — the recipient reads "前幾天" and thinks "wait, when?"

## Phase 2: Understand the Recipient

Research who the recipient is and what the relationship looks like from the writer's side.

**Gather:**
- The recipient's position, research area, recent work
- The power dynamic (professor you've never met? someone who knows your advisor? a peer?)
- Cultural context (Taiwanese academic norms? Japanese? Western?)
- Any prior interaction between the writer and recipient — **read the actual archived messages, both sides, verbatim**

**Paraphrasing the recipient is a referent (T-schema).** When the letter restates something the recipient said, check that restatement against the recipient's actual words. Two distinct moves — do not conflate them:

- *Softening the tentativeness of a polite refusal* is allowed: "we may be able to consider" need not harden into "you will consider."
- *Erasing factual guidance the recipient gave* is not allowed: a concrete time ("in a year"), a condition, an instruction — these are referents, not bookkeeping to be loosened away. Drop one and every downstream judgment that rested on it (how early is "early", whether an apology is warranted, whether a deadline was missed) drifts silently — invisibly, because the reworded sentence still reads fine.

**Then ask yourself (and write down the answers before drafting):**
- What does this person probably care about when reading this letter?
- How many similar letters do they probably receive?
- What would make them stop and actually read carefully?
- What would make them think "this person is real" vs "this was generated"?

## Phase 3: Simulate, Don't Compose

Before writing, explicitly articulate the writer's perspective in a short internal summary:

"If I were [name], a [situation description], writing to [recipient] about [purpose],
I would feel [emotion]. I would want them to know [key point]. I would be careful
about [concern]. The most natural way for me to open this letter would be..."

This is not optional. Write this simulation out before drafting.

## Phase 4: Write

Now draft the letter, following these principles:

**Voice matching (under T-schema):**
- Use the vocabulary and rhythm you observed in Phase 1
- If the user writes short, direct sentences in conversation, don't produce flowery paragraphs
- If the user mixes Chinese and English naturally, reflect that
- Match their level of formality, not what you think "sounds professional"
- While drafting, continuously check: does this sentence have a concrete referent?
  If not, either find one from the user's materials or ask. Never fill a gap with vague phrasing.

**The #1 rule: Lead with WHY, not WHO (前置動機).**

The reader's first question is always "why am I receiving this?" — never "who is this person?"
The first sentence of any correspondence must answer WHY before WHO.

- BAD: "I am Che Cheng, I got my PhD from NTU... I am writing to apply for..."
  (Reader still doesn't know why you're writing to THEM specifically)
- GOOD: "I attended your keynote at IASC-ARS 2025 and am writing to apply for..."
  (Immediately answers: you're not spam, you have a specific reason)

For replies: the first sentence should respond to the other person's last message, not start
with your own agenda. ("Thank you for your reply. The earlier email didn't arrive..." — not
"I would like to update you on my plans...")

WHO (credentials, background) goes later in the email, compressed. The CV is attached.

**What real people do that AI doesn't:**
- Mention specific things about the recipient's work that actually connect to their situation
  (not a literature review, but "I read your paper on X, and it's relevant to a problem I'm facing")
- Express genuine motivation, not manufactured enthusiasm
- Leave some things unsaid. Not every qualification needs to be listed. Trust that the CV is attached.
- Be slightly imperfect. Real emails have personality.

**Cultural calibration (Taiwanese academic context):**
- Opening: use full name + title for first address (e.g., "程毅豪老師您好"), then "老師" afterward
- Don't address someone by full name repeatedly in the body (feels distant, like reading about a stranger)
- Closing: simple and warm, not stiff. "謝謝老師" is fine. "感謝老師撥冗審閱" is borderline robotic.
- The email itself serves as the cover letter. Don't repeat what's in the attached autobiography.

**Cultural calibration (Japanese academic context):**
- Leave space for the recipient to not respond, not commit, not feel obligated.
- Use softeners like "if by any chance" or "if it is convenient" before any request or proposal.
- If the recipient gave a vague timeline (e.g., "at least until 2027"), do NOT pin it down in your reply
  (e.g., "closer to 2027" feels like pressure). Use "in the future" or "when the time is right" instead.
- Japanese professors value indirectness. A sentence that says "I am available anytime" is less pressure
  than "I will contact you in January 2027."
- When the recipient has declined or delayed, your reply should convey understanding and zero urgency.
  The relationship is more important than the immediate opportunity.

**Pressure calibration (applies to all correspondence):**

After drafting, re-read every sentence and ask: **"How much social pressure does this sentence put on the
recipient?"** This is especially critical when:
- The recipient has already said no, or deferred
- There is a power asymmetry (you are junior)
- The cultural context values indirectness (Japanese, some Taiwanese formal contexts)

Common pressure traps:
- **Pinning down vague timelines.** If they said "maybe next year," don't reply with a specific month.
- **Listing specific ways you can help.** The more specific, the more it implies they should say yes.
  "I would be delighted to help" (open) vs "I could collect data, run analyses, and coordinate with
  your lab" (feels like you're already planning to move in).
- **Eagerness overflow.** The right word choice matters:

| Too eager (pressure) | Appropriate | Low-key |
|---------------------|-------------|---------|
| enthusiastic | delighted | happy |
| eager | glad | grateful |
| passionate about | interested in | appreciate |
| I can't wait to | I look forward to | I hope to |
| as soon as possible | at your convenience | when the time is right |

- **The "less is more" principle for proposals.** When offering to help or proposing collaboration,
  one short sentence is less pressure than a detailed paragraph. Let the recipient ask for details
  if they are interested.

**Ordering as a status signal (multi-recipient / list-bearing correspondence):**

When a message arranges people or options — the To/CC order, a name roster, a list of candidate
time slots — the *order itself* is read as a status signal. Every listed person notices where they
sit. Put external guests, invited experts, and senior figures **near the front, never last**: a lone
outside guest trailing a block of in-house names reads as an afterthought or filler, even when the
writer meant nothing by it. Before sending, re-read the recipient order and any roster the way each
person would see their *own* placement, and reorder so no one is left feeling put at the back. This is
courtesy expressed through arrangement rather than words — especially load-bearing in hierarchical /
relational cultures (Taiwanese, Japanese, and most cross-institutional settings).

## Phase 5: Anti-Patterns Checklist

Before presenting the draft, check for these AI writing tells and remove every instance:

| Pattern | Why it's a problem | Fix |
|---------|-------------------|-----|
| Em dashes (——) | AI signature move for parenthetical elaboration | Rewrite as two sentences, or use commas |
| "致力於" "長期致力於" | Nobody talks like this in a letter | Say what they actually do |
| "高度契合" "密切關聯" | Vague corporate-speak | Be specific about what connects |
| "均展現了..." "充分體現..." | Self-promotional summary sentences | Delete. The facts speak for themselves. |
| Listing 3+ things with "、" in parallel | Reads like a spec sheet | Pick the 1-2 most relevant, or break into sentences |
| "核心精神" "根本問題" "本質上" | Grandiose framing | Just say what you mean |
| Starting paragraphs with "在...方面" | Formulaic topic sentence structure | Vary your openings |
| "不僅...更..." "不僅...也..." | AI loves this construction. Humans use it sparingly. | Use it at most once per document |
| Ending with "期盼" "期許" "展望" | Overly formal, sounds like a press release | End like a person: "謝謝老師" or "希望有機會跟老師聊聊" |
| English sincerity-intensifier adverbs ("sincerely", "deeply", "truly", "genuinely", "wholeheartedly", "really", "very much") modifying verbs of gratitude / hope / appreciation | Native English correspondence carries sincerity in the verb and the structure, not in adverbs. Stacked intensifiers ("I deeply appreciate", "I sincerely hope", "I would very much like to", "I am truly grateful") read as ESL or AI — the writer is *telling* you they are sincere instead of *being* sincere. The fix is almost always deletion, not substitution. | Drop the adverb entirely: "I appreciate" / "I hope" / "I would like to" / "I am grateful". `Sincerely yours` at sign-off is the one fixed slot; elsewhere, sincerity intensifiers are noise. Exception: "I sincerely apologize" in formal rituals (and even then, often "I apologize" is enough). |
| Vague temporal phrasing without verified anchor ("recently", "前幾天", "上次", "earlier") | If the writer hasn't told you the specific date, AI defaults to "前幾天" / "recently" — but the recipient knows when things actually happened and will notice the mismatch. Pure AI tell. | Ask the writer for the specific date. Replace "前幾天" with "上週四" or "5/8 在 storyline 會議時" — anchored phrasings carry the same warmth without the AI smell. |
| Extra `---` / `***` hrules inside letter body | AI uses horizontal rules to segment emails into card-like sections. Humans don't—they use paragraph breaks. | Delete every hrule except the Phase 5b wrapper pair. One paragraph = one idea; adjacent paragraphs separated by blank lines, not hrules |
| **Adjacent structural dividers** | Two lines with only whitespace between (e.g., section-closing rule + next-section-opening rule, or heading-trailing rule right before `---`). This is the *actual* AI tell—not the total count of lines but the back-to-back pair. | Remove one side of the pair. Default to keeping the semantically stronger line (e.g., keep the wrapper; remove the heading-trailing decorative `::after` rule) |
| `2px double` borders (in HTML/PDF drafts) | Double-line borders are AI design reflex for emphasis (e.g., total row, CTA divider) | Use `1px solid`. Emphasis comes from *weight difference* against neighboring soft rules, not from doubling the line itself |
| Decorative `::before` / `::after` rules on every heading | AI adds trailing horizontal lines after `I SCOPE · 關於本工作坊`-style labels to "make it look editorial" | Remove. Small-caps labels with proper letter-spacing carry enough visual weight alone |
| Arrow symbols (`→` / `$\rightarrow$`) in prose to show direction, change, or causality | Fine in slides or notes, but in formal prose the reader has to "sound it out", and the arrow is ambiguous (sequence? causality? numeric change? lead-lag direction?). A clear AI tell in academic/report writing. | Spell it out in words: "期貨領先現貨之方向", "由 0.81 上升至 0.89", "X 導致 Y". Keep arrows only inside math mode, equations, or actual diagrams. |
| "新增" / "新加" / "另新增" framing in a one-piece document | In a finished document every part is integral. "第四章新增之…" / "本研究新增了…" exposes multi-pass assembly and reads as patched-together — the reader is not supposed to see the seams. | Drop the "新增" frame: "第四章新增之 X" → "第四章之 X" / "本研究之 X". State what the section *is*, not when it was bolted on. |

## Phase 5b: Output Format

**CRITICAL: Never use markdown blockquote (`>`) for email/letter drafts.**
Blockquotes render with a left border line in terminals and chat UIs, making the draft look like
a quoted reply rather than original text. The user will copy this text to send — it must be clean.

**Correct format**: Use a horizontal rule (`---`) before and after the draft to visually separate it.
Write the body as plain paragraphs with no `>` prefix. Lists (`-`) are fine for bullet points
within the email (e.g., available time slots).

```
---

Recipient greeting,

Body paragraph 1.

Body paragraph 2.
- Item 1
- Item 2

Signature

---
```

### Only TWO `---` allowed per draft (before + after). Zero internal hrules.

Common AI mistakes (all are AI signatures — real people don't do any of these):

- ❌ Adding `---` between body paragraphs as section dividers
- ❌ Adding `---` before the signature line
- ❌ Using `---` or `***` to separate "main content" from "postscript"
- ❌ Using `---` to replace a period or comma transition

If the draft needs to signal structural shift, let paragraphs do it: blank line between
two paragraphs is enough. If two topics feel like they need a hard divider between them,
they probably belong in **two separate messages**, not one email with hrules.

**When you present the draft, count your `---`. There should be exactly 2.** More than 2
means you've accidentally built a template aesthetic into what should feel like a personal
letter. Delete the extras before showing the user.

### The Adjacency Principle (generalizes beyond `---`)

The real AI tell isn't "too many dividers"—it's **two dividers appearing back-to-back**
with nothing meaningful between them. This generalizes beyond markdown hrules to any
formatted output:

| Medium | Adjacent-pair anti-pattern |
|--------|---------------------------|
| Markdown letter/email | `---` then blank line then another `---` (both wrapping something trivial) |
| Markdown with sections | `---` section divider immediately after a `## heading` line |
| HTML / PDF drafts | `border-bottom` on one section + `border-top` on the next section with only margin between |
| HTML / PDF tables | Last `.row { border-bottom }` soft + `.total { border-top }` strong = double line above total |
| HTML / PDF typography | `::after { background }` decorative rule after heading + next section's `border-top` |

**Fix pattern**: remove one side of the pair. Default: keep the semantically stronger/structural
line, drop the decorative one. For table footers specifically: `.row:has(+ .row.total) { border-bottom: none }`.

### Default bias: human-messier > AI-tidy

When in doubt, **cut the divider**. Real human writing is structurally messier than AI
output—paragraphs end, new paragraphs start, and the reader infers structure from the
writing itself. AI compulsively adds visual scaffolding (hrules, borders, ::before rules,
card wrappers) because it feels "organized." Humans don't care, and the pattern betrays
the generator.

Heuristic: if you can remove a divider (hrule, border, `::after`, wrapper) and the adjacent
content is still comprehensible, **remove it**. Your default should skew toward "too few
dividers" rather than "just enough." Err on the side of typography doing the work, not
visual bars.

This heuristic applies not just to `---` in markdown but to **every CSS border declaration**
when generating HTML/PDF drafts (DMs, proposals, reports). Count rendered horizontal lines
per page; pairs with nothing meaningful between them are the AI tell to fix.

## Phase 6: Present and Iterate

Show the draft to the user. Don't just dump it. Explain:
- "I wrote this as if you were [your simulation from Phase 3]"
- "The main thing I emphasized was [X] because I think that's what [recipient] would care about"
- "Let me know if the tone feels like you"

If the user says the tone is wrong, don't just adjust surface-level wording.
Go back to Phase 1 and ask what you got wrong about their internal state.

## Phase 6b: Learn from User Edits

If the user edits the draft file directly (detected via system-reminder about file modification),
invoke the **`draft-learner`** skill: `/perspective-writer:draft-learner`

This skill handles diffing, rule extraction, and updating `.claude/rules/` automatically.
Do NOT duplicate its logic here.

Each user edit begins another Revise pass. Per "Mode: Compose vs. Revise", a revision is not mere
wording polish — before reworking the draft again, re-anchor to the prior correspondence
(Phase 1-2). Do not skip it just because a draft already exists.

## Phase 7: Persist for Next Time

After the user confirms the draft (or after tone corrections), ask:

> "要不要把跟 [recipient] 的通信習慣記下來？這樣下次寫信就不用重新調整語氣了。
> 我會存在 `.claude/rules/` 裡，你隨時可以打開修改。"

If the user agrees, persist everything to `.claude/rules/correspondence-[recipient].md`:

```markdown
# 通信規則 — [Recipient Name]

## 基本資訊
| 欄位 | 內容 |
|------|------|
| 姓名 | ... |
| 稱呼 | **...**（寫信時一律用此稱呼） |
| Email | ... |
| 關係 | 長輩/同輩/晚輩 |
| 職位 | ... |

## 稱呼與語氣
- 開頭：...
- 文中：...
- 結尾：...
- 語氣特徵：...

## 用詞偏好
| 避免 | 改用 |
|------|------|
| ... | ... |

## 信件結構
1. ...
2. ...

## 注意事項
- ...
```

**Important**:
- **不要寫進 CLAUDE.md** — 通信對象的個人資訊放在 rules 裡就好，CLAUDE.md 太外顯。
- If the rules file already exists, READ it first and UPDATE/ADD. Don't overwrite.
- Always tell the user: "設定存在 `.claude/rules/correspondence-[name].md`，你隨時可以打開修改。"
- If the user corrected the tone during Phase 6, the correction itself is the most valuable thing to persist.
  Capture the specific fix (e.g., "用『請教』不用『討論』") not just a vague rule.
- Use `correspondence-[recipient].md` naming so multiple recipients each have their own file.
