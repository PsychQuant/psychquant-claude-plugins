# Axiomatization of Decision Making

## Core Axioms

### Axiom D1: Preference Structure
- A decision maker has a preference relation ≿ over a set of alternatives X
- This relation is complete (∀x,y∈X: x≿y or y≿x) and transitive (∀x,y,z∈X: if x≿y and y≿z, then x≿z)
- The strict preference relation ≻ and indifference relation ∼ are derived from ≿

### Axiom D2: Utility Representation
- If preferences satisfy certain rationality conditions, there exists a utility function u: X → ℝ such that x≿y if and only if u(x) ≥ u(y)
- This function represents the decision maker's preferences and is unique up to positive monotonic transformations

### Axiom D3: Uncertainty
- Decision problems under uncertainty involve a set S of possible states of the world
- The decision maker may have beliefs about the likelihood of these states, represented by a probability measure P on S
- The decision maker chooses among acts f: S → X, which are functions from states to consequences

### Axiom D4: Expected Utility
- Under certain axioms of rational choice (completeness, transitivity, continuity, independence), the utility of an act f is given by its expected utility: E[u(f)] = ∑s∈S P(s)u(f(s))
- Decision makers choose acts to maximize expected utility

### Axiom D5: Information
- Information is represented as a partition or σ-algebra of the state space S
- More refined partitions represent more informative situations
- The value of information is the improvement in expected utility that can be achieved by making decisions based on that information

## Derived Principles

### P1: Rationality Principle
- Decision makers act to maximize their expected utility given their beliefs and preferences
- Choices that violate utility maximization are considered irrational

### P2: Risk Attitude Principle
- The shape of a utility function reflects attitudes toward risk
- Concave utility functions indicate risk aversion
- Convex utility functions indicate risk seeking
- Linear utility functions indicate risk neutrality

### P3: Value of Information Principle
- Information has positive value if and only if it can change optimal decisions
- The maximum price a decision maker should pay for information is the expected improvement in utility it provides

### P4: Preference Revelation Principle
- A decision maker's preferences can be inferred from their observed choices
- If choices satisfy certain consistency conditions, they can be rationalized as maximizing some utility function

### P5: Limited Rationality Principle
- Human decision makers have cognitive limitations that prevent perfect utility maximization
- These limitations include bounded computational capacity, limited attention, and constraints on information processing

## Fundamental Theorems

### Theorem D1: Utility Representation Theorem
- If a preference relation ≿ on X is complete, transitive, and continuous, then there exists a continuous utility function u: X → ℝ that represents ≿

### Theorem D2: Expected Utility Theorem
- If preferences over acts satisfy the von Neumann-Morgenstern axioms (completeness, transitivity, continuity, independence), then they can be represented by the expected utility of the acts

### Theorem D3: Bayesian Decision Theory
- Optimal decision making under uncertainty involves:
  - Forming prior beliefs P(s) about states
  - Updating beliefs to P(s|e) upon observing evidence e using Bayes' rule
  - Choosing the act that maximizes expected utility with respect to the posterior beliefs

### Theorem D4: Value of Perfect Information
- The expected value of perfect information (EVPI) is the difference between the expected utility with perfect information and the expected utility without it
- EVPI = E[maxa u(a,S)] - maxa E[u(a,S)]

### Theorem D5: Prospect Theory
- Actual human decisions systematically deviate from expected utility theory
- These deviations can be captured by:
  - Reference-dependent value functions
  - Nonlinear probability weighting
  - Loss aversion

## Practical Applications

### Decision Analysis
- Formal methods for structuring and analyzing complex decision problems
- Includes influence diagrams, decision trees, and multi-attribute utility theory

### Game Theory
- Analysis of strategic interactions where outcomes depend on the choices of multiple decision makers
- Includes concepts like Nash equilibrium, strategic dominance, and backward induction

### Behavioral Economics
- Study of how psychological, cognitive, and emotional factors influence economic decisions
- Includes models of limited attention, cognitive biases, and social preferences

### Artificial Intelligence
- Development of algorithms for automated decision making
- Includes approaches based on reinforcement learning, planning, and decision-theoretic reasoning

## Limitations and Extensions

### Limitations
- The axioms assume idealized decision makers with unlimited computational capacity
- Real decision makers often violate the axioms in systematic ways
- The framework struggles with situations involving deep uncertainty or ambiguity

### Extensions
- Bounded rationality models that account for computational limitations
- Non-expected utility theories that relax the independence axiom
- Multi-objective decision making with non-comparable values
- Group decision making and social choice theory