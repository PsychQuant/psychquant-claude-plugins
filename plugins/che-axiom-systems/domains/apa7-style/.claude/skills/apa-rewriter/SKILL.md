---
name: apa-rewriter
description: Rewrite text to APA 7th edition style. Use when user asks to "rewrite to APA", "make APA compliant", "check APA style", or needs help with psychology/social science academic writing.
---

# APA 7 Rewriter Skill

Rewrite user-provided text to conform to APA 7th Edition style guidelines.

This skill is **self-contained** with all reference files included in this folder.

## Trigger Conditions

Use this skill when user:
- Asks to "rewrite to APA style" or "make this APA compliant"
- Wants to check if text follows APA 7 guidelines
- Needs help with academic writing in psychology/social sciences
- Mentions "APA format" or "academic writing"

## Reference Files (In This Folder)

**Required - Read these files for complete rules:**

| File | Content | Priority |
|------|---------|----------|
| `forbidden_patterns.yaml` | Words to delete/replace (46 patterns) | 1st |
| `transformation_rules.yaml` | Explicit X→Y rules (46 transformations) | 2nd |
| `writing_guidelines.yaml` | Tense, voice, formatting rules | 3rd |
| `writing_style.yaml` | Core axioms (clarity, precision, etc.) | Reference |

## Processing Pipeline

### Step 1: Delete Emphasis Words (Immediately)

Read `forbidden_patterns.yaml` → `emphasis_words` section.

Quick reference - delete these words without replacement:
- `importantly`, `notably`, `interestingly`
- `obviously`, `clearly`, `indeed`
- `actually`, `really`, `basically`, `critically`
- `significantly` (unless reporting statistics like p < .05)

### Step 2: Apply Transformations

Read `transformation_rules.yaml` for complete list.

Quick reference - common transformations:

| Pattern | Replacement | Category |
|---------|-------------|----------|
| `The study found` | `We found` | anthropomorphism |
| `The research showed` | `We found` | anthropomorphism |
| `The data suggest` | `These data indicate` | anthropomorphism |
| `due to the fact that` | `because` | redundancy |
| `in order to` | `to` | redundancy |
| `a lot of` | `many` / `much` | informal |
| `It is important to note that` | (delete) | empty_phrase |
| `mankind` | `humankind` | gender_inclusive |

### Step 3: Check Psychology-Specific Terms

Read `forbidden_patterns.yaml` → `psychology_specific` section.

In **correlational studies** (no experimental manipulation):
- `influence` → `was associated with`
- `impact` → `was related to`
- `causes` → `was associated with`
- `proves` → `suggests` / `indicates`

### Step 4: Verify Section-Specific Tense

Read `writing_guidelines.yaml` for complete rules.

| Section | Tense | Example |
|---------|-------|---------|
| Method | Past | "We recruited 100 participants" |
| Results | Past | "We found a significant effect" |
| Discussion | Present | "These findings suggest..." |

### Step 5: Final Checks

```
□ No emphasis words remain
□ No anthropomorphism (studies don't "find")
□ No redundant phrases
□ Correct tense for section type
□ Active voice where appropriate
□ Numbers: words for 0-9, numerals for 10+
□ Gender-inclusive language
```

## Output Format

Provide:
1. Rewritten text
2. List of changes made (what → what, reason)

## Example

**Input:**
> The study importantly found that stress significantly influences academic performance. This is due to the fact that a lot of students experience anxiety.

**Output:**
> We found that stress was associated with academic performance. Many students experience anxiety.

**Changes:**
1. `importantly` → deleted (emphasis word)
2. `The study found` → `We found` (anthropomorphism)
3. `significantly` → deleted (not statistical context)
4. `influences` → `was associated with` (correlational study)
5. `due to the fact that` → deleted, sentences merged (redundancy)
6. `a lot of` → `many` (informal)

## For Complete Rules

All reference files are included in this skill folder:
- `forbidden_patterns.yaml` - 46 patterns across 4 categories
- `transformation_rules.yaml` - 46 explicit transformations
- `writing_style.yaml` - 9 core axioms with examples
- `writing_guidelines.yaml` - 14 practical writing rules
