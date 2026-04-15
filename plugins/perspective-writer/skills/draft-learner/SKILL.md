---
name: draft-learner
description: >
  Auto-learn from user edits to draft files. When a system-reminder shows a draft was modified,
  diff the changes, extract concrete rules, and update .claude/rules/ files. Trigger when you
  detect a file modification system-reminder on a file you recently wrote or edited.
argument-hint: (auto-triggered from file modification)
allowed-tools: Read, Edit, Write, Grep, Glob, TaskCreate, TaskUpdate, TaskList
---

# Draft Learner

You have been triggered because a file you recently wrote or edited in this conversation was modified by the user. Your job is to learn from their edits and persist those preferences as reusable rules.

## Step 0: Bootstrap Stage Task List（強制）

**在動任何事之前**先用 `TaskCreate` 為這個 stage 建 todo list：

```
TaskCreate(name="step1_detect_and_diff",     description="Step 1: 讀修改後的檔案，對照原版，把每個改動分類")
TaskCreate(name="step2_extract_rules",       description="Step 2: 把每個改動轉成具體、可重用的 rule（一改動一 rule）")
TaskCreate(name="step3_locate_rules_file",   description="Step 3: Glob 找 .claude/rules/ 現有檔案；沒有就詢問是否建立")
TaskCreate(name="step4_update_rules",        description="Step 4: Edit 現有檔案（不覆寫、不重複、矛盾就取代）或 Write 新檔")
TaskCreate(name="step5_confirm_with_user",   description="Step 5: 給 user 簡短摘要說學到什麼、存到哪")
```

完成每一步立即 `TaskUpdate → completed`。**靜默完成 = 違規**。

**為什麼強制**：draft-learner 最大風險是 step 2 偷懶寫出「be more formal」這種沒用的模糊 rule 就交差。TaskList 讓 step 2 的「extract_rules」必須被看到完成，不能靜默跳過。

---

## Step 1: Detect and Diff

1. Read the modified file using the `Read` tool (the path comes from the system-reminder or conversation context).
2. Compare it against the original version you wrote — use the conversation history to recall exactly what you produced.
3. Categorize every change into one or more of these types:

| Category | Examples |
|----------|----------|
| **Tone shift** | Formality level, honorifics (你→您), pronoun changes, register |
| **Content cut** | Removed sentences, paragraphs, compliments, filler |
| **Content add** | Added greetings, closings, disclaimers, details |
| **Structure change** | Merged/split paragraphs, reordered sections, changed formatting |
| **Wording swap** | Specific word or phrase replacements (e.g., "希望"→"期盼") |

## Step 2: Extract Concrete Rules

Turn each change into a **concrete, reusable rule**. Specificity is critical.

### BAD (too vague — never write rules like these):
- "be more formal"
- "shorter emails"
- "adjust tone"

### GOOD (specific and actionable):
- "用「您」不是「你」when writing to professors or seniors"
- "刪掉評價對方研究設計的句子 — 只描述自己的需求"
- "結尾固定加「祝 研安」for academic correspondence"
- "每段不超過3句，避免長段落"
- "不用驚嘆號，句號結尾即可"
- "Use bullet points instead of prose for listing action items"

### Inferring WHY
If the reason behind a change is inferable, include it parenthetically:
- "不稱呼「親愛的」（對資深學者太隨意）"
- "Remove self-deprecating phrases like '不好意思打擾'（user prefers direct tone）"

**One rule per change.** Do not merge multiple distinct edits into a single vague rule.

## Step 3: Find or Create Rules File

Use `Grep` and `Glob` to check if a relevant `.claude/rules/` file already exists in the project.

### File naming conventions:
| Draft type | Rules file pattern |
|------------|-------------------|
| Correspondence to a person | `.claude/rules/correspondence-[recipient-name].md` |
| Reports / documents | `.claude/rules/[document-type]-style.md` |
| Code comments / docs | `.claude/rules/code-writing-style.md` |
| General writing | `.claude/rules/writing-style.md` |

### If the file exists:
1. **Read it first** using the `Read` tool.
2. Proceed to Step 4 (update).

### If the file does NOT exist:
1. Ask the user: "我偵測到你對草稿做了修改。要不要建立 `.claude/rules/[suggested-name].md` 來記住這些偏好？"
2. If the user agrees, create it with a header and the extracted rules.
3. If the user declines, still show the summary (Step 5) but do not persist.

## Step 4: Update Rules File

When updating an existing rules file:

1. **Do not duplicate.** If a rule already exists that covers the same point, skip it.
2. **Replace contradictions.** If a new rule contradicts an existing one, replace the old rule with the new one. Add a comment like `<!-- updated YYYY-MM-DD -->` next to the replacement.
3. **Organize by section.** Keep rules grouped under relevant headings (e.g., `## Tone`, `## Structure`, `## Vocabulary`, `## Opening/Closing`). Create new sections as needed.
4. **Append new rules** at the end of the appropriate section.

Use the `Edit` tool for surgical updates. Only use `Write` if creating a new file.

## Step 5: Confirm with User

After updating (or deciding not to), show a short summary:

```
從你的修改我學到了：
1. [concrete change 1]
2. [concrete change 2]
3. [concrete change 3]

已更新 `.claude/rules/[filename]`，你隨時可以打開修改。
```

If the user declined to create a rules file:
```
從你的修改我觀察到：
1. [concrete change 1]
2. [concrete change 2]

如果之後想儲存這些偏好，跟我說一聲就好。
```

## Important Guardrails

- **Always trigger on draft edits.** User edits to your drafts are the highest-signal feedback. Do not skip or ignore them.
- **Only trigger on YOUR drafts.** Only activate when the modified file is one you wrote or edited in the current conversation. Do not trigger on files the user is editing independently.
- **Stay concrete.** Every rule must be specific enough that a different AI session could follow it without ambiguity.
- **One rule per change.** Never merge multiple distinct edits into one vague rule.
- **Respect existing rules files.** Always read before writing. Never overwrite the entire file.
- **Language matching.** Write rules in the same language as the draft. If the draft is in Chinese, rules should be in Chinese. If mixed, match the dominant language.
