# Acquisition Models and Phenomena

## Formal Models of Language Acquisition

### Parameter Setting Model
- **Key Concept**: Language acquisition as setting values for a finite set of parameters
- **Formalization**: L = G(P₁, P₂, ..., Pₙ) where P₁ ∈ {v₁, v₂, ...}
  - L: acquired language
  - G: universal grammar framework
  - P₁...Pₙ: parameters with finite possible values
- **Example**: Head parameter (head-initial vs. head-final)
- **Limitations**: Oversimplifies the learning process; difficult to account for gradual acquisition

### Bayesian Model
- **Key Concept**: Learning as hypothesis updating via Bayes' rule
- **Formalization**: P(h|d) = P(d|h)P(h)/P(d)
  - P(h|d): posterior probability of grammar h given data d
  - P(d|h): likelihood of observing data d given grammar h
  - P(h): prior probability of grammar h
  - P(d): probability of data d
- **Applications**: Word learning, syntactic categorization, phonological rule learning
- **Strengths**: Accounts for prior knowledge and gradual belief updating

### Connectionist Model
- **Key Concept**: Learning as adjustment of connection weights in neural networks
- **Formalization**: Learning rule: Δwᵢⱼ = η·δⱼ·aᵢ
  - wᵢⱼ: connection weight from unit i to unit j
  - η: learning rate
  - δⱼ: error signal at unit j
  - aᵢ: activation of unit i
- **Applications**: Past tense acquisition, phonological development, semantic networks
- **Strengths**: Captures statistical learning and emergent regularization

### Competition Model
- **Key Concept**: Acquisition as competition between multiple cues to interpretation
- **Formalization**: Strength(interpretation) = ∑ᵢ wᵢ·cueᵢ
  - wᵢ: weight of cue i
  - cueᵢ: presence/absence of cue i
- **Applications**: Cross-linguistic differences in sentence interpretation
- **Strengths**: Explains typological variation in acquisition patterns

### Usage-Based Model
- **Key Concept**: Frequency-sensitive, item-based learning leading to abstraction
- **Formalization**: P(construction|context) = f(construction, context) / f(context)
  - f(): frequency function
- **Applications**: Constructional development, vocabulary acquisition, pragmatic competence
- **Strengths**: Accounts for early conservatism and gradual generalization

## Acquisition Phenomena and Regularities

### U-Shaped Learning
- **Pattern**: Initial correct usage → over-regularization errors → correct usage
- **Example**: English past tense: went → goed → went
- **Explanation**: Transition from memorized forms to rule application to exception learning
- **Formalization**: Performance = memorization + rule application - interference

### Critical Period Effects
- **Pattern**: Age-related decline in acquisition outcomes
- **Formalization**: Proficiency = f(age of acquisition)
  - Where f is a non-linear function with inflection points
- **Variables that moderate effect**:
  - Linguistic domain (phonology most affected)
  - Input quantity and quality
  - Individual factors (motivation, aptitude)

### Frequency Effects
- **Type frequency**: Number of distinct items in a pattern
- **Token frequency**: Number of occurrences of a specific item
- **Mathematical relationship**: Acquisition rate ∝ log(frequency)
- **Manifestations**:
  - High-frequency items acquired earlier
  - High type-frequency patterns generalize more readily
  - Power law of learning: Learning rate = a·N^b
    - N: number of exposures
    - a, b: constants

### Cross-Linguistic Transfer
- **Positive transfer**: facilitation when L1 and L2 features align
- **Negative transfer**: interference when L1 and L2 features conflict
- **Formalization**: Transfer = f(typological distance, perceived similarity, proficiency)
- **Transfer hierarchy**: Lexicon > phonology > syntax > morphology

### Developmental Sequences
- **Morpheme acquisition orders**: Consistent ordering of grammatical morphemes
  - Example: -ing > plural -s > articles > past -ed (in English)
- **Negation development**: No/not → aux+not → complex forms
- **Question formation**: Rising intonation → fronting → inversion → embedded questions
- **Explanatory factors**:
  - Perceptual salience
  - Semantic complexity
  - Frequency
  - Functional load

## Mathematical Representations of Learning

### Error-Based Learning Models
- **Delta rule**: Δwᵢ = α(t - o)xᵢ
  - wᵢ: weight on input i
  - α: learning rate
  - t: target output
  - o: actual output
  - xᵢ: input value
- **Applications**: Morphological paradigm learning, phonological rule acquisition

### Information-Theoretic Approach
- **Minimum Description Length**: Grammar G* = argmin G{L(G) + L(D|G)}
  - L(G): length of grammar description
  - L(D|G): length of data description using grammar
- **Surprisal**: S(word|context) = -log₂ P(word|context)
  - Predicts processing difficulty and learning attention

### Rational Analysis
- **Optimal inference**: Learner selects hypothesis h* that maximizes posterior probability
  - h* = argmax h P(h|d) = argmax h P(d|h)P(h)
- **Sampling assumption**: Learners approximate Bayesian inference through sampling
  - P(response = h) ∝ P(h|d)

### Reinforcement Learning
- **Q-learning**: Q(s,a) ← Q(s,a) + α[r + γ·max a' Q(s',a') - Q(s,a)]
  - s: state, a: action, r: reward, α: learning rate, γ: discount factor
- **Applications**: Word learning through social feedback, dialogue strategies

## Special Topics in Language Acquisition

### Statistical Learning Mechanisms
- **Transitional probabilities**: P(Y|X) = P(X,Y)/P(X)
  - Used in word segmentation, syntactic parsing
- **Mutual information**: MI(X;Y) = ∑x∑y P(x,y)log[P(x,y)/(P(x)P(y))]
  - Used in collocation learning, semantic association

### Bilingual Acquisition
- **Activation threshold hypothesis**: θL = f(recency, frequency of use)
  - Where θL is the activation threshold for language L
- **Code-switching models**: P(switch|context) = f(proficiency, topic, interlocutor)
- **Interdependence hypothesis**: Common underlying proficiency across languages

### Atypical Language Acquisition
- **Specific Language Impairment**: Characterized by deficits in grammatical morphology
  - Surface hypothesis: ∫(perceptual_salience)dt < threshold
- **Williams Syndrome**: Enhanced formulaic language despite cognitive impairments
- **Autism Spectrum Disorders**: Pragmatic deficits with variable structural language

### Social Factors in Acquisition
- **Joint attention**: Acquisition rate ∝ proportion of time in joint attention
- **Child-directed speech**: Simplified register with exaggerated prosody
  - Facilitates segmentation and pattern detection
- **Socioeconomic status**: Vocabulary size ≈ a·(words heard per hour)^b + c