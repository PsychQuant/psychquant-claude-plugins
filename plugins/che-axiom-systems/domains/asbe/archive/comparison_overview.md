# ASBE vs Existing Approaches

**公理化範例規範與現有方法的比較**

This document compares ASBE with established specification methodologies.

---

## Comparison Matrix

| Aspect | ASBE | Pure Formal | SBE | Prose Spec |
|--------|------|-------------|-----|------------|
| **Precision** | ★★★★★ | ★★★★★ | ★★★☆☆ | ★★☆☆☆ |
| **Accessibility** | ★★★★☆ | ★★☆☆☆ | ★★★★☆ | ★★★★★ |
| **LLM Compatibility** | ★★★★★ | ★★★☆☆ | ★★★★☆ | ★★☆☆☆ |
| **Traceability** | ★★★★★ | ★★★★★ | ★★☆☆☆ | ★☆☆☆☆ |
| **Learnability** | ★★★★☆ | ★★☆☆☆ | ★★★★★ | ★★★★☆ |
| **Completeness** | ★★★★☆ | ★★★★★ | ★★★☆☆ | ★★☆☆☆ |

---

## 1. ASBE vs Pure Formal Methods (Z, VDM, Alloy)

### Pure Formal Example (Z Notation)

```
─── ParagraphSpec ─────────────────────
  paragraphs : ℙ Paragraph
  sentences : Paragraph → ℙ Sentence
  main_idea : Paragraph → Idea

  ∀ p : paragraphs ⦁
    (∀ s : sentences(p) ⦁ supports(s, main_idea(p)))
    ∧ 3 ≤ #sentences(p) ≤ 7
───────────────────────────────────────
```

### Same Rule in ASBE

```yaml
- id: "A3_unity"
  statement_natural: |
    Each paragraph should express exactly one main idea,
    with all sentences supporting that idea.
  statement_formal: |
    ∀p ∈ Paragraphs, ∃! main_idea(p)
    ∀s ∈ Sentences(p), supports(s, main_idea(p))
  violations:
    - content: "Budget meeting tomorrow. I like coffee..."
      explanation: "Multiple unrelated topics"
  compliant:
    - content: "The meeting will address three issues..."
      explanation: "All sentences support 'meeting topics'"
```

### Analysis

| Dimension | Pure Formal | ASBE | Winner |
|-----------|-------------|------|--------|
| Mathematical rigor | Complete | Sufficient | Pure Formal |
| Human readability | Low | High | ASBE |
| Learning curve | Steep | Moderate | ASBE |
| Practical application | Difficult | Direct | ASBE |
| LLM interpretation | Inconsistent | Reliable | ASBE |

**Verdict**: Pure formal methods are superior for theorem proving and safety-critical systems. ASBE is superior for communication, teaching, and LLM guidance.

---

## 2. ASBE vs Specification by Example (SBE/BDD)

### Traditional SBE (Gherkin)

```gherkin
Feature: Paragraph Unity

Scenario: Valid paragraph
  Given a paragraph about "budget meeting"
  When all sentences discuss meeting topics
  Then the paragraph is valid

Scenario: Invalid paragraph
  Given a paragraph starting with "budget meeting"
  When a sentence discusses "coffee preference"
  Then the paragraph is invalid
```

### Same Rule in ASBE

```yaml
- id: "A3_unity"
  statement_natural: "Each paragraph expresses one main idea"
  statement_formal: "∀p, ∃! main_idea(p) ∧ ∀s ∈ p, supports(s, main_idea)"
  violations: [...]
  compliant: [...]
```

### Analysis

| Dimension | SBE | ASBE | Winner |
|-----------|-----|------|--------|
| Example-driven | ★★★★★ | ★★★★★ | Tie |
| Formal foundation | ★☆☆☆☆ | ★★★★★ | ASBE |
| Hierarchical structure | ★☆☆☆☆ | ★★★★★ | ASBE |
| Executable tests | ★★★★★ | ★★☆☆☆ | SBE |
| Domain modeling | ★★☆☆☆ | ★★★★☆ | ASBE |

**Verdict**: SBE excels at executable acceptance tests. ASBE excels at principled domain knowledge. They serve complementary purposes.

---

## 3. ASBE vs Prose Specifications (Style Guides)

### Traditional Prose (APA Manual Style)

> "Effective writing involves clear communication of ideas. Writers should organize their thoughts logically, beginning each paragraph with a topic sentence that introduces the main idea. Supporting sentences should elaborate on this idea, providing evidence or examples. Avoid including tangential information that does not directly support the paragraph's central theme. The length of paragraphs should be appropriate to the complexity of the idea being expressed..."
>
> *(continues for several pages)*

### Same Content in ASBE

```yaml
axioms:
  - id: "A1_purpose"
    one_liner: "Writing transfers ideas to readers"
    statement_natural: "The purpose of writing is to transfer ideas..."
    statement_formal: "∀text, Purpose(text) = Transfer(idea, w→r)"

  - id: "A3_unity"
    one_liner: "One idea per paragraph"
    derives_from: ["A1_purpose"]
    violations: [{specific example}]
    compliant: [{specific example}]
```

### Analysis

| Dimension | Prose | ASBE | Winner |
|-----------|-------|------|--------|
| Nuance | ★★★★★ | ★★★☆☆ | Prose |
| Searchability | ★☆☆☆☆ | ★★★★★ | ASBE |
| Quick reference | ★☆☆☆☆ | ★★★★★ | ASBE |
| LLM reliability | ★★☆☆☆ | ★★★★★ | ASBE |
| Consistency | ★★☆☆☆ | ★★★★★ | ASBE |
| Cultural context | ★★★★★ | ★★☆☆☆ | Prose |

**Verdict**: Prose excels at conveying nuance and cultural context. ASBE excels at reliable, consistent, machine-interpretable rules.

---

## 4. When to Use Each Approach

### Use Pure Formal Methods When:
- Mathematical proof is required
- Safety-critical systems (aviation, medical devices)
- Formal verification is the goal
- Audience has formal methods training

### Use Traditional SBE When:
- Building executable test suites
- Agile software development context
- Business stakeholders need to validate requirements
- Tests should be automated

### Use Prose Specifications When:
- Extensive background context is needed
- Cultural or historical nuance matters
- Audience expects narrative format
- Flexibility in interpretation is acceptable

### Use ASBE When:
- LLMs will interpret the specification
- Principled, hierarchical rules are needed
- Both humans and machines must understand
- Quick reference and searchability matter
- Teaching systematic thinking about a domain

---

## ASBE's Unique Position

```
                    PRECISION
                        ↑
                        │
    Pure Formal ●       │
                        │       ● ASBE
                        │
         ───────────────┼───────────────→ ACCESSIBILITY
                        │
                ● SBE   │
                        │       ● Prose
                        │
```

ASBE occupies a unique position: **high precision + high accessibility**.

This is achieved through:
1. **Dual-layer expression** (natural + formal)
2. **Example grounding** (violations + compliant)
3. **Hierarchical structure** (axiom → theorem → rule)

---

## Migration Paths

### From Prose to ASBE
1. Identify implicit principles in prose
2. Formalize as axioms
3. Derive operational rules
4. Add examples from prose
5. Validate: does ASBE capture prose's intent?

### From Formal to ASBE
1. Keep formal notation as `statement_formal`
2. Add natural language explanations
3. Create concrete examples
4. Organize into axiom hierarchy

### From SBE to ASBE
1. Group examples by underlying principle
2. Abstract principles as axioms/theorems
3. Add formal notation
4. Establish derivation relationships

---

*Last updated: 2024-12-30*
