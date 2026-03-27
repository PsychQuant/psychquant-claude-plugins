# Axiomatic Specification by Example (ASBE)

**公理化範例規範**

ASBE is a methodology for creating formal specifications optimized for both human understanding and LLM consumption. It combines axiomatic rigor with example-driven accessibility.

---

## Quick Start

### Minimal Template

Copy this template to create an ASBE specification:

```yaml
meta:
  domain: "Your Domain Name"
  version: "1.0.0"

axioms:
  - id: "A1_xxx"                      # Required: unique ID (A=axiom)
    one_liner: "Brief summary"        # Optional: max 100 chars

    statement_natural: |              # Required
      Plain language description of the rule.
      Multiple sentences are fine.

    statement_formal: |               # Required
      ∀x ∈ Domain, Property(x) → Conclusion(x)

    rationale: |                      # Optional
      Why this axiom matters.

    violations:                       # Required: at least 1
      - description: "What's wrong with this"
        content: |
          The actual bad example text.
        explanation: "Why it violates the rule"  # Optional

    compliant:                        # Required: at least 1
      - description: "What's right about this"
        content: |
          The actual good example text.
        explanation: "Why it satisfies the rule"  # Optional

theorems:                             # Optional section
  - id: "T1_xxx"                      # T=theorem
    derives_from: ["A1_xxx"]          # Required for theorems
    statement_natural: |
      ...
    statement_formal: |
      ...
    violations: [...]
    compliant: [...]

rules:                                # Optional section
  - id: "R1_xxx"                      # R=operational rule
    derives_from: ["T1_xxx"]          # Required
    # ... same structure
```

### Validation Checklist

Before finalizing your ASBE specification:

- [ ] Every rule has `statement_natural` AND `statement_formal`
- [ ] Every rule has at least 1 `violations` example
- [ ] Every rule has at least 1 `compliant` example
- [ ] Every theorem/rule has `derives_from` pointing to parent(s)
- [ ] Axioms have NO `derives_from` (they are foundational)
- [ ] All `id` values are unique
- [ ] `statement_natural` and `statement_formal` express the same rule

### ID Naming Convention

| Prefix | Type | Example |
|--------|------|---------|
| `A` | Axiom | `A1_clarity`, `A2_unity` |
| `T` | Theorem | `T1_known_new`, `T2_economy` |
| `C` | Corollary | `C1_emphasis` |
| `R` | Rule | `R1_paragraph_length` |

---

## Core Concept

ASBE synthesizes three paradigms:

| Component | Source | Role in ASBE |
|-----------|--------|--------------|
| **Axiomatic Structure** | Mathematical Logic | Hierarchy: Axiom → Theorem → Rule |
| **Specification by Example** | Gojko Adzic (2011) | `violations` + `compliant` examples |
| **Dual-Layer Representation** | Formal Methods | `statement_natural` + `statement_formal` |

### Why Both Natural and Formal?

```
Natural language alone  →  Accessible but ambiguous
Formal notation alone   →  Precise but opaque
ASBE (both + examples)  →  Accessible AND precise
```

---

## Files in This Directory

```
Axiomatic Specification by Example/
├── README.md                        # This file
├── asbe_axioms.md                   # The 5 axioms OF ASBE itself
├── asbe_axioms_bootstrapped.yaml    # ASBE axioms in ASBE format (self-reference)
├── writing_style_asbe.yaml          # Example: writing style specification
└── archive/                         # Archived reference materials
```

**Start here:**
1. Read this README for the template
2. Look at `writing_style_asbe.yaml` for a complete example
3. Consult `asbe_axioms.md` for the theoretical foundation

---

## The 5 ASBE Axioms (Summary)

| Axiom | Name | One-liner |
|-------|------|-----------|
| A1 | Dual Expression | Every rule needs natural + formal |
| A2 | Example Grounding | Every rule needs violation + compliant examples |
| A3 | Hierarchical Derivation | Rules form a DAG from axioms |
| A4 | Minimal Axiom Set | Axioms are independent, consistent, sufficient |
| A5 | Semantic Equivalence | Natural and formal must mean the same thing |

---

## Applications

ASBE can axiomatize:
- Writing style guides (APA, technical docs)
- Code review standards
- Design principles
- Assessment rubrics
- Any domain needing precise, teachable rules

---

## Related Work

- **Specification by Example** (Gojko Adzic, 2011)
- **Design by Contract** (Bertrand Meyer, Eiffel)
- **Algebraic Specification** (ADJ Group, 1970s)
- **Property-Based Testing** (QuickCheck, 1999)

---

## Meta-Principles (Summary)

| Principle | Name | One-liner |
|-----------|------|-----------|
| M1 | LLM Optimization | Structure for reliable LLM interpretation |
| M2 | Human Readability | Remain human-readable despite LLM optimization |
| M3 | Incremental Elaboration | Specifications can start minimal and grow |
| M4 | Dual Format Representation | YAML for structure + Markdown for derivation |

---

*Created: 2024-12-30 | Updated: 2026-01-01 | Maintainer: Che Cheng*
