# Probability Theory

## Why Probability in CS?

Randomness is everywhere in computing. Randomized algorithms often beat deterministic ones. Machine learning is built on probability. Network protocols handle packet loss probabilistically. Hash functions need to distribute uniformly. Understanding probability lets you analyze average-case performance, design better algorithms, and reason about uncertain systems.

---

## Part 1 — Sample Spaces and Events

### Definitions

**Experiment:** Any process with an uncertain outcome (flip a coin, roll a die, draw a card).

**Sample space S:** The set of all possible outcomes.

```
Flip a coin:  S = {H, T}
Roll a die:   S = {1, 2, 3, 4, 5, 6}
Flip 2 coins: S = {HH, HT, TH, TT}
```

**Event:** Any subset of the sample space.

```
Event A = "roll an even number" = {2, 4, 6} ⊆ S
Event B = "roll > 4" = {5, 6}
```

### Probability Measure

For a finite sample space with equally likely outcomes:

```
P(A) = |A| / |S|
```

**Properties (Kolmogorov Axioms):**
```
1. P(A) ≥ 0               for any event A
2. P(S) = 1               (something must happen)
3. P(A ∪ B) = P(A) + P(B) if A and B are mutually exclusive
```

**Consequences:**
```
P(∅) = 0
P(Aᶜ) = 1 − P(A)
P(A ∪ B) = P(A) + P(B) − P(A ∩ B)   (inclusion-exclusion)
```

**Examples:**
```
Roll a fair die:
P(even) = |{2,4,6}|/6 = 3/6 = 1/2
P(> 4) = |{5,6}|/6 = 1/3
P(even AND > 4) = |{6}|/6 = 1/6
P(even OR > 4) = 1/2 + 1/3 − 1/6 = 2/3
```

---

## Part 2 — Conditional Probability

### Definition

P(A|B) = "probability of A given that B has occurred"

```
P(A|B) = P(A ∩ B) / P(B)    (when P(B) > 0)
```

**Analogy:** You're at a party. What's the probability the next person you meet likes Python? If you're told you're at a data science meetup, the probability changes — you have new information.

**Example:**
```
Draw a card from a standard deck.
P(Ace | card is red) = ?

P(Ace ∩ Red) = 2/52  (red aces: ♥A and ♦A)
P(Red) = 26/52 = 1/2

P(Ace | Red) = (2/52)/(26/52) = 2/26 = 1/13
```

### Multiplication Rule

```
P(A ∩ B) = P(A|B) × P(B) = P(B|A) × P(A)
```

**Chain rule:**
```
P(A ∩ B ∩ C) = P(A|B ∩ C) × P(B|C) × P(C)
```

### Independence

Events A and B are **independent** if knowing B gives no information about A:

```
P(A|B) = P(A)

Equivalently: P(A ∩ B) = P(A) × P(B)
```

**Example:** Flipping two fair coins — first flip doesn't affect second.
```
P(H on coin 2 | H on coin 1) = P(H on coin 2) = 1/2
P(HH) = P(H)×P(H) = 1/2 × 1/2 = 1/4 ✓
```

**Caution:** Mutually exclusive ≠ independent. If A and B are mutually exclusive and both have positive probability, they can't be independent (knowing A occurred tells you B didn't).

---

## Part 3 — Bayes' Theorem

### The Formula

```
P(A|B) = P(B|A) × P(A) / P(B)
```

**More useful form with law of total probability:**
```
P(A|B) = P(B|A) × P(A) / [P(B|A)×P(A) + P(B|Aᶜ)×P(Aᶜ)]
```

### Why It Matters

Bayes' theorem lets you **update beliefs** when you get new evidence. This is the foundation of:
- Spam filters
- Medical diagnosis
- Machine learning (Naive Bayes classifier)
- Search algorithms

### Classic Example — Medical Test

A disease affects 1% of the population. A test is 99% accurate (detects disease 99% of the time when present; false positive 1% of the time).

You test positive. What's the probability you have the disease?

```
P(Disease) = 0.01
P(No Disease) = 0.99
P(Positive | Disease) = 0.99
P(Positive | No Disease) = 0.01

P(Disease | Positive)
= P(Positive|Disease) × P(Disease) / P(Positive)
= (0.99 × 0.01) / (0.99×0.01 + 0.01×0.99)
= 0.0099 / (0.0099 + 0.0099)
= 0.0099 / 0.0198
= 0.5 = 50%
```

