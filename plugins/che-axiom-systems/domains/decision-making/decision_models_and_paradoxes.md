# Decision Models and Paradoxes

## Classical Decision Models

### Expected Value Model
- **Formulation**: Choose action a to maximize EV(a) = ∑s∈S P(s)v(a,s)
- **Assumptions**: Risk neutrality, objective probabilities
- **Applications**: Simple gambling problems, basic insurance decisions
- **Limitations**: Fails to account for risk attitudes, leads to St. Petersburg paradox

### Expected Utility Model
- **Formulation**: Choose action a to maximize EU(a) = ∑s∈S P(s)u(v(a,s))
- **Assumptions**: von Neumann-Morgenstern axioms (completeness, transitivity, continuity, independence)
- **Applications**: Finance, insurance, public policy
- **Limitations**: Empirical violations in Allais and Ellsberg paradoxes

### Subjective Expected Utility Model
- **Formulation**: Choose action a to maximize SEU(a) = ∑s∈S π(s)u(v(a,s))
- **Assumptions**: Savage axioms (adds subjective probabilities π)
- **Applications**: Decisions with unique events, personal decision making
- **Limitations**: Difficulty in eliciting true subjective probabilities

## Behavioral Decision Models

### Prospect Theory
- **Formulation**: V(a) = ∑s∈S w(P(s))v(x(a,s))
- **Key Elements**:
  - Reference-dependent value function v: steep for losses (loss aversion)
  - Probability weighting function w: overweights small probabilities, underweights large ones
  - Coding outcomes as gains or losses relative to reference point
- **Applications**: Consumer behavior, financial decisions, risk communication

### Cumulative Prospect Theory
- **Formulation**: V(a) = ∑i w+(P(xi≥x))v(xi) - ∑i w-(P(xi≤x))v(xi)
- **Key Elements**: 
  - Applies probability weighting to cumulative probabilities
  - Allows different weighting functions for gains and losses
- **Applications**: Financial markets, insurance, gambling

### Regret Theory
- **Formulation**: Choose a to maximize ∑s P(s)Q(v(a,s), v(a*,s))
- **Key Elements**:
  - Q measures satisfaction accounting for regret
  - Compare actual outcome to what could have been obtained with best alternative a*
- **Applications**: Explains choice patterns in Allais paradox, auction behavior

## Mathematical Representation

### Utility Function Properties
1. **Risk Aversion**: u''(x) < 0 (concave function)
   - Arrow-Pratt measure of absolute risk aversion: r_A(x) = -u''(x)/u'(x)
   - Relative risk aversion: r_R(x) = x·r_A(x)

2. **Risk Seeking**: u''(x) > 0 (convex function)

3. **Risk Neutrality**: u''(x) = 0 (linear function)

### Common Utility Functions
1. **Exponential**: u(x) = -e^(-αx) where α > 0
   - Constant absolute risk aversion: r_A(x) = α

2. **Power (CRRA)**: u(x) = (x^(1-ρ) - 1)/(1-ρ) where ρ ≠ 1
   - Constant relative risk aversion: r_R(x) = ρ
   - Includes logarithmic utility when ρ = 1: u(x) = ln(x)

3. **Prospect Theory Value Function**: 
   - v(x) = x^α for x ≥ 0
   - v(x) = -λ(-x)^β for x < 0
   - Where α, β ∈ (0,1) and λ > 1 (loss aversion parameter)

## Famous Paradoxes

### St. Petersburg Paradox
- **Setup**: Toss a fair coin until heads appears; payoff is 2^n where n is the number of tosses
- **Expected Value**: ∑n=1 to ∞ (1/2)^n · 2^n = ∑n=1 to ∞ 1 = ∞
- **Paradox**: People are unwilling to pay large amounts despite infinite expected value
- **Resolution**: Bounded utility function (diminishing marginal utility)

### Allais Paradox
- **Setup**: Two choice problems that reveal inconsistency in preferences
  - Problem 1: Choose between
    - Option A: 100% chance of $1M
    - Option B: 89% chance of $1M, 10% chance of $5M, 1% chance of $0
  - Problem 2: Choose between
    - Option C: 11% chance of $1M, 89% chance of $0
    - Option D: 10% chance of $5M, 90% chance of $0
- **Paradox**: People typically prefer A>B but D>C, violating independence axiom
- **Resolution**: Probability weighting, certainty effect (Prospect Theory)

### Ellsberg Paradox
- **Setup**: Urn with 30 red balls and 60 balls that are either black or yellow
  - Gamble A: Win $100 if red ball is drawn
  - Gamble B: Win $100 if black ball is drawn
  - Gamble C: Win $100 if red or yellow ball is drawn
  - Gamble D: Win $100 if black or yellow ball is drawn
- **Paradox**: People typically prefer A>B and D>C, violating subjective expected utility theory
- **Resolution**: Ambiguity aversion, distinguishing risk from uncertainty

### Newcomb's Paradox
- **Setup**: 
  - Super-intelligent being predicts your choice
  - Box A: Always contains $1,000
  - Box B: Contains $1M if being predicts you take only B, otherwise empty
  - You can take both boxes or just Box B
- **Paradox**: 
  - Dominance principle suggests taking both boxes
  - Expected utility may suggest taking only Box B
- **Resolution**: Depends on assumptions about causality and prediction

## Advanced Topics

### Multi-Attribute Utility Theory
- **Formulation**: U(x) = f(u1(x1), u2(x2), ..., un(xn))
- **Conditions for Additive Form**: U(x) = ∑i wi·ui(xi)
  - Mutual preferential independence of attributes
  - ∑i wi = 1, wi ≥ 0

### Intertemporal Choice
- **Discounted Utility Model**: U(c0, c1, ..., cT) = ∑t=0 to T δ^t·u(ct)
- **Hyperbolic Discounting**: Present bias with D(t) = (1+αt)^(-β/α)
- **Applications**: Saving, investment, addiction, procrastination

### Decisions under Ambiguity
- **Multiple-Priors Model**: V(a) = minπ∈Π Eπ[u(a)]
- **α-Maxmin Model**: V(a) = α·minπ∈Π Eπ[u(a)] + (1-α)·maxπ∈Π Eπ[u(a)]
- **Applications**: Climate change, novel technologies, rare events

### Sequential Decision Making
- **Dynamic Programming Principle**: 
  - V(s) = max_a [r(s,a) + γ·E[V(s')]]
- **Applications**: Resource allocation, optimal stopping, reinforcement learning