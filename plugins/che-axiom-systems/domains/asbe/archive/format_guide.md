# ASBE Format Guide

**如何撰寫 ASBE 規範**

This guide explains how to write specifications following the ASBE methodology.

---

## Quick Start

An ASBE specification has four layers:

```
┌─────────────────────────────────────┐
│  1. METADATA                        │  Domain, version, author
├─────────────────────────────────────┤
│  2. AXIOMS                          │  Foundational principles
├─────────────────────────────────────┤
│  3. THEOREMS / COROLLARIES          │  Derived rules
├─────────────────────────────────────┤
│  4. OPERATIONAL RULES               │  Practical guidelines
└─────────────────────────────────────┘
```

Each rule contains:

```yaml
id: "A1_clarity"           # Unique identifier
statement_natural: "..."   # Human language
statement_formal: "..."    # Formal notation
violations: [...]          # Bad examples
compliant: [...]           # Good examples
```

---

## Step-by-Step Guide

### Step 1: Identify Your Domain

Ask yourself:
- What am I trying to axiomatize?
- What decisions does this specification need to guide?
- Who will use this specification (humans, LLMs, both)?

### Step 2: Start with 3-5 Core Axioms

Good axioms are:
- **Self-evident**: Require no justification within the domain
- **Independent**: Cannot be derived from each other
- **Foundational**: Other rules naturally follow from them

**Bad axiom** (too specific):
```yaml
id: "A1"
statement_natural: "Paragraphs should be 3-5 sentences long"
```

**Good axiom** (foundational):
```yaml
id: "A1"
statement_natural: "Writing exists to transfer ideas from writer to reader"
```

### Step 3: Write Dual Expressions

For each rule, write BOTH natural and formal versions:

```yaml
statement_natural: |
  Each paragraph should express exactly one main idea.

statement_formal: |
  ∀p ∈ Paragraphs, ∃! idea(p) such that
    ∀s ∈ Sentences(p), supports(s, idea(p))
```

**Tips for formal notation**:
- Use standard logic symbols (∀, ∃, →, ∧, ∨, ¬)
- Define domain-specific functions as needed
- Formal need not be executable—clarity > rigor

### Step 4: Add Examples

Every rule needs at least one violation and one compliant example:

```yaml
violations:
  - description: "Paragraph with multiple unrelated ideas"
    content: |
      The budget meeting is tomorrow. I like coffee.
      The new policy affects everyone. It might rain.
    explanation: "Four unrelated statements in one paragraph"

compliant:
  - description: "Paragraph with unified topic"
    content: |
      The budget meeting tomorrow will address three concerns.
      First, we need to discuss the Q4 projections.
      Second, the hiring freeze requires review.
      Third, we must allocate funds for the new project.
    explanation: "All sentences support the main idea of 'budget meeting concerns'"
```

### Step 5: Derive Theorems

Once axioms are established, identify patterns that follow:

```yaml
id: "T1_known_new"
derives_from: ["A1_clarity", "A2_reader_focus"]
statement_natural: |
  Sentences should begin with known information and
  end with new information.
```

### Step 6: Add Operational Rules

Operational rules are practical guidelines derived from the theory:

```yaml
id: "R1_paragraph_length"
derives_from: ["A3_unity", "T2_cognitive_load"]
statement_natural: |
  Keep paragraphs between 3-7 sentences.
statement_formal: |
  ∀p ∈ Paragraphs, 3 ≤ |Sentences(p)| ≤ 7
```

---

## Naming Conventions

| Prefix | Type | Example |
|--------|------|---------|
| A | Axiom | A1, A2_clarity |
| T | Theorem | T1, T3_flow |
| C | Corollary | C1, C2_emphasis |
| R | Rule | R1, R5_lists |

---

## Common Mistakes

### Mistake 1: Axioms that are actually rules

```yaml
# BAD: This is derivable, not foundational
id: "A1"
statement_natural: "Use active voice"

# BETTER: As an operational rule
id: "R3_active_voice"
derives_from: ["A1_clarity", "T1_directness"]
statement_natural: "Prefer active voice for clearer attribution"
```

### Mistake 2: Examples that don't clearly illustrate

```yaml
# BAD: Ambiguous example
violations:
  - content: "The thing happened."
    # What makes this a violation? Unclear.

# BETTER: Specific and explained
violations:
  - description: "Vague noun requiring context to understand"
    content: "The thing happened yesterday."
    explanation: "'Thing' could refer to anything; reader lacks context"
```

### Mistake 3: Natural and formal say different things

```yaml
# BAD: Mismatch
statement_natural: "Paragraphs should be short"
statement_formal: "∀p, |words(p)| < 100"  # This says <100 words, not "short"

# BETTER: Aligned
statement_natural: "Paragraphs should contain fewer than 100 words"
statement_formal: "∀p ∈ Paragraphs, |words(p)| < 100"
```

---

## Template

```yaml
meta:
  domain: "Your Domain"
  version: "1.0.0"
  author: "Your Name"
  created: "2024-12-30"

axioms:
  - id: "A1_foundation"
    name: "Foundation Axiom"
    one_liner: "Brief summary here"
    statement_natural: |
      Natural language description...
    statement_formal: |
      ∀x ∈ Domain, Property(x)
    rationale: "Why this axiom matters..."
    violations:
      - description: "What this violates"
        content: "Example content"
        explanation: "Why it violates"
    compliant:
      - description: "What this demonstrates"
        content: "Example content"
        explanation: "Why it complies"

theorems:
  - id: "T1_derived"
    derives_from: ["A1_foundation"]
    # ... same structure as axiom
```

---

## Validation Checklist

Before finalizing your ASBE specification:

- [ ] Every axiom is truly foundational (not derivable)
- [ ] Every non-axiom has `derives_from` specified
- [ ] Every rule has `statement_natural` AND `statement_formal`
- [ ] Every rule has at least one violation example
- [ ] Every rule has at least one compliant example
- [ ] Natural and formal statements are semantically equivalent
- [ ] Examples are specific and clearly explained
- [ ] IDs follow naming conventions

---

*Last updated: 2024-12-30*