**Surprising result:** Even with a 99% accurate test, a positive result only means 50% chance of having the disease — because the disease is so rare. This is called the **base rate fallacy**.

### Spam Filter Example

```
Prior: P(Spam) = 0.3
Evidence: email contains "FREE MONEY"
P("FREE MONEY" | Spam) = 0.8
P("FREE MONEY" | Not Spam) = 0.01

P(Spam | "FREE MONEY")
= (0.8 × 0.3) / (0.8×0.3 + 0.01×0.7)
= 0.24 / (0.24 + 0.007)
= 0.24 / 0.247
≈ 0.97

97% probability of spam ✓
```

---

## Part 4 — Random Variables

### Discrete Random Variables

A **random variable** X is a function from the sample space to real numbers.

```
Roll a die: X = the number showing
X can take values {1, 2, 3, 4, 5, 6} each with probability 1/6
```

**Probability Mass Function (PMF):** p(x) = P(X = x)

```
For a fair die:
p(1) = p(2) = p(3) = p(4) = p(5) = p(6) = 1/6

Requirements: p(x) ≥ 0,  Σ p(x) = 1
```

### Expected Value

The **expected value** (mean) E[X] is the long-run average:

```
E[X] = Σₓ x × P(X = x)
```

**Example — fair die:**
```
E[X] = 1×(1/6) + 2×(1/6) + 3×(1/6) + 4×(1/6) + 5×(1/6) + 6×(1/6)
     = (1+2+3+4+5+6)/6
     = 21/6 = 3.5
```

**Linearity of expectation — the most useful property:**
```
E[X + Y] = E[X] + E[Y]    (even if X and Y are not independent!)
E[aX + b] = aE[X] + b
```

**Application — expected number of coin flips until heads:**
```
Let X = number of flips. P(X = k) = (1/2)ᵏ (k-1 tails then 1 head)
E[X] = Σₖ₌₁^∞ k × (1/2)ᵏ = 2
```

### Variance

**Variance** measures spread:

```
Var(X) = E[(X - E[X])²] = E[X²] − (E[X])²
```

**Standard deviation:** σ = √Var(X)

```
Fair die:
E[X²] = (1+4+9+16+25+36)/6 = 91/6
Var(X) = 91/6 − (3.5)² = 91/6 − 49/4 = 182/12 − 147/12 = 35/12 ≈ 2.92
σ ≈ 1.71
```

---

## Part 5 — Important Distributions

### Bernoulli Distribution

One trial with two outcomes: success (p) or failure (1-p).

```
P(X = 1) = p     (success)
P(X = 0) = 1-p   (failure)
E[X] = p
Var(X) = p(1-p)
```

### Binomial Distribution

n independent Bernoulli trials. X = number of successes.

```
P(X = k) = C(n,k) × pᵏ × (1-p)ⁿ⁻ᵏ
E[X] = np
Var(X) = np(1-p)
```

**Example:** Flip a fair coin 10 times. P(exactly 7 heads)?
```
P(X=7) = C(10,7) × (0.5)⁷ × (0.5)³
       = 120 × (0.5)¹⁰
       = 120/1024 ≈ 0.117
```

### Geometric Distribution

Number of trials until first success.

```
P(X = k) = (1-p)ᵏ⁻¹ × p    (k ≥ 1)
E[X] = 1/p
Var(X) = (1-p)/p²
```

**Example:** Keep rolling a die until you get a 6. Expected rolls?
```
p = 1/6
E[X] = 1/(1/6) = 6 rolls
```

### Poisson Distribution

Number of events in a fixed time/space interval, given average rate λ.

```
P(X = k) = e⁻λ × λᵏ / k!
E[X] = λ
Var(X) = λ
```

**Application:** Server requests per second, errors in code per 1000 lines, calls to a help desk per hour.

---

## Part 6 — Probabilistic Analysis of Algorithms

### Expected Case Analysis

**Example — randomized quicksort:**

Instead of worst-case O(n²), if we randomly choose the pivot each time, expected runtime is O(n log n).

The key insight: any element is chosen as pivot with equal probability, so on average the split is balanced.

### Birthday Problem

How many people needed so that P(at least two share a birthday) > 50%?

```
P(all different birthdays among k people)
= (365/365) × (364/365) × (363/365) × ... × ((365-k+1)/365)

Set this < 0.5 and solve for k.
Answer: k = 23
```

