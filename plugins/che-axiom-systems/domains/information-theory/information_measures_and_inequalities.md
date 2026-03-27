# Information Measures and Inequalities

## Introduction

This document formalizes the key information measures and their relationships derived from the Axiomatization of Information Theory. These measures form the quantitative foundation for analyzing information in various contexts, while the inequalities establish fundamental limits and relationships that govern information processing systems.

## Basic Information Measures

### 1. Self-Information

Self-information quantifies the information content of a single event.

**Definition**: For an event $x$ with probability $P(x)$, the self-information is:
$$I(x) = -\log_b P(x)$$

**Properties**:
- $I(x) \geq 0$ (non-negativity)
- $I(x)$ approaches $\infty$ as $P(x)$ approaches 0
- $I(x) = 0$ when $P(x) = 1$ (certain events contain no information)
- For independent events $x$ and $y$: $I(x,y) = I(x) + I(y)$

### 2. Entropy

Entropy measures the average uncertainty or information content in a random variable.

**Definition**: For a discrete random variable $X$ with probability mass function $P(X)$:
$$H(X) = -\sum_{x \in \mathcal{X}} P(x) \log_b P(x) = \mathbb{E}[I(X)]$$

For a continuous random variable with probability density function $f(x)$:
$$h(X) = -\int_{-\infty}^{\infty} f(x) \log_b f(x) dx$$

**Properties**:
- $H(X) \geq 0$ (non-negativity)
- $H(X) \leq \log_b |\mathcal{X}|$ (maximality for uniform distribution)
- $H(X)$ is concave in the distribution $P(X)$
- $H(X,Y) \leq H(X) + H(Y)$ with equality if and only if $X$ and $Y$ are independent

### 3. Conditional Entropy

Conditional entropy measures the average uncertainty in one random variable given knowledge of another.

**Definition**: For random variables $X$ and $Y$:
$$H(X|Y) = -\sum_{x,y} P(x,y) \log_b P(x|y) = \sum_y P(y) H(X|Y=y)$$

**Properties**:
- $H(X|Y) \geq 0$ (non-negativity)
- $H(X|Y) \leq H(X)$ (conditioning reduces entropy)
- $H(X|Y) = H(X)$ if and only if $X$ and $Y$ are independent
- $H(X,Y) = H(X) + H(Y|X) = H(Y) + H(X|Y)$ (chain rule)

### 4. Mutual Information

Mutual information measures the amount of information shared between two random variables.

**Definition**: For random variables $X$ and $Y$:
$$I(X;Y) = \sum_{x,y} P(x,y) \log_b \frac{P(x,y)}{P(x)P(y)} = H(X) - H(X|Y) = H(Y) - H(Y|X)$$

**Properties**:
- $I(X;Y) \geq 0$ (non-negativity)
- $I(X;Y) = I(Y;X)$ (symmetry)
- $I(X;Y) = 0$ if and only if $X$ and $Y$ are independent
- $I(X;Y) \leq \min\{H(X), H(Y)\}$ (upper bound)

### 5. Relative Entropy (Kullback-Leibler Divergence)

Relative entropy measures the "distance" between two probability distributions.

**Definition**: For distributions $P$ and $Q$:
$$D_{KL}(P||Q) = \sum_x P(x) \log_b \frac{P(x)}{Q(x)}$$

**Properties**:
- $D_{KL}(P||Q) \geq 0$ (non-negativity)
- $D_{KL}(P||Q) = 0$ if and only if $P = Q$
- $D_{KL}(P||Q) \neq D_{KL}(Q||P)$ (asymmetry)
- $I(X;Y) = D_{KL}(P(X,Y)||P(X)P(Y))$ (relationship to mutual information)

### 6. Conditional Mutual Information

Conditional mutual information measures the information shared between two variables given a third.

**Definition**: For random variables $X$, $Y$, and $Z$:
$$I(X;Y|Z) = H(X|Z) - H(X|Y,Z) = \sum_{x,y,z} P(x,y,z) \log_b \frac{P(x,y|z)}{P(x|z)P(y|z)}$$

**Properties**:
- $I(X;Y|Z) \geq 0$ (non-negativity)
- $I(X;Y|Z) = 0$ if and only if $X$ and $Y$ are conditionally independent given $Z$
- $I(X;Y,Z) = I(X;Y) + I(X;Z|Y)$ (chain rule)

## Key Information Inequalities

