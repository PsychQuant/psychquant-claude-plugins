# ASBE Core Axioms

**公理化範例規範的核心公理**

This document defines the foundational axioms of ASBE itself—a meta-level axiomatization of how to create LLM-friendly specifications.

---

## Meta-Language Declaration

This document uses **semi-formal mathematical notation** as its meta-language:

| Component | Description |
|-----------|-------------|
| **First-order logic** | ∀ (for all), ∃ (exists), → (implies), ∧ (and), ∨ (or), ¬ (not) |
| **Set theory** | ∈ (element of), ⊆ (subset), \|...\| (cardinality), ∅ (empty set) |
| **Domain-specific predicates** | `natural(R)`, `formal(R)`, `violations(R)` — defined by convention |
| **Natural language glosses** | Prose explanations accompanying formal statements |

### What This Is NOT

- ❌ **Not machine-verifiable**: Cannot be checked by Coq, Lean, or Isabelle
- ❌ **Not ZFC set theory**: Does not derive from formal set-theoretic axioms
- ❌ **Not type theory**: No dependent types or proof terms

### Why This Choice

| Goal | Formal System | Semi-Formal (Chosen) |
|------|---------------|----------------------|
| Human readability | ★★☆☆☆ | ★★★★★ |
| LLM interpretability | ★★★☆☆ | ★★★★★ |
| Theorem proving | ★★★★★ | ★☆☆☆☆ |
| Practical usability | ★★☆☆☆ | ★★★★★ |

ASBE prioritizes **communication over verification**. The goal is human + LLM comprehension, not mechanical theorem proving.

### Bootstrapping

For a self-referential version where ASBE axioms are expressed in ASBE format itself, see:
→ [`asbe_axioms_bootstrapped.yaml`](./asbe_axioms_bootstrapped.yaml)

---

## Primitive Terms

Before stating axioms, we define primitive (undefined) terms:

| Term | Intuition |
|------|-----------|
| `Rule` | A normative statement prescribing behavior |
| `Example` | A concrete instance demonstrating a rule |
| `Reader` | An agent (human or LLM) interpreting a specification |
| `Understanding` | Successful transfer of intended meaning |

---

## Axioms

### A1. Dual Expression Axiom (雙層表達公理)

```
Every rule R in an ASBE specification must have both:
  (1) A natural language expression: natural(R)
  (2) A formal expression: formal(R)

Formally:
  ∀R ∈ Rule, ∃ natural(R) ∧ ∃ formal(R)
```

**Rationale**: Natural language provides accessibility; formal notation provides precision. Neither alone suffices.

### A2. Example Grounding Axiom (範例錨定公理)

```
Every rule R must be accompanied by at least one violation example
and at least one compliant example.

Formally:
  ∀R ∈ Rule, |violations(R)| ≥ 1 ∧ |compliant(R)| ≥ 1
```

**Rationale**: Abstract rules are insufficient for reliable interpretation. Concrete examples anchor understanding.

### A3. Hierarchical Derivation Axiom (層級推導公理)

```
Rules in an ASBE specification form a directed acyclic graph (DAG) where:
  - Axioms are roots (no incoming edges)
  - Theorems derive from axioms
  - Corollaries derive from theorems
  - Operational rules derive from any of the above

Formally:
  ∀R ∈ Rule, R.type ∈ {axiom, theorem, corollary, rule}
  ∀R where R.type ≠ axiom, ∃ parent(R) where level(parent(R)) < level(R)
```

**Rationale**: Traceability ensures coherence and enables verification of rule consistency.

### A4. Minimal Axiom Set Axiom (最小公理集公理)

```
The set of axioms A should be:
  (1) Independent: No axiom is derivable from others
  (2) Consistent: No contradictions exist
  (3) Sufficient: All domain rules can be derived

Formally:
  ∀a ∈ A, a ∉ Closure(A \ {a})  // Independence
  ¬∃R such that R ∧ ¬R ∈ Closure(A)  // Consistency
```

