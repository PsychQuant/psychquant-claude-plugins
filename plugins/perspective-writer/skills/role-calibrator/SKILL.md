---
name: role-calibrator
description: >
  Adjust correspondence rules based on the writer's role and expertise in a collaboration.
  Trigger when the user says things like "我在這裡是統計專家", "我的角色是...", "這個我比他專業",
  "不應該用請教", "tone doesn't match my expertise", or when a draft uses deference language
  for topics where the user is the expert. Also trigger from /perspective-writer:role-calibrator directly.
argument-hint: <role description or correction>
allowed-tools: Read, Edit, Write, Grep, Glob
---

# Role Calibrator

Adjust communication rules when the writer's **role/expertise** doesn't match the current tone settings.

## Why This Exists

A single correspondence relationship has multiple **domains**. The writer might be junior in one domain
(business strategy) but senior in another (statistical methodology). Generic rules like "always use 請教"
break down when the writer IS the expert on the topic being discussed.

## Step 1: Identify the Calibration

From the user's input, extract:

1. **Who** — which recipient's rules need updating (check `.claude/rules/correspondence-*.md`)
2. **What domain** — the user's area of expertise (e.g., statistics, programming, psychometrics)
3. **Current problem** — what language feels wrong (e.g., "用請教問 ANOVA 的事很奇怪")
4. **Desired positioning** — how the user wants to come across in that domain

## Step 2: Read Existing Rules

```
Glob: .claude/rules/correspondence-*.md
Read the matched file(s)
```

Look for:
- Blanket deference rules that don't account for domain expertise
- Vocabulary tables that always map to humble language
- Missing "role positioning" section

## Step 3: Add or Update Role Section

Add a `## 角色定位` section (or update if it exists) that specifies:

1. **Writer's expertise domains** — where they lead, not follow
2. **Recipient's expertise domains** — where deference is appropriate
3. **Language mapping by domain**:

```markdown
## 角色定位

[Writer] 在這個合作中的角色是 **[role]**。[Recipient] 是 [their role]。

### 語氣切換規則

| 話題領域 | 誰是專家 | 語氣 | 用詞 |
|---------|---------|------|------|
| [domain A] | 寫信人 | 提供建議 | 「我建議…」「比較合適的做法是…」 |
| [domain B] | 收件人 | 請教 | 「想跟學長請教…」 |
| [domain C] | 雙方 | 確認對齊 | 「想跟學長確認…」「對齊一下…」 |
```

4. **Replacement vocabulary** for the expert domain:

| 避免（太謙虛） | 改用（展現專業） |
|---------------|----------------|
| 想請教 | 有幾個建議想確認 |
| 不知道這樣好不好 | 我建議這樣處理 |
| 要怎麼處理比較好 | 比較合適的做法是 |

## Step 4: Update Related Sections

Check if other sections need adjusting:
- **信件結構**: if it says "提出想請教的點", update to account for domain-based switching
- **用詞偏好**: add domain-specific overrides
- **注意事項**: add reminder about maintaining professional positioning

## Step 5: Confirm with User

Show a summary:

```
已更新 `.claude/rules/correspondence-[name].md`：

角色定位：
- 統計/方法論 → 你是專家，用「建議」「確認」
- 商業/產業 → 學長是專家，用「請教」

你可以打開 `.claude/rules/correspondence-[name].md` 確認或修改。
```

## Important

- **Don't remove deference entirely.** The user still respects the recipient as 長輩.
  The adjustment is domain-specific: expert tone for their domain, humble tone for the recipient's domain.
- **Deference ≠ expertise.** You can be respectful AND authoritative.
  "我建議用迴歸結果為主，ANOVA 作為補充，不知道學長覺得如何" — this is both respectful and expert.
- **One rule file per recipient.** Don't create a separate file for role calibration.
  Add the `## 角色定位` section to the existing correspondence file.