These inequalities establish fundamental limits and relationships in information theory.

### 1. Shannon's Inequality

The most basic inequality in information theory, establishing the non-negativity of relative entropy.

**Statement**: For any distributions $P$ and $Q$ over the same alphabet:
$$D_{KL}(P||Q) \geq 0$$
with equality if and only if $P = Q$.

**Implication**: Many other information inequalities can be derived from this basic principle.

### 2. Data Processing Inequality

Information can only decrease when processed through a deterministic or random function.

**Statement**: For a Markov chain $X \rightarrow Y \rightarrow Z$:
$$I(X;Y) \geq I(X;Z)$$
with equality if and only if $I(X;Z|Y) = 0$.

**Implication**: Processing cannot create new information; it can only preserve or destroy existing information.

### 3. Fano's Inequality

Establishes a lower bound on the probability of error in terms of conditional entropy.

**Statement**: For random variables $X$ and $Y$ where $X$ takes values in a set of size $|\mathcal{X}|$, and $P_e = P(X \neq Y)$:
$$H(P_e) + P_e \log_b(|\mathcal{X}| - 1) \geq H(X|Y)$$
where $H(P_e) = -P_e \log_b P_e - (1-P_e) \log_b (1-P_e)$.

**Implication**: Sets a fundamental limit on how well we can estimate one random variable from another.

### 4. Jensen's Inequality (Information Form)

A critical mathematical tool used in deriving many information-theoretic results.

**Statement**: For a convex function $f$ and random variable $X$:
$$f(\mathbb{E}[X]) \leq \mathbb{E}[f(X)]$$
For a concave function, the inequality is reversed.

**Information-theoretic application**: Since $-\log$ is convex, Jensen's inequality gives:
$$H(X) = -\sum_x P(x) \log P(x) \leq -\log \sum_x P(x)P(x) = -\log \sum_x P(x)^2$$

### 5. Maximum Entropy Principle

The probability distribution that maximizes entropy subject to constraints is uniquely determined.

**Statement**: Among all probability distributions satisfying a set of constraints on expected values, the one maximizing entropy has the form:
$$P(x) = \frac{1}{Z} \exp\left(-\sum_i \lambda_i f_i(x)\right)$$
where $Z$ is a normalization constant, $\lambda_i$ are Lagrange multipliers, and $f_i(x)$ are the constraint functions.

**Implication**: The maximum entropy distribution is the least biased estimate possible based on given information.

### 6. Chain Rules for Entropy and Mutual Information

These establish how information measures combine for multiple random variables.

**Entropy Chain Rule**:
$$H(X_1, X_2, ..., X_n) = \sum_{i=1}^n H(X_i | X_1, ..., X_{i-1})$$

**Mutual Information Chain Rule**:
$$I(X_1, X_2, ..., X_n; Y) = \sum_{i=1}^n I(X_i; Y | X_1, ..., X_{i-1})$$

**Implication**: Complex information measures can be decomposed into simpler terms.

### 7. Log Sum Inequality

A fundamental inequality used to prove many information-theoretic results.

**Statement**: For non-negative numbers $a_1, a_2, ..., a_n$ and $b_1, b_2, ..., b_n$:
$$\sum_i a_i \log \frac{a_i}{b_i} \geq \left(\sum_i a_i\right) \log \frac{\sum_i a_i}{\sum_i b_i}$$
with equality if and only if $\frac{a_i}{b_i}$ is constant for all $i$.

**Implication**: The log sum inequality directly leads to the convexity of relative entropy.

### 8. Strong Typicality Properties

Properties of typical sequences that are fundamental to coding theorems.

**Statement**: For a sequence $x^n$ of length $n$ from source $X$ with entropy $H(X)$, as $n \to \infty$:
- The set of typical sequences has probability approaching 1
- Each typical sequence has probability approximately $2^{-nH(X)}$
- The number of typical sequences is approximately $2^{nH(X)}$

**Implication**: These properties enable the proofs of the source and channel coding theorems.

## Advanced Information Measures

These extend the basic measures to address specific information-theoretic contexts.

### 1. Rényi Entropy

A generalization of Shannon entropy that provides a spectrum of entropy measures.

**Definition**: For a distribution $P$ and parameter $\alpha \neq 1$:
$$H_\alpha(X) = \frac{1}{1-\alpha} \log_b \sum_x P(x)^\alpha$$