**Rationale**: Minimality prevents redundancy and clarifies the true foundations.

### A5. Semantic Equivalence Axiom (語意等價公理)

```
The natural language and formal expressions of a rule must be
semantically equivalent.

Formally:
  ∀R ∈ Rule, Meaning(natural(R)) ≡ Meaning(formal(R))
```

**Rationale**: The two layers must express the same rule, not different rules.

---

## Derived Theorems

### T1. Counterexample Sufficiency Theorem

```
From A2:
A single well-chosen violation example can disambiguate a rule
more effectively than additional natural language elaboration.

Proof sketch:
  By A2, violations(R) anchors the boundary of acceptable behavior.
  Examples operate in the same domain as actual use cases.
  Natural language operates in a meta-domain requiring interpretation.
  ∴ Examples reduce interpretation variance more efficiently.
```

### T2. Formal-Natural Complementarity Theorem

```
From A1 and A5:
When natural(R) is ambiguous, formal(R) resolves the ambiguity.
When formal(R) is opaque, natural(R) provides intuition.

Corollary: Readers with different backgrounds can enter understanding
through different layers.
```

### T3. Derivation Chain Verification Theorem

```
From A3 and A4:
Any rule R can be verified by tracing its derivation chain back to axioms.

Formally:
  ∀R ∈ Rule, ∃ path P = [a₁, ..., aₙ, R] where a₁ ∈ Axioms
  Validity(R) ⟺ ∀ step in P is sound
```

---

## Meta-Principles

### M1. LLM Optimization Principle

```
ASBE specifications should be structured for reliable LLM interpretation:
  - Use consistent YAML/JSON structure
  - Avoid ambiguous references
  - Provide explicit field names
  - Include type annotations where applicable
```

### M2. Human Readability Principle

```
Despite LLM optimization, ASBE specifications must remain
human-readable and human-writable:
  - Use meaningful identifiers
  - Include prose rationales
  - Maintain logical ordering
```

### M3. Incremental Elaboration Principle

```
An ASBE specification can start minimal and grow:
  - Begin with core axioms
  - Add theorems as patterns emerge
  - Expand examples as edge cases are discovered
  - The specification evolves while remaining consistent
```

### M4. Dual Format Representation Principle (雙格式表達原則)

```
Complex specifications benefit from maintaining two parallel formats:
  (1) Structured format (YAML/JSON): Skeleton/index layer
  (2) Prose format (Markdown): Flesh/derivation layer

Formally:
  Spec = (Spec_structured, Spec_prose)
  where:
    Spec_structured ⊇ {all_rule_ids, formal_statements, hierarchy}
    Spec_prose ⊇ {derivations, diagrams, examples_in_context, rationales}
```

**Rationale**: Each format serves distinct cognitive purposes:

| Format | Strengths | Use Cases |
|--------|-----------|-----------|
| **YAML** | Quick indexing, machine-parseable, structural overview | "What rules exist?", code integration |
| **Markdown** | Visual diagrams, narrative flow, contextual explanation | "Why this rule?", learning, edge cases |

**Synchronization Requirement**:
```
∀ axiom a: a ∈ Spec_structured ⟺ a ∈ Spec_prose
Updates to one format must propagate to the other.
```

**Example from Weight Control Axiomatization**:
```
weight_control_axioms.yaml    ← Structure: "mass_conservation: ΔW = Σin - Σout"
complete_molecular_tracking.md ← Prose: Full derivation + ASCII weight curves + edge cases
```

---

## Revision History

| Date | Change |
|------|--------|
| 2024-12-30 | Initial axiom set (A1-A5, T1-T3, M1-M3) |
| 2024-12-30 | Added Meta-Language Declaration; created bootstrapped version |
| 2026-01-01 | Added M4: Dual Format Representation Principle (雙格式表達原則) |
