# Functions

## What is a Function?

A **function** f from set A to set B is a relation that assigns to each element of A exactly one element of B.

Written as: f: A → B

**Real life analogy:** Think of a function as a vending machine. You put in a selection code (input from A), and you get exactly one item (output from B). Every valid code gives exactly one item — no code gives two items, and no code gives nothing.

**Key requirement:** Every element of A must map to **exactly one** element of B. Not zero, not two — exactly one.

---

## Terminology

Given f: A → B:

- **Domain** = A (the set of valid inputs)
- **Codomain** = B (the set of possible outputs)
- **Range / Image** = {f(a) | a ∈ A} — the set of values actually produced
- f(a) = b means "f maps a to b" or "the image of a under f is b"

```
f: {1, 2, 3} → {a, b, c, d}
f(1) = a
f(2) = a
f(3) = c

Domain   = {1, 2, 3}
Codomain = {a, b, c, d}
Range    = {a, c}        (b and d are in codomain but not in range)
```

---

## Types of Functions

### Injective (One-to-One)

No two different inputs map to the same output.

∀a₁, a₂ ∈ A: f(a₁) = f(a₂) → a₁ = a₂

**Analogy:** A locker assignment where each student gets a unique locker. No two students share a locker.

```
f(1) = a, f(2) = b, f(3) = c   → INJECTIVE ✓
f(1) = a, f(2) = a, f(3) = c   → NOT INJECTIVE (1 and 2 both map to a) ✗
```

**In CS:** Hash functions ideally should be injective (no collisions). A database primary key enforces injectivity.

### Surjective (Onto)

Every element of the codomain is mapped to by at least one input.

∀b ∈ B, ∃a ∈ A such that f(a) = b

**Analogy:** A hotel where every room is occupied. No room is left empty.

```
f: {1,2,3} → {a,b,c}
f(1)=a, f(2)=b, f(3)=c   → SURJECTIVE ✓ (every output hit)
f(1)=a, f(2)=a, f(3)=b   → NOT SURJECTIVE (c is never hit) ✗
```

**In CS:** A surjective hash function means no bucket is ever empty — good load distribution.

### Bijective (One-to-One Correspondence)

Both injective AND surjective. Every input maps to a unique output, and every output is hit exactly once.

**Analogy:** A perfect seating arrangement — each person has exactly one seat, and each seat has exactly one person.

```
f: {1,2,3} → {a,b,c}
f(1)=a, f(2)=b, f(3)=c   → BIJECTIVE ✓
```

**Key fact:** A bijective function has an inverse.

**In CS:** Bijections are fundamental to cryptography (encryption must be bijective to be decryptable), data compression, and counting arguments in algorithms.

---

## Inverse Functions

If f: A → B is bijective, its **inverse** f⁻¹: B → A is defined by:

f⁻¹(b) = a if and only if f(a) = b

**Analogy:** If f is "putting shoes on," then f⁻¹ is "taking shoes off." Only works if f is bijective — if two feet fit the same shoe, you can't tell which foot owned it.

```
f: {1,2,3} → {a,b,c}
f(1)=a, f(2)=b, f(3)=c

f⁻¹(a) = 1
f⁻¹(b) = 2
f⁻¹(c) = 3
```

---

## Function Composition

Given f: A → B and g: B → C, the **composition** (g ∘ f): A → C is:

(g ∘ f)(x) = g(f(x))

**Read right to left:** f is applied first, then g.

**Analogy:** Assembly line. Raw material → Machine f → Intermediate product → Machine g → Final product.

```
f(x) = x²
g(x) = x + 1

(g ∘ f)(3) = g(f(3)) = g(9) = 10
(f ∘ g)(3) = f(g(3)) = f(4) = 16
```

Note: g ∘ f ≠ f ∘ g in general — composition is not commutative.

**In CS:** Function composition is the mathematical basis of:
- Unix pipes: `ls | grep .md | sort` = sort(grep(ls()))
- Function chaining in functional programming
- Layer composition in neural networks

---

## Special Functions

### Floor and Ceiling

**Floor ⌊x⌋** — largest integer ≤ x

```
⌊3.7⌋ = 3
⌊-2.3⌋ = -3     (not -2! go down)
⌊5⌋ = 5
```

**Ceiling ⌈x⌉** — smallest integer ≥ x

```
⌈3.2⌉ = 4
⌈-2.7⌉ = -2     (not -3! go up)
⌈5⌉ = 5
```

**In CS:**
```cpp
// Integer division in C++ is floor for positive numbers
int pages = totalItems / itemsPerPage;

// Ceiling division pattern (for pages needed):
int pages = (totalItems + itemsPerPage - 1) / itemsPerPage;
// Or: (int)ceil((double)totalItems / itemsPerPage)
```

### Modulo Function

f(a, b) = a mod b — the remainder when a is divided by b

```
17 mod 5 = 2    (17 = 3×5 + 2)
-7 mod 3 = 2    (in mathematics; -1 in C++)
```

**In CS:** Used everywhere — hash tables (bucket = key mod tableSize), cyclic buffers, day-of-week calculations, cryptography.

