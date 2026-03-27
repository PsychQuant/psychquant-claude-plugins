# ASBE Definitions

**公理化範例規範的定義**

This document provides formal definitions of terms used throughout ASBE.

---

## Structural Definitions

### Definition 1: ASBE Specification

An **ASBE Specification** is a tuple S = (A, T, C, R, E) where:
- A = set of axioms
- T = set of theorems
- C = set of corollaries
- R = set of operational rules
- E = set of examples

Such that all elements satisfy the ASBE axioms A1-A5.

### Definition 2: Rule

A **Rule** in ASBE is a tuple r = (id, type, natural, formal, violations, compliant, derives_from) where:

| Field | Type | Description |
|-------|------|-------------|
| `id` | string | Unique identifier (e.g., "A1", "T3", "R12") |
| `type` | enum | One of: axiom, theorem, corollary, rule |
| `natural` | string | Natural language statement |
| `formal` | string | Formal notation (logic, set theory, etc.) |
| `violations` | list[Example] | Examples that violate the rule |
| `compliant` | list[Example] | Examples that satisfy the rule |
| `derives_from` | list[id] | Parent rules (empty for axioms) |

### Definition 3: Example

An **Example** in ASBE is a tuple e = (description, content, context?) where:

| Field | Type | Description |
|-------|------|-------------|
| `description` | string | What this example demonstrates |
| `content` | string | The actual example content |
| `context` | string? | Optional situational context |

### Definition 4: Derivation

A **Derivation** is a sequence [r₁, r₂, ..., rₙ] where:
- r₁ is an axiom
- Each rᵢ₊₁ is derivable from {r₁, ..., rᵢ}
- rₙ is the target rule

---

## Type Hierarchy

```
Rule
├── Axiom       (level 0, no derives_from)
├── Theorem     (level 1, derives from axioms)
├── Corollary   (level 2, derives from theorems)
└── Rule        (level 3, derives from any above)
```

### Definition 5: Level Function

```
level(r) =
  0   if r.type = axiom
  1   if r.type = theorem
  2   if r.type = corollary
  3   if r.type = rule
```

### Definition 6: Closure

The **Closure** of a rule set R, denoted Closure(R), is the smallest set containing R and all rules derivable from R through valid inference.

---

## Quality Metrics

### Definition 7: Example Coverage

For a rule r, **Example Coverage** is defined as:

```
coverage(r) = |distinct_scenarios(violations(r) ∪ compliant(r))| / |possible_scenarios|
```

Higher coverage indicates more robust specification.

### Definition 8: Derivation Depth

The **Derivation Depth** of a rule r is the length of the longest path from any axiom to r:

```
depth(r) = max{ |path| : path is a derivation ending in r }
```

### Definition 9: Specification Completeness

A specification S is **Complete** with respect to domain D if:

```
∀ situation s ∈ D, ∃ r ∈ S such that r determines the correct behavior for s
```

---

## Notation Conventions

| Symbol | Meaning |
|--------|---------|
| ∀ | For all |
| ∃ | There exists |
| ∈ | Element of |
| ⊆ | Subset of |
| ∧ | Logical and |
| ∨ | Logical or |
| ¬ | Logical not |
| → | Implies |
| ≡ | Semantically equivalent |
| \| ... \| | Cardinality (size of set) |

---

## Revision History

| Date | Change |
|------|--------|
| 2024-12-30 | Initial definitions (D1-D9) |
