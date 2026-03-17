# Sets, Logic and Proofs

## Why This Matters

Before you write a single line of code, you are already doing discrete mathematics. When you write `if (a && b)`, you are applying propositional logic. When you declare a `HashSet`, you are using set theory. When you prove your algorithm terminates, you are constructing a mathematical proof. Discrete mathematics is the language that computer science is written in.

---

## Part 1 — Set Theory

### What is a Set?

A **set** is an unordered collection of distinct objects. Those objects are called **elements** or **members**.

**Real-world analogy:** A set is like a bag where you throw items in — but the bag has two rules: no duplicates allowed, and the order doesn't matter. A bag with {apple, banana, cherry} is the same bag as {cherry, apple, banana}.

```
A = {1, 2, 3, 4, 5}
B = {2, 4, 6, 8}
C = {}              ← empty set, also written ∅
```

We write **x ∈ A** to say "x is an element of A" and **x ∉ A** to say it isn't.

### Set Builder Notation

Instead of listing elements, describe the rule:

```
A = {x | x is an integer and 1 ≤ x ≤ 5}
    read: "the set of all x such that x is an integer between 1 and 5"

Even = {x | x ∈ ℤ and x mod 2 = 0}
     = {..., -4, -2, 0, 2, 4, ...}
```

**In code:**
```python
A = {x for x in range(1, 6)}           # {1, 2, 3, 4, 5}
Even = {x for x in range(-10, 11) if x % 2 == 0}
```

### Important Sets

| Symbol | Name | Contents |
|--------|------|----------|
| ℕ | Natural numbers | {0, 1, 2, 3, ...} |
| ℤ | Integers | {..., -2, -1, 0, 1, 2, ...} |
| ℚ | Rationals | All fractions p/q where q ≠ 0 |
| ℝ | Reals | All numbers on the number line |
| ∅ | Empty set | {} — contains nothing |

### Subsets

**A is a subset of B** (written A ⊆ B) if every element of A is also in B.

```
A = {2, 4}
B = {1, 2, 3, 4, 5}
A ⊆ B  ✓  (both 2 and 4 are in B)

A = {2, 7}
A ⊆ B  ✗  (7 is not in B)
```

**Proper subset** (A ⊂ B): A ⊆ B AND A ≠ B — A is strictly smaller than B.

**Key fact:** ∅ ⊆ A for every set A. The empty set is a subset of everything.

### Set Operations

**Real-world analogy for all three:**
Imagine two survey groups. Group A: people who own a cat. Group B: people who own a dog.

**Union (A ∪ B)** — all people who own a cat OR a dog (or both).
```
A = {1, 2, 3}
B = {3, 4, 5}
A ∪ B = {1, 2, 3, 4, 5}
```

**Intersection (A ∩ B)** — people who own BOTH a cat AND a dog.
```
A ∩ B = {3}
```

**Difference (A − B)** — people who own a cat but NOT a dog.
```
A − B = {1, 2}
B − A = {4, 5}
```

**Complement (Aᶜ or Ā)** — everyone who does NOT own a cat (relative to some universe U).
```
U = {1, 2, 3, 4, 5, 6}
A = {1, 2, 3}
Aᶜ = {4, 5, 6}
```

**In code:**
```python
A = {1, 2, 3}
B = {3, 4, 5}

A | B   # union     → {1, 2, 3, 4, 5}
A & B   # intersection → {3}
A - B   # difference → {1, 2}
```

### Power Set

The **power set** P(A) is the set of ALL subsets of A — including ∅ and A itself.

```
A = {1, 2, 3}
P(A) = { ∅, {1}, {2}, {3}, {1,2}, {1,3}, {2,3}, {1,2,3} }
```

If |A| = n, then |P(A)| = 2ⁿ.

This is why: for each element, you make a binary choice — include it or not. n elements → 2ⁿ combinations.

**Application in CS:** This is exactly why checking all subsets of an array takes O(2ⁿ) time — you're iterating over the power set.

### Cartesian Product

A × B is the set of all ordered pairs (a, b) where a ∈ A and b ∈ B.

```
A = {1, 2}
B = {x, y}
A × B = {(1,x), (1,y), (2,x), (2,y)}
```

**Application:** A database table with columns Name and Age is essentially Name × Age — all possible (name, age) pairs.

### Cardinality

|A| denotes the number of elements in set A.

```
A = {1, 2, 3, 4, 5}  →  |A| = 5
∅                    →  |∅| = 0
```

**Inclusion-Exclusion Principle:**

```
|A ∪ B| = |A| + |B| − |A ∩ B|
```

**Why subtract the intersection?** Because elements in both A and B get counted twice when you add |A| + |B|, so subtract once.

**Example:** In a class of 30 students, 18 study Maths, 15 study CS, and 10 study both. How many study at least one?

```
|M ∪ C| = 18 + 15 − 10 = 23
```

---

## Part 2 — Propositional Logic

### Propositions

A **proposition** is a statement that is either TRUE or FALSE — never both, never neither.

```
"5 > 3"                          → TRUE  ✓ (proposition)
"The sky is green"               → FALSE ✓ (proposition)
"x > 5"                          → not a proposition (depends on x)
"What time is it?"               → not a proposition (a question)
```

### Logical Connectives

| Symbol | Name | Meaning |
|--------|------|---------|
| ¬p | NOT | negation of p |
| p ∧ q | AND | p and q |
| p ∨ q | OR | p or q (inclusive) |
| p ⊕ q | XOR | p or q but not both |
| p → q | IMPLIES | if p then q |
| p ↔ q | BICONDITIONAL | p if and only if q |

### Truth Tables

**NOT:**

| p | ¬p |
|---|-----|
| T | F |
| F | T |

**AND:**

| p | q | p ∧ q |
|---|---|-------|
| T | T | T |
| T | F | F |
| F | T | F |
| F | F | F |

**OR:**

| p | q | p ∨ q |
|---|---|-------|
| T | T | T |
| T | F | T |
| F | T | T |
| F | F | F |

**IMPLIES (p → q):**

| p | q | p → q |
|---|---|-------|
| T | T | T |
| T | F | **F** |
| F | T | T |
| F | F | T |

The tricky rows are when p is FALSE — the implication is TRUE regardless of q. Why?

**Analogy:** "If it rains, I will carry an umbrella." If it doesn't rain, I haven't broken my promise — whether I carry an umbrella or not is irrelevant. The promise (implication) is only broken when it rains AND I don't carry an umbrella.

**XOR:**

| p | q | p ⊕ q |
|---|---|-------|
| T | T | F |
| T | F | T |
| F | T | T |
| F | F | F |

**Application:** XOR is used in cryptography and error detection. Flipping a bit twice restores it: `x ⊕ k ⊕ k = x`.

### Logical Equivalences

Two expressions are **logically equivalent** if they have the same truth value for all inputs. Written as p ≡ q.

**De Morgan's Laws** (the most important ones):

```
¬(p ∧ q) ≡ ¬p ∨ ¬q
¬(p ∨ q) ≡ ¬p ∧ ¬q
```

**Analogy:** "It's not the case that (I'm tired AND hungry)" means "I'm not tired OR I'm not hungry" — at least one of them is false.

**In code:**
```python
# De Morgan's in programming
not (a and b)  ==  (not a) or (not b)
not (a or b)   ==  (not a) and (not b)
```

**Important equivalences:**

| Name | Law |
|------|-----|
| Double negation | ¬¬p ≡ p |
| Idempotent | p ∧ p ≡ p |
| Identity | p ∧ T ≡ p, p ∨ F ≡ p |
| Domination | p ∨ T ≡ T, p ∧ F ≡ F |
| Contrapositive | p → q ≡ ¬q → ¬p |
| Implication | p → q ≡ ¬p ∨ q |

**Contrapositive is very important:**
"If it is raining, the ground is wet" is equivalent to "If the ground is not wet, it is not raining." Both say the same thing — just in different directions.

### Tautologies and Contradictions

- **Tautology:** Always TRUE (e.g., p ∨ ¬p — "it's raining or it's not raining")
- **Contradiction:** Always FALSE (e.g., p ∧ ¬p — "it's raining and it's not raining")
- **Contingency:** Sometimes true, sometimes false

### Predicates and Quantifiers

A **predicate** is a proposition that contains variables.

```
P(x): "x > 5"       — TRUE when x = 7, FALSE when x = 2
Q(x, y): "x + y = 10"
```

**Universal Quantifier (∀):** "For all"
```
∀x P(x): "P(x) is true for every x"
∀x (x² ≥ 0): "for all real x, x squared is non-negative" — TRUE
```

**Existential Quantifier (∃):** "There exists"
```
∃x P(x): "P(x) is true for at least one x"
∃x (x² = 4): "there exists an x where x² = 4" — TRUE (x = 2 or x = -2)
```

**Negating Quantifiers:**
```
¬(∀x P(x)) ≡ ∃x ¬P(x)
¬(∃x P(x)) ≡ ∀x ¬P(x)
```

"Not everyone passed" = "Someone failed."
"Nobody passed" = "Everyone failed."

---

## Part 3 — Proof Techniques

### Why Proofs?

A proof is a rigorous argument that a statement is true — no exceptions, no special cases, no "it works for the examples I tried." This is what separates mathematics from science. In CS, proofs give you guarantees your code relies on.

### Direct Proof

**Structure:** Assume p is true. Use definitions, axioms, and previously proven theorems to show q must be true.

**Theorem:** If n is an even integer, then n² is even.

**Proof:**
```
Assume n is even.
By definition, n = 2k for some integer k.
Then n² = (2k)² = 4k² = 2(2k²).
Since 2k² is an integer, n² = 2(integer), so n² is even. ∎
```

### Proof by Contrapositive

Instead of proving p → q, prove ¬q → ¬p (which is equivalent).

**Use when:** Direct proof is hard, but the contrapositive is easier.

**Theorem:** If n² is odd, then n is odd.

**Proof by contrapositive:** If n is even, then n² is even.
```
Assume n is even, so n = 2k.
n² = 4k² = 2(2k²) — even. ∎
```

Much easier than the direct approach.

### Proof by Contradiction

Assume the statement is FALSE, then derive a contradiction.

**Theorem:** √2 is irrational.

**Proof:**
```
Assume √2 is rational.
Then √2 = p/q where p, q are integers with no common factors (fully reduced).
Squaring: 2 = p²/q², so p² = 2q².
Therefore p² is even, which means p is even (from our previous theorem).
Write p = 2m.
Then (2m)² = 2q², so 4m² = 2q², so q² = 2m².
Therefore q² is even, so q is even.
But now both p and q are even — they share factor 2.
This contradicts our assumption that p/q was fully reduced. ∎
```

### Proof by Induction

**Analogy:** Imagine an infinite row of dominoes. To prove all of them fall:
1. Knock the first one down (base case)
2. Show if domino k falls, domino k+1 must also fall (inductive step)

**Structure:**
1. **Base case:** Prove the statement for n = 1 (or n = 0)
2. **Inductive hypothesis:** Assume the statement is true for n = k
3. **Inductive step:** Prove it's true for n = k+1

**Theorem:** 1 + 2 + 3 + ... + n = n(n+1)/2

**Proof:**
```
Base case (n = 1): LHS = 1. RHS = 1(2)/2 = 1. ✓

Inductive hypothesis: Assume 1 + 2 + ... + k = k(k+1)/2.

Inductive step: Show 1 + 2 + ... + k + (k+1) = (k+1)(k+2)/2.

LHS = [1 + 2 + ... + k] + (k+1)
    = k(k+1)/2 + (k+1)          ← by inductive hypothesis
    = (k+1)[k/2 + 1]
    = (k+1)(k+2)/2
    = RHS ✓ ∎
```

**Application in CS:** Proving correctness of recursive algorithms is essentially proof by induction.

---

## Practice Problems

**Set Theory:**

1. Let A = {1, 2, 3, 4, 5}, B = {3, 4, 5, 6, 7}. Find A ∪ B, A ∩ B, A − B, B − A.

2. A survey of 100 people found 60 drink coffee, 50 drink tea, and 30 drink both. How many drink neither?

3. List all elements of P({a, b, c}).

4. Prove that for any sets A and B: A ∩ B ⊆ A.

**Logic:**

5. Construct a truth table for (p → q) ∧ (q → p). What well-known connective is this equivalent to?

6. Negate the statement: "All students who study hard pass the exam."

7. Show using truth tables that p → q ≡ ¬p ∨ q.

8. What is the contrapositive of "If the program compiles, then there are no syntax errors"?

**Proofs:**

9. Prove: If n is odd, then n² is odd.

10. Prove by induction: 2⁰ + 2¹ + 2² + ... + 2ⁿ = 2ⁿ⁺¹ − 1.

11. Prove by contradiction: There is no largest prime number.

---

## Answers to Selected Problems

**Problem 1:**
```
A ∪ B = {1, 2, 3, 4, 5, 6, 7}
A ∩ B = {3, 4, 5}
A − B = {1, 2}
B − A = {6, 7}
```

**Problem 2:**
```
|C ∪ T| = 60 + 50 − 30 = 80
Neither = 100 − 80 = 20
```

**Problem 5:** (p → q) ∧ (q → p) ≡ p ↔ q (biconditional)

**Problem 8:** Contrapositive: "If there are syntax errors, then the program does not compile."

**Problem 10:**
```
Base case (n = 0): LHS = 2⁰ = 1. RHS = 2¹ − 1 = 1. ✓

Inductive hypothesis: Assume 2⁰ + ... + 2ᵏ = 2ᵏ⁺¹ − 1.

Inductive step:
2⁰ + ... + 2ᵏ + 2ᵏ⁺¹ = (2ᵏ⁺¹ − 1) + 2ᵏ⁺¹
                       = 2 · 2ᵏ⁺¹ − 1
                       = 2ᵏ⁺² − 1 ✓ ∎
```

---

## References

- Rosen, K.H. — *Discrete Mathematics and Its Applications* (7th ed.) — Chapters 1, 2
- Susanna Epp — *Discrete Mathematics with Applications* — Chapters 1–4
- MIT OpenCourseWare 6.042J — [Mathematics for Computer Science](https://ocw.mit.edu/courses/6-042j-mathematics-for-computer-science-fall-2010/)
