# Axioms of Logic

## Axioms of Equality

### Axiom 1: Transitivity
Things which equal the same thing also equal one another.
- Formal notation: If a = c and b = c, then a = b
- This establishes equality as a transitive relation

### Axiom 2: Congruence with Addition
If equals are added to equals, then the wholes are equal.
- Formal notation: If a = b and c = d, then a + c = b + d
- This preserves equality under the operation of addition

### Axiom 3: Congruence with Subtraction
If equals are subtracted from equals, then the remainders are equal.
- Formal notation: If a = b and c = d, then a - c = b - d
- This preserves equality under the operation of subtraction

### Axiom 4: Identity of Coincident Objects
Things which coincide with one another equal one another.
- Formal notation: If a and b occupy exactly the same space/position, then a = b
- This links physical coincidence with logical equality

## Axioms of Magnitude

### Axiom 5: Part-Whole Relation
The whole is greater than the part.
- Formal notation: If a is a proper part of b, then b > a
- This establishes the foundational ordering relation between parts and wholes

## Propositional Logic Axioms

### Axiom P1: Law of Identity
Every proposition implies itself.
- Formal notation: P → P
- This establishes that any statement is equivalent to itself

### Axiom P2: Law of Non-Contradiction
No proposition can be both true and false.
- Formal notation: ¬(P ∧ ¬P)
- This prevents logical contradictions

### Axiom P3: Law of Excluded Middle
Every proposition is either true or false.
- Formal notation: P ∨ ¬P
- This establishes the binary nature of classical logic

### Axiom P4: Modus Ponens
If P implies Q, and P is true, then Q is true.
- Formal notation: ((P → Q) ∧ P) → Q
- This provides the fundamental rule of inference

## Predicate Logic Axioms

### Axiom Q1: Universal Instantiation
If a property applies to everything, it applies to any specific thing.
- Formal notation: ∀x P(x) → P(a)
- This connects universal statements to particular instances

### Axiom Q2: Existential Generalization
If a property applies to some specific thing, then there exists something with that property.
- Formal notation: P(a) → ∃x P(x)
- This allows inferring existence from particular instances

### Axiom Q3: Quantifier Negation
The negation of "all" is "some not" and the negation of "some" is "none".
- Formal notation: ¬∀x P(x) ↔ ∃x ¬P(x) and ¬∃x P(x) ↔ ∀x ¬P(x)
- This establishes the relationship between universal and existential quantifiers under negation