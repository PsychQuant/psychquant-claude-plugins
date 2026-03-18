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

## Why AI Correspondence Fails

AI-generated correspondence describes the writer's qualifications like a product spec sheet.
Real people don't write like that. A real person writing an application email is nervous, strategic, genuine,
and aware of the social dynamics at play. They emphasize what they think the recipient cares about, not what
looks impressive on paper.

Before you write a single word of the actual letter, you must complete two phases of understanding.
Skipping these phases is not allowed. If you don't have enough information, ask.

## Phase 1: Understand the Writer

Read the user's existing materials to build a mental model of who they are and how they write.

**Sources to check (ask the user which are available):**
- Previous sent emails or correspondence
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
- "What's your actual feeling about this?" (nervous? excited? uncertain?)
- "What do you most want the recipient to take away?"
- "Is there anything you're worried about with this letter?"

Do not guess these. A person's internal state determines their writing tone, and you cannot infer it from their CV.

## Phase 2: Understand the Recipient

Research who the recipient is and what the relationship looks like from the writer's side.

**Gather:**
- The recipient's position, research area, recent work
- The power dynamic (professor you've never met? someone who knows your advisor? a peer?)
- Cultural context (Taiwanese academic norms? Japanese? Western?)
- Any prior interaction between the writer and recipient

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

**What real people do that AI doesn't:**
- Start with the point, not a self-introduction (the recipient will read your name and affiliation anyway)
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

## Phase 6: Present and Iterate

Show the draft to the user. Don't just dump it. Explain:
- "I wrote this as if you were [your simulation from Phase 3]"
- "The main thing I emphasized was [X] because I think that's what [recipient] would care about"
- "Let me know if the tone feels like you"

If the user says the tone is wrong, don't just adjust surface-level wording.
Go back to Phase 1 and ask what you got wrong about their internal state.