---

## Counting with Functions

Functions give us a powerful way to count:

**If f: A → B is injective:** |A| ≤ |B| (domain can't be bigger than codomain)

**If f: A → B is surjective:** |A| ≥ |B| (domain must be at least as big as codomain)

**If f: A → B is bijective:** |A| = |B| (same cardinality)

This is the **pigeonhole principle** in disguise:

> If you have n+1 pigeons and n holes, at least one hole contains 2+ pigeons.

Formally: If f: A → B and |A| > |B|, then f cannot be injective. At least two elements of A map to the same element of B.

**Example:** In any group of 13 people, at least two share a birth month.
(13 people → 12 months, by pigeonhole)

**CS Example:** If you have 1000 students and only 365 possible birthdays, at least ⌈1000/365⌉ = 3 students share a birthday.

---

## Recursive Functions

A **recursive function** calls itself with a smaller input until it reaches a base case.

```
Factorial:
f(0) = 1                    (base case)
f(n) = n × f(n-1)          (recursive case)

f(4) = 4 × f(3)
     = 4 × 3 × f(2)
     = 4 × 3 × 2 × f(1)
     = 4 × 3 × 2 × 1 × f(0)
     = 4 × 3 × 2 × 1 × 1
     = 24
```

**Fibonacci:**
```
F(0) = 0
F(1) = 1
F(n) = F(n-1) + F(n-2)
```

**In CS:**
```cpp
int factorial(int n) {
    if (n == 0) return 1;       // base case
    return n * factorial(n-1);  // recursive case
}
```

Every recursive function must have:
1. A base case (stopping condition)
2. Progress toward the base case (smaller input each call)

---

## Growth of Functions — Big O

Functions describe algorithm performance. We care about how fast f(n) grows as n → ∞.

**Big O notation:** f(n) = O(g(n)) means f grows no faster than g (up to a constant factor).

```
O(1)        — constant     — array index lookup
O(log n)    — logarithmic  — binary search
O(n)        — linear       — linear search
O(n log n)  — linearithmic — merge sort
O(n²)       — quadratic    — bubble sort
O(2ⁿ)       — exponential  — brute force subset enumeration
O(n!)       — factorial    — brute force permutations
```

**Analogy:** Imagine n = 1,000,000:
- O(1) → 1 operation
- O(log n) → ~20 operations
- O(n) → 1,000,000 operations
- O(n²) → 10¹² operations (takes ~11 days at 10⁹ ops/sec)
- O(2ⁿ) → more atoms than exist in the universe

---

## Practice Problems

**Q1.** Let f: ℤ → ℤ be defined by f(n) = 2n + 1.
- a) Is f injective?
- b) Is f surjective? (codomain is all integers)
- c) What is the range of f?

**Q2.** Let f(x) = x² and g(x) = 2x - 1 (both f,g: ℝ → ℝ).
Compute:
- a) (g ∘ f)(3)
- b) (f ∘ g)(3)
- c) (f ∘ f)(2)

**Q3.** Calculate:
- a) ⌊7.8⌋
- b) ⌈-3.2⌉
- c) ⌊-0.5⌋
- d) 23 mod 7

**Q4.** Prove or disprove: If f: A → B and g: B → C are both injective, then g ∘ f is injective.

**Q5.** In a class of 30 students, each scores between 0 and 100 on an exam. 
- a) Must at least two students have the same score?
- b) If scores are integers, must at least two students have the same score? Why?

**Q6.** How many integers from 1 to 1000 are divisible by 7?

---

## Answers

**Q1.**
- a) INJECTIVE: if 2a₁+1 = 2a₂+1, then a₁ = a₂ ✓
- b) NOT SURJECTIVE: range = odd integers only (2n+1 is always odd)
- c) Range = {..., -3, -1, 1, 3, 5, ...} = odd integers

**Q2.**
- a) (g∘f)(3) = g(f(3)) = g(9) = 2(9)-1 = 17
- b) (f∘g)(3) = f(g(3)) = f(5) = 25
- c) (f∘f)(2) = f(f(2)) = f(4) = 16

**Q3.**
- a) 7
- b) -3
- c) -1
- d) 2 (23 = 3×7 + 2)

**Q4.** TRUE. Suppose (g∘f)(a₁) = (g∘f)(a₂). Then g(f(a₁)) = g(f(a₂)). Since g is injective, f(a₁) = f(a₂). Since f is injective, a₁ = a₂. ✓

**Q5.**
- a) Not necessarily — 30 students, 101 possible scores (0-100), no pigeonhole violation
- b) YES — 30 students, only 101 integer scores possible... actually still not forced. But if there were 102+ students it would be. With 30 students and integers 0-100, it's NOT guaranteed.

**Q6.** ⌊1000/7⌋ = 142 integers.

---

## References

- Rosen, K.H. — *Discrete Mathematics and Its Applications*, Chapter 2
- Sipser, M. — *Introduction to the Theory of Computation* (for bijections and cardinality)
- [Big O Cheat Sheet](https://www.bigocheatsheet.com)
