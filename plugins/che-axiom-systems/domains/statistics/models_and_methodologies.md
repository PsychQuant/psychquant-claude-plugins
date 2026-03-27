# Models and Methodologies in Data Science

## Statistical Models

### Linear Models
- **Formulation**: y = Xβ + ε where ε ~ N(0, σ²I)
- **Estimation**: β̂ = (X'X)⁻¹X'y (Ordinary Least Squares)
- **Assumptions**:
  - Linearity: E[y|X] = Xβ
  - Independence: cov(εᵢ, εⱼ) = 0 for i ≠ j
  - Homoskedasticity: var(εᵢ) = σ² for all i
  - Normality: εᵢ ~ N(0, σ²)
- **Extensions**:
  - Generalized Linear Models: g(E[y|X]) = Xβ
  - Mixed Effects Models: y = Xβ + Zu + ε
  - Regularized Linear Models: β̂ = argmin ∥y - Xβ∥² + λJ(β)

### Probabilistic Graphical Models
- **Bayesian Networks**:
  - Factorization: P(X₁,...,Xₙ) = ∏ᵢ P(Xᵢ|Pa(Xᵢ))
  - Representation: Directed acyclic graph (DAG)
  - Inference: P(Xᵢ|E) where E is evidence
- **Markov Random Fields**:
  - Factorization: P(X) = (1/Z) ∏ᵏ ψₖ(Cₖ)
  - Representation: Undirected graph
  - Applications: Image analysis, spatial statistics
- **Hidden Markov Models**:
  - Components: Hidden states, observations, transition probabilities
  - Algorithms: Forward-backward, Viterbi, Baum-Welch

### Time Series Models
- **ARIMA(p,d,q)**:
  - AR(p): Autoregressive component
  - I(d): Integration (differencing)
  - MA(q): Moving average component
  - Formulation: (1-∑ᵖᵢ₌₁ φᵢLⁱ)(1-L)ᵈXₜ = (1+∑ᵍⱼ₌₁ θⱼLʲ)εₜ
- **State Space Models**:
  - State equation: xₜ = Fxₜ₋₁ + wₜ
  - Observation equation: yₜ = Hxₜ + vₜ
  - Filtering: Kalman filter, particle filter
- **Spectral Analysis**:
  - Fourier decomposition: Xₜ = ∑ᵏ (aₖcos(λₖt) + bₖsin(λₖt))
  - Periodogram: I(λ) = (1/2πn)|∑ₜ Xₜe⁻ⁱᵗλ|²

## Machine Learning Models

### Supervised Learning
- **Decision Trees**:
  - Split criterion: Information gain, Gini impurity
  - I(S,A) = H(S) - ∑ᵥ |Sᵥ|/|S| H(Sᵥ)
  - Pruning methods: Cost-complexity, reduced error
- **Support Vector Machines**:
  - Linear SVM: min ∥w∥² s.t. yᵢ(w·xᵢ+b) ≥ 1
  - Kernel trick: K(x,y) = ⟨φ(x),φ(y)⟩
  - Common kernels: Polynomial, RBF, sigmoid
- **Neural Networks**:
  - Activation functions: σ(z) = 1/(1+e⁻ᶻ), tanh(z), ReLU(z) = max(0,z)
  - Backpropagation: δⁱ = ((wⁱ⁺¹)ᵀδⁱ⁺¹) ⊙ σ'(zⁱ)
  - Architectures: CNN, RNN, Transformer

### Unsupervised Learning
- **Clustering**:
  - K-means: min ∑ᵏⱼ₌₁ ∑ᵢ∈Sⱼ ∥xᵢ - μⱼ∥²
  - Hierarchical: Linkage methods (single, complete, average)
  - Density-based: DBSCAN, OPTICS
- **Dimensionality Reduction**:
  - PCA: Maximize variance, eigendecomposition of covariance matrix
  - t-SNE: Minimize KL divergence between similarity distributions
  - Autoencoders: min ∥x - g(f(x))∥²
- **Density Estimation**:
  - Kernel Density: f̂(x) = (1/nh) ∑ᵢ K((x-xᵢ)/h)
  - Gaussian Mixture: f(x) = ∑ᵏⱼ₌₁ πⱼN(x|μⱼ,Σⱼ)
  - Normalizing Flows: z = f(x) where f is invertible

### Reinforcement Learning
- **Components**:
  - States (S), Actions (A), Rewards (R), Policy (π)
  - Value functions: V^π(s) = E[∑ₜ γᵗRₜ₊₁|S₀=s, π]
  - Q-function: Q^π(s,a) = E[∑ₜ γᵗRₜ₊₁|S₀=s, A₀=a, π]
- **Methods**:
  - Value-based: Q-learning, SARSA
  - Policy-based: REINFORCE, PPO
  - Actor-Critic: A2C, DDPG
  - Model-based: Dyna-Q, AlphaZero

## Methodological Frameworks

### Experimental Design
- **Randomized Controlled Trials**:
  - Design: Treatment assignment mechanism, randomization procedure
  - Analysis: Average Treatment Effect (ATE), Intention-to-Treat (ITT)
  - Extensions: Factorial designs, block randomization, crossover designs
- **A/B Testing**:
  - Statistical power: n = 2σ²(z₁₋ₐ/₂+z₁₋ᵦ)²/δ²
  - Multiple testing correction: Bonferroni, Benjamini-Hochberg
  - Sequential testing: α-spending functions, group sequential designs

### Causal Inference
- **Potential Outcomes Framework**:
  - Definition: Y(1) vs Y(0) (treatment vs control outcomes)
  - Fundamental problem: Cannot observe both for same unit
  - Causal effect: τ = E[Y(1) - Y(0)]
- **Structural Causal Models**:
  - Definition: Variables, structural equations, graphical model
  - do-calculus: Three rules for manipulating interventional distributions
  - Identification: Back-door criterion, front-door criterion
- **Quasi-Experimental Methods**:
  - Difference-in-differences: (Y_T,post - Y_T,pre) - (Y_C,post - Y_C,pre)
  - Regression discontinuity: Local treatment effect around threshold
  - Instrumental variables: β̂_IV = cov(y,z)/cov(x,z)

### Evaluation Frameworks
- **Performance Metrics**:
  - Classification: Accuracy, precision, recall, F1-score, AUC
  - Regression: MSE, MAE, R², MAPE
  - Ranking: NDCG, MRR, MAP
- **Validation Strategies**:
  - Cross-validation: k-fold, leave-one-out, stratified
  - Temporal validation: Forward chaining, sliding window
  - Nested validation for hyperparameter tuning
- **Model Comparison**:
  - Statistical tests: McNemar's test, paired t-test
  - Information criteria: AIC, BIC, DIC
  - Ensemble methods: Stacking, blending, model averaging

## Mathematical Foundations

### Optimization Techniques
- **Gradient Descent**:
  - Update rule: θ_t+1 = θ_t - η∇f(θ_t)
  - Variants: SGD, Mini-batch, Momentum, Adam
  - Convergence guarantees for convex functions
- **Convex Optimization**:
  - Conditions: f(tx + (1-t)y) ≤ tf(x) + (1-t)f(y)
  - Duality: min f₀(x) s.t. fᵢ(x) ≤ 0 ↔ max g(λ,ν)
  - Methods: Interior point, barrier methods, ADMM
- **Non-convex Optimization**:
  - Challenges: Local minima, saddle points
  - Approaches: Random restarts, simulated annealing
  - Recent advances: Normalized gradient descent, Langevin dynamics

### Information Theory
- **Entropy**: H(X) = -∑ₓ p(x)log p(x)
- **Kullback-Leibler Divergence**: D_KL(P∥Q) = ∑ₓ p(x)log(p(x)/q(x))
- **Mutual Information**: I(X;Y) = ∑ₓ∑ᵧ p(x,y)log(p(x,y)/(p(x)p(y)))
- **Applications**:
  - Feature selection: Maximize I(X;Y)
  - Clustering: Minimize H(C|X)
  - Compression: Huffman coding, arithmetic coding

### Computational Complexity
- **Time Complexity Classes**:
  - P: Polynomial time solvable
  - NP: Nondeterministic polynomial time
  - Reduction techniques for NP-completeness
- **Space Complexity**:
  - Memory requirements for algorithms
  - Trade-offs between time and space
- **Approximation Algorithms**:
  - ε-approximation schemes
  - Randomized approximation
  - Online algorithms and competitive analysis