**Application in CS:** Hash collisions. A hash table with n slots — after inserting about √n items, collision probability exceeds 50%. This is the birthday attack on hash functions.

### Coupon Collector Problem

You collect coupons of n types, one per day, uniformly random. Expected days to collect all n types?

```
E[days] = n × (1 + 1/2 + 1/3 + ... + 1/n) = n × Hₙ ≈ n ln n
```

For n = 365: E ≈ 365 × ln(365) ≈ 2153 days — about 6 years to see all birthdays.

**Application:** Distributed systems — how many times must you broadcast to reach all nodes?

---

## Practice Problems

**Basic Probability:**

1. A bag has 3 red, 4 blue, and 5 green balls. Draw one ball. Find:
   a) P(red)
   b) P(not green)
   c) P(red or blue)

2. Roll two dice. Find P(sum = 7) and P(sum = 11).

3. From a standard deck (52 cards), find P(Ace or Heart).

**Conditional Probability:**

4. In a class, 60% study Maths, 40% study CS, 20% study both. A student studies Maths. What's the probability they also study CS?

5. An urn has 3 red and 5 blue balls. Draw 2 without replacement. Find P(second is red | first is red).

6. Three machines produce 50%, 30%, 20% of a factory's output with defect rates 2%, 3%, 5% respectively. A defective item is found. What's the probability it came from Machine 1?

**Random Variables:**

7. X has PMF: P(X=0)=0.3, P(X=1)=0.4, P(X=2)=0.2, P(X=3)=0.1. Find E[X] and Var(X).

8. In 20 coin flips (fair coin), find E[heads] and P(exactly 10 heads).

9. A website has an average of 3 visitors per minute (Poisson). Find P(exactly 5 visitors in a minute).

**Bayes' Theorem:**

10. A test for a virus has 95% sensitivity and 98% specificity. The virus prevalence is 0.5%. Find P(virus | positive test).

---

## Answers to Selected Problems

**Problem 2:**
```
Sum of 7: {(1,6),(2,5),(3,4),(4,3),(5,2),(6,1)} → P = 6/36 = 1/6
Sum of 11: {(5,6),(6,5)} → P = 2/36 = 1/18
```

**Problem 3:**
```
P(Ace) = 4/52, P(Heart) = 13/52, P(Ace AND Heart) = 1/52
P(Ace OR Heart) = 4/52 + 13/52 − 1/52 = 16/52 = 4/13
```

**Problem 6 (Bayes):**
```
P(M1)=0.5, P(M2)=0.3, P(M3)=0.2
P(D|M1)=0.02, P(D|M2)=0.03, P(D|M3)=0.05

P(D) = 0.5×0.02 + 0.3×0.03 + 0.2×0.05 = 0.01+0.009+0.01 = 0.029

P(M1|D) = P(D|M1)×P(M1)/P(D) = (0.02×0.5)/0.029 = 0.01/0.029 ≈ 0.345
```

**Problem 7:**
```
E[X] = 0×0.3 + 1×0.4 + 2×0.2 + 3×0.1 = 0+0.4+0.4+0.3 = 1.1
E[X²] = 0+0.4+0.8+0.9 = 2.1
Var(X) = 2.1 − 1.1² = 2.1 − 1.21 = 0.89
```

**Problem 9:**
```
P(X=5) = e⁻³ × 3⁵ / 5! = e⁻³ × 243/120 = 0.0498 × 2.025 ≈ 0.1008
```

**Problem 10:**
```
P(Disease)=0.005, P(Positive|Disease)=0.95, P(Positive|No Disease)=0.02
P(Positive) = 0.95×0.005 + 0.02×0.995 = 0.00475+0.0199 = 0.02465
P(Disease|Positive) = 0.00475/0.02465 ≈ 0.193 = 19.3%
```

---

## References

- Rosen, K.H. — *Discrete Mathematics and Its Applications* — Chapter 7
- Feller, W. — *An Introduction to Probability Theory and Its Applications* (classic)
- MIT 6.042J — [Probability](https://ocw.mit.edu/courses/6-042j-mathematics-for-computer-science-fall-2010/)
- Khan Academy — [Statistics and Probability](https://www.khanacademy.org/math/statistics-probability)
- 3Blue1Brown — [Bayes theorem, the geometry of changing beliefs](https://www.youtube.com/watch?v=HZGCoVF3YvM)
