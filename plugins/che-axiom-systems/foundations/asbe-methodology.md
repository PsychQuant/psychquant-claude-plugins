# ASBE Methodology — Axiomatic Specification by Example

公理化範例規範。Meta-level methodology for creating formal specifications optimized for both human understanding and LLM consumption.

## The 5 ASBE Axioms

### A1. Dual Expression (雙層表達公理)
Every rule must have both a natural language expression and a formal expression.
```
∀R ∈ Rule, ∃ natural(R) ∧ ∃ formal(R)
```

### A2. Example Grounding (範例錨定公理)
Every rule must be accompanied by at least one violation example and at least one compliant example.
```
∀R ∈ Rule, |violations(R)| ≥ 1 ∧ |compliant(R)| ≥ 1
```

### A3. Hierarchical Derivation (層級推導公理)
Rules form a directed acyclic graph (DAG): Axioms → Theorems → Corollaries → Rules.
```
∀R where R.type ≠ axiom, ∃ parent(R) where level(parent(R)) < level(R)
```

### A4. Minimal Axiom Set (最小公理集公理)
Axioms must be independent (not derivable from each other), consistent (no contradictions), and sufficient (all domain rules can be derived).
```
∀a ∈ A, a ∉ Closure(A \ {a})   // Independence
¬∃R such that R ∧ ¬R ∈ Closure(A)  // Consistency
```

### A5. Semantic Equivalence (語意等價公理)
The natural language and formal expressions of a rule must be semantically equivalent.
```
∀R ∈ Rule, Meaning(natural(R)) ≡ Meaning(formal(R))
```

## Derived Theorems

### T1. Counterexample Sufficiency
A single well-chosen violation example can disambiguate a rule more effectively than additional natural language elaboration.

### T2. Formal-Natural Complementarity
When natural(R) is ambiguous, formal(R) resolves it. When formal(R) is opaque, natural(R) provides intuition.

### T3. Derivation Chain Verification
Any rule can be verified by tracing its derivation chain back to axioms.

## Meta-Principles

### M1. LLM Optimization
Structure for reliable LLM interpretation: consistent YAML/JSON, explicit field names, no ambiguous references.

### M2. Human Readability
Despite LLM optimization, specifications must remain human-readable and human-writable.

### M3. Incremental Elaboration
Specifications can start minimal and grow while remaining consistent.

### M4. Dual Format Representation (雙格式表達原則)
Complex specifications benefit from two parallel formats:
- **YAML**: Skeleton/index layer — quick indexing, machine-parseable
- **Markdown**: Flesh/derivation layer — diagrams, narrative, contextual explanation

## ID Naming Convention

| Prefix | Type | Example |
|--------|------|---------|
| `A` | Axiom | `A1_clarity`, `A2_unity` |
| `T` | Theorem | `T1_known_new` |
| `C` | Corollary | `C1_emphasis` |
| `R` | Rule | `R1_paragraph_length` |

## Design Philosophy

> Communication over verification.

ASBE prioritizes human + LLM comprehension, not mechanical theorem proving. It uses semi-formal mathematical notation — not machine-verifiable (Coq/Lean), but maximally readable.