**Special cases**:
- As $\alpha \to 1$, $H_\alpha(X) \to H(X)$ (Shannon entropy)
- $\alpha = 0$: $H_0(X) = \log_b |\{x: P(x) > 0\}|$ (Hartley entropy)
- $\alpha = 2$: $H_2(X) = -\log_b \sum_x P(x)^2$ (collision entropy)
- $\alpha = \infty$: $H_\infty(X) = -\log_b \max_x P(x)$ (min-entropy)

### 2. Cross-Entropy

Measures the expected number of bits needed if using a code optimized for distribution $Q$ to encode data from distribution $P$.

**Definition**:
$$H(P,Q) = -\sum_x P(x) \log_b Q(x)$$

**Relationship**: $H(P,Q) = H(P) + D_{KL}(P||Q)$

### 3. Mutual Information Rate

Extends mutual information to measure information transfer rate in stochastic processes.

**Definition**: For stationary stochastic processes $\{X_i\}$ and $\{Y_i\}$:
$$I(X;Y) = \lim_{n \to \infty} \frac{1}{n} I(X_1^n; Y_1^n)$$
where $X_1^n = (X_1, X_2, ..., X_n)$.

### 4. Directed Information

Measures causal influence of one process on another, respecting the direction of time.

**Definition**: For sequences $X^n$ and $Y^n$:
$$I(X^n \to Y^n) = \sum_{i=1}^n I(X^i; Y_i | Y^{i-1})$$

**Application**: Appropriate for feedback channels where outputs affect future inputs.

### 5. Transfer Entropy

Measures the directed transfer of information between processes.

**Definition**: From process $Y$ to process $X$:
$$T_{Y \to X} = I(Y_{\text{past}}; X_{\text{future}} | X_{\text{past}})$$

**Application**: Used in neuroscience, economics, and complex systems to quantify information flow.

## Computational Applications

These information measures have specific applications in computational contexts.

### 1. Minimum Description Length (MDL)

Formalizes Occam's Razor for model selection.

**Principle**: The best model for a dataset minimizes the sum of:
- The description length of the model
- The description length of the data given the model

**Formal expression**: For data $D$ and model $M$:
$$L(D,M) = L(M) + L(D|M)$$
where $L(M)$ is approximately $-\log_2 P(M)$ and $L(D|M)$ is approximately $-\log_2 P(D|M)$.

### 2. Normalized Mutual Information

A normalized version of mutual information, useful for comparing clustering results.

**Definition**: For random variables $X$ and $Y$:
$$\text{NMI}(X;Y) = \frac{I(X;Y)}{\sqrt{H(X)H(Y)}}$$

**Alternative normalizations**:
- $\frac{I(X;Y)}{\max\{H(X),H(Y)\}}$
- $\frac{2I(X;Y)}{H(X)+H(Y)}$

### 3. Variation of Information

A metric for comparing clusterings or partitions.

**Definition**: For random variables $X$ and $Y$:
$$\text{VI}(X,Y) = H(X|Y) + H(Y|X) = H(X,Y) - I(X;Y)$$

**Property**: Satisfies triangle inequality, making it a true metric.

### 4. Mutual Information Maximization Objective

A principle used in representation learning and feature extraction.

**Objective**: Maximize $I(X;Z)$ where $X$ is the input data and $Z$ is the learned representation, subject to constraints.

**Information Bottleneck Variant**: Maximize $I(Z;Y) - \beta I(X;Z)$ where $Y$ is the target variable and $\beta$ controls the compression-relevance tradeoff.

## Conclusion

These information measures and inequalities form the mathematical foundation of information theory. They provide precise quantification of information concepts and establish the fundamental limits that govern all information processing systems. From communication systems to machine learning algorithms, these measures enable analysis, optimization, and theoretical understanding across diverse domains where information plays a central role.

## References

1. Cover, T. M., & Thomas, J. A. (2006). Elements of Information Theory (2nd ed.). Wiley-Interscience.
2. Yeung, R. W. (2008). Information Theory and Network Coding. Springer.
3. MacKay, D. J. C. (2003). Information Theory, Inference, and Learning Algorithms. Cambridge University Press.
4. Csiszár, I., & Körner, J. (2011). Information Theory: Coding Theorems for Discrete Memoryless Systems. Cambridge University Press.
5. Yeung, R. W. (1997). A Framework for Linear Information Inequalities. IEEE Transactions on Information Theory, 43(6), 1924-1934.