# Logic and Propositional Calculus

## What is Logic?

Logic is the foundation of all reasoning in computer science. Every `if` statement you write, every boolean condition, every circuit in your CPU — all of it is built on the rules of logic.

Think of logic as the grammar of mathematics. Just as grammar tells you how to form valid sentences, logic tells you how to form valid arguments and determine whether they're true or false.

---

## Propositions

A **proposition** is a statement that is either true or false — never both, never neither.

**Examples of propositions:**
- "5 is greater than 3" → TRUE
- "Python is a compiled language" → FALSE
- "Every even number greater than 2 is the sum of two primes" → TRUE (Goldbach's conjecture, verified up to 4×10¹⁸)

**Not propositions:**
- "What time is it?" → question, not a statement
- "x + 1 = 5" → depends on x, truth value unknown
- "This statement is false" → paradox

We use variables **p**, **q**, **r** to represent propositions.

---

## Logical Connectives

### Negation — ¬p (NOT)

Flips the truth value.

**Real life:** If p = "It is raining", then ¬p = "It is NOT raining"

**In code:** `!condition`

| p | ¬p |
|---|-----|
| T | F |
| F | T |

---

### Conjunction — p ∧ q (AND)

True only when **both** are true.

**Real life:** "I will go to the party IF I finish my work AND it doesn't rain."

**In code:** `condition1 && condition2`

| p | q | p ∧ q |
|---|---|-------|
| T | T | T |
| T | F | F |
| F | T | F |
| F | F | F |

---

### Disjunction — p ∨ q (OR)

True when **at least one** is true.

**Real life:** "You can pay by cash OR card."

**In code:** `condition1 || condition2`

| p | q | p ∨ q |
|---|---|-------|
| T | T | T |
| T | F | T |
| F | T | T |
| F | F | F |

---

### Exclusive OR — p ⊕ q (XOR)

True when **exactly one** is true — not both.

**Real life:** A two-way light switch. The light is ON when exactly one switch is flipped. If both are up or both are down, light is off.

**In code:** `condition1 ^ condition2`

| p | q | p ⊕ q |
|---|---|-------|
| T | T | F |
| T | F | T |
| F | T | T |
| F | F | F |

---

### Implication — p → q (IF...THEN)

"If p then q." The most misunderstood connective.

**Real life analogy — a promise:**

> "If it rains, I will carry an umbrella."

| Rain (p) | Umbrella (q) | Promise broken? | p → q |
|----------|--------------|-----------------|-------|
| T | T | No | T |
| T | F | YES — you lied | F |
| F | T | No — you can carry one anyway | T |
| F | F | No — promise only applies when it rains | T |

**Key insight:** Implication is only FALSE when the hypothesis (p) is TRUE and the conclusion (q) is FALSE. A false hypothesis makes the implication vacuously true.

| p | q | p → q |
|---|---|-------|
| T | T | T |
| T | F | F |
| F | T | T |
| F | F | T |

---

### Biconditional — p ↔ q (IF AND ONLY IF)

True when both have the **same** truth value.

**Real life:** "You get dessert if and only if you finish your dinner."

| p | q | p ↔ q |
|---|---|-------|
| T | T | T |
| T | F | F |
| F | T | F |
| F | F | T |

---

## Operator Precedence

Just like BODMAS in arithmetic:

```
1. ¬     (NOT)           — highest priority
2. ∧     (AND)
3. ∨     (OR)
4. →     (implies)
5. ↔     (biconditional) — lowest priority
```

So `p ∨ q ∧ r` means `p ∨ (q ∧ r)` — AND binds tighter than OR.

---

## Tautologies and Contradictions

**Tautology** — always TRUE regardless of variable values.

Example: `p ∨ ¬p` — "It is raining OR it is not raining." Always true.

**In CS:** Tautologies are useless conditions — `if (x > 5 || x <= 5)` is always true.

**Contradiction** — always FALSE.

Example: `p ∧ ¬p` — "It is raining AND it is not raining." Impossible.

**In CS:** `if (x > 5 && x <= 5)` is dead code — never executes.

---

## Logical Equivalences

Two propositions are **logically equivalent** (≡) if they always have the same truth value.

### De Morgan's Laws — The Most Important

```
¬(p ∧ q) ≡ ¬p ∨ ¬q
¬(p ∨ q) ≡ ¬p ∧ ¬q
```

**Real life:** "NOT (raining AND cold)" = "NOT raining OR NOT cold"

**In code:**
```cpp
!(a && b)  is equivalent to  (!a || !b)
!(a || b)  is equivalent to  (!a && !b)
```

This is why every NAND gate in hardware equals an OR gate with inverted inputs.

### Complete Equivalences Table

| Law | Equivalence |
|-----|-------------|
| Double Negation | ¬(¬p) ≡ p |
| Idempotent (AND) | p ∧ p ≡ p |
| Idempotent (OR) | p ∨ p ≡ p |
| Identity (AND) | p ∧ T ≡ p |
| Identity (OR) | p ∨ F ≡ p |
| Domination (AND) | p ∧ F ≡ F |
| Domination (OR) | p ∨ T ≡ T |
| Commutative (AND) | p ∧ q ≡ q ∧ p |
| Commutative (OR) | p ∨ q ≡ q ∨ p |
| Associative (AND) | (p ∧ q) ∧ r ≡ p ∧ (q ∧ r) |
| Associative (OR) | (p ∨ q) ∨ r ≡ p ∨ (q ∨ r) |
| Distributive 1 | p ∧ (q ∨ r) ≡ (p ∧ q) ∨ (p ∧ r) |
| Distributive 2 | p ∨ (q ∧ r) ≡ (p ∨ q) ∧ (p ∨ r) |
| De Morgan's 1 | ¬(p ∧ q) ≡ ¬p ∨ ¬q |
| De Morgan's 2 | ¬(p ∨ q) ≡ ¬p ∧ ¬q |
| Absorption 1 | p ∧ (p ∨ q) ≡ p |
| Absorption 2 | p ∨ (p ∧ q) ≡ p |
| Contrapositive | p → q ≡ ¬q → ¬p |
| Implication | p → q ≡ ¬p ∨ q |

### The Contrapositive

`p → q` is logically equivalent to `¬q → ¬p`

**Real life:**
- Original: "If you study hard, you will pass."
- Contrapositive: "If you did not pass, you did not study hard."

Both say exactly the same thing. Proofs often use the contrapositive when the direct approach is hard.

---

## Predicates and Quantifiers

Propositional logic can't express statements about quantities like "all", "some", "every". Predicate logic extends it.

### Predicates

A **predicate** is a statement whose truth depends on variables.

P(x) = "x is greater than 5"
- P(7) = TRUE
- P(3) = FALSE
- P(x) alone = neither true nor false until x is given

### Universal Quantifier — ∀ (For All)

∀x P(x) means "P(x) is true for **every** value of x in the domain."

**Real life:** ∀ students in this class own a laptop.

To **prove** ∀x P(x): show it holds for every single x.
To **disprove** ∀x P(x): find just ONE counterexample.

**Example:**
∀ integers n, n² ≥ 0 → TRUE (squares are never negative)
∀ integers n, n² > 0 → FALSE (counterexample: n=0, 0²=0, not > 0)

### Existential Quantifier — ∃ (There Exists)

∃x P(x) means "there EXISTS at least one x for which P(x) is true."

**Real life:** ∃ a prime number that is even. (It's 2.)

To **prove** ∃x P(x): find just one example.
To **disprove** ∃x P(x): show it fails for ALL x.

### Negating Quantifiers

```
¬(∀x P(x)) ≡ ∃x ¬P(x)
¬(∃x P(x)) ≡ ∀x ¬P(x)
```

**Real life:**
- "NOT all students passed" = "There EXISTS a student who did not pass"
- "No student failed" = "For ALL students, they did not fail"

---

## Valid Arguments and Inference Rules

An **argument** is a sequence of propositions (premises) leading to a conclusion. It is **valid** if the conclusion follows necessarily from the premises.

### Modus Ponens — The Most Fundamental Rule

```
p → q
p
∴ q
```

If "if p then q" is true, AND p is true, THEN q must be true.

**Real life:**
- If it rains, the match is cancelled. (p → q)
- It is raining. (p)
- Therefore, the match is cancelled. (q) ✓

### Modus Tollens — Proof by Contradiction

```
p → q
¬q
∴ ¬p
```

**Real life:**
- If the server is down, the website won't load. (p → q)
- The website is loading fine. (¬q)
- Therefore, the server is NOT down. (¬p) ✓

### Hypothetical Syllogism — Chaining

```
p → q
q → r
∴ p → r
```

**Real life:**
- If I study, I'll understand the material.
- If I understand the material, I'll pass the exam.
- Therefore: If I study, I'll pass the exam.

### Disjunctive Syllogism

```
p ∨ q
¬p
∴ q
```

**Real life:**
- Either the bug is in the frontend or the backend.
- It's not in the frontend.
- Therefore, it's in the backend.

---

## Practice Problems

**Q1.** Let p = "The code compiles" and q = "The tests pass". Express in words:
- a) p ∧ ¬q
- b) p → q
- c) ¬p ∨ q
- d) Are (b) and (c) equivalent? Prove it.

**Q2.** Construct a truth table for `(p ∧ q) → (p ∨ q)`. Is it a tautology?

**Q3.** Use De Morgan's law to negate: "The number is positive AND less than 100."

**Q4.** Negate using quantifier rules: "Every program written in C++ runs faster than its Python equivalent."

**Q5.** Identify the inference rule used:
- The password is either 8 characters or contains a symbol.
- The password is not 8 characters.
- Therefore, the password contains a symbol.

**Q6.** Is the following argument valid?
- If n is divisible by 4, then n is divisible by 2.
- n is divisible by 2.
- Therefore, n is divisible by 4.

---

## Answers

**Q1.**
- a) "The code compiles but the tests do not pass"
- b) "If the code compiles, then the tests pass"
- c) "Either the code does not compile, or the tests pass"
- d) Yes — by the implication equivalence: p → q ≡ ¬p ∨ q

**Q2.** Yes — it's a tautology. Whenever both p and q are true (left side true), at least one is true (right side true). When left side is false, the implication is vacuously true.

**Q3.** "The number is NOT positive OR it is NOT less than 100" (i.e., it is ≥ 100 or non-positive)

**Q4.** "There EXISTS a program written in C++ that does NOT run faster than its Python equivalent."

**Q5.** Disjunctive Syllogism.

**Q6.** INVALID. This is affirming the consequent. n=2 is divisible by 2 but not by 4. Counterexample disproves the argument.

---

## References

- Rosen, K.H. — *Discrete Mathematics and Its Applications*, 8th ed., Chapter 1
- Epp, S.S. — *Discrete Mathematics with Applications*, Chapter 2
- [Stanford Truth Table Tool](https://web.stanford.edu/class/cs103/tools/truth-table-tool/)
- [MIT OpenCourseWare — Mathematics for CS](https://ocw.mit.edu/courses/6-042j-mathematics-for-computer-science-fall-2010/)
