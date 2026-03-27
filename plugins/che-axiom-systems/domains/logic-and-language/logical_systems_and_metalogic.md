# Logical Systems and Metalogic

## Classical Logical Systems

### Propositional Logic
- **Syntax**: Atomic propositions and logical connectives (∧, ∨, →, ¬)
- **Semantics**: Truth tables, valuations v: Prop → {T, F}
- **Proof System**: Axioms + Modus Ponens
- **Metatheorems**:
  - Soundness: If ⊢ φ then ⊨ φ
  - Completeness: If ⊨ φ then ⊢ φ
  - Decidability: There exists an algorithm to determine if ⊢ φ

### First-Order Logic
- **Syntax**: Adds quantifiers (∀, ∃) and predicates over individuals
- **Semantics**: Interpretations I = (D, I) with domain D and interpretation function I
- **Proof System**: Propositional axioms + quantifier axioms + equality axioms
- **Metatheorems**:
  - Soundness: If ⊢ φ then ⊨ φ
  - Completeness (Gödel): If ⊨ φ then ⊢ φ
  - Undecidability: No algorithm can determine if ⊢ φ
  - Löwenheim-Skolem: If a theory has an infinite model, it has models of every infinite cardinality

### Higher-Order Logic
- **Syntax**: Allows quantification over predicates and functions
- **Semantics**: Standard semantics vs. Henkin semantics
- **Limitations**:
  - Incompleteness under standard semantics
  - Non-axiomatizability
  - Loss of compactness and Löwenheim-Skolem properties

## Non-Classical Logical Systems

### Intuitionistic Logic
- **Key Difference**: Rejects Law of Excluded Middle (P ∨ ¬P)
- **Semantics**: Kripke models, topological models
- **Proof-theoretic Interpretation**: Proofs as constructions
- **Application**: Constructive mathematics, type theory, computer science

### Modal Logic
- **Extension**: Adds modal operators □ (necessity) and ◇ (possibility)
- **Semantics**: Kripke semantics with possible worlds and accessibility relations
- **Systems**:
  - K: Basic modal logic
  - T: Reflexive accessibility (□P → P)
  - S4: Transitive and reflexive accessibility
  - S5: Equivalence relation accessibility
- **Applications**: Philosophy, computer science (program verification, knowledge representation)

### Many-Valued Logic
- **Extension**: Multiple truth values beyond true/false
- **Examples**:
  - Three-valued logic: {True, False, Unknown}
  - Fuzzy logic: Truth values in [0,1]
- **Applications**: Handling vagueness, uncertainty, paradoxes

### Relevance Logic
- **Key Difference**: Requires relevance between antecedent and consequent in implications
- **Motivation**: Avoid paradoxes of material implication
- **Examples**: Systems R, E, T

## Formal Properties of Logical Systems

### Consistency
- **Weak Consistency**: Not all formulas are provable
- **Strong Consistency**: For no formula φ are both φ and ¬φ provable
- **Absolute Consistency**: The system has a model
- **Formal Definition**: A system S is consistent iff there exists a formula φ such that ⊬S φ

### Soundness
- **Definition**: If ⊢ φ then ⊨ φ (everything provable is valid)
- **Importance**: Ensures proofs only derive true statements
- **Verification**: Check that all axioms are valid and inference rules preserve validity

### Completeness
- **Weak Completeness**: If ⊨ φ then ⊢ φ (all valid formulas are provable)
- **Strong Completeness**: If Γ ⊨ φ then Γ ⊢ φ (all semantic consequences are derivable)
- **Gödel's Completeness Theorem**: First-order logic is strongly complete
- **Limitations**: Higher-order logic is incomplete under standard semantics

### Decidability
- **Definition**: There exists an effective procedure to determine if ⊢ φ
- **Examples**:
  - Propositional logic: Decidable (truth tables)
  - First-order logic: Undecidable (Church-Turing theorem)
  - Monadic predicate logic: Decidable
- **Semi-decidability**: Provable formulas can be effectively enumerated

### Expressiveness
- **Definability**: Which concepts can be expressed in the logical language
- **Limitations**: Löwenheim-Skolem theorems, Tarski's indefinability theorem
- **Extending Expressiveness**: Second-order quantifiers, infinitary logic, fixed-point operators

## Metalogical Results

### Gödel's Incompleteness Theorems
- **First Incompleteness Theorem**: Any consistent formal system S containing basic arithmetic contains statements that can neither be proved nor disproved within S
- **Second Incompleteness Theorem**: No consistent formal system containing basic arithmetic can prove its own consistency
- **Formal Statement**: If system S is consistent, then ConS is not provable in S
  - Where ConS is the statement "S is consistent"

### Tarski's Undefinability Theorem
- **Statement**: The truth predicate of a sufficiently expressive formal language cannot be defined within that language
- **Formal Version**: For any sufficiently expressive formal language L, there is no L-formula True(x) such that for all L-sentences φ: True(⌜φ⌝) ↔ φ
- **Consequence**: Truth is not expressible within the object language

### Löwenheim-Skolem Theorems
- **Downward L-S**: If a countable first-order theory has an infinite model, it has a countable model
- **Upward L-S**: If a theory has an infinite model, it has models of every infinite cardinality
- **Skolem's Paradox**: The apparent contradiction that set theory has a countable model despite proving the existence of uncountable sets

### Compactness Theorem
- **Statement**: A set of first-order sentences is satisfiable if and only if every finite subset is satisfiable
- **Consequence**: First-order logic cannot express certain finitary properties
- **Applications**: Nonstandard models, ultraproducts, transfer principles

## Applications to Language and Mathematics

### Formal Grammar and Language Theory
- **Chomsky Hierarchy**: Regular, context-free, context-sensitive, recursively enumerable languages
- **Relation to Logic**: Monadic second-order logic captures regular languages
- **Model Theory of Natural Language**: Formal semantics, Montague grammar

### Foundations of Mathematics
- **Logical Frameworks**:
  - Set theory (ZFC): Based on first-order logic with membership relation
  - Type theory: Based on higher-order logic with types
  - Category theory: Alternative foundation using categories
- **Formalization Projects**: Automated theorem proving, formal verification
- **Incompleteness Implications**: Limits of formal axiomatization, independence results