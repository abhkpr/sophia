# Combinatorics and Counting

## Why Combinatorics?

Combinatorics is the mathematics of counting — but not simple counting like "how many apples are in the basket." It answers questions like: how many ways can you arrange items? How many passwords are possible? How many paths exist through a network? These questions appear constantly in algorithm analysis, probability, cryptography, and software design.

---

## Part 1 — Basic Counting Principles

### The Product Rule

If task A can be done in m ways and task B can be done in n ways, then doing both A AND B can be done in **m × n** ways.

**Analogy:** Getting dressed — 5 shirts and 3 pants = 5 × 3 = 15 possible outfits.

**Example:** How many 8-character passwords exist using lowercase letters and digits?
```
Each character: 26 letters + 10 digits = 36 choices
8 characters: 36⁸ = 2,821,109,907,456 passwords
```

**In CS:**
```python
# Counting nested loops
for i in range(m):      # m iterations
    for j in range(n):  # n iterations each
        ...             # runs m × n times total
```

### The Sum Rule

If task A can be done in m ways and task B can be done in n ways, and A and B are mutually exclusive (can't do both), then doing A OR B can be done in **m + n** ways.

**Analogy:** Choosing a snack — 4 fruits or 6 vegetables = 10 choices (you only pick one snack).

**Example:** A variable name starts with a letter or underscore. How many 1-character variable names?
```
26 lowercase + 26 uppercase + 1 underscore = 53
```

### Inclusion-Exclusion

For sets that overlap: |A ∪ B| = |A| + |B| − |A ∩ B|

**Example:** Numbers from 1 to 100 divisible by 3 OR by 5:
```
Divisible by 3: ⌊100/3⌋ = 33
Divisible by 5: ⌊100/5⌋ = 20
Divisible by both (15): ⌊100/15⌋ = 6

Total = 33 + 20 − 6 = 47
```

### The Pigeonhole Principle

If n+1 items are placed into n containers, at least one container has 2 or more items.

**Analogy:** 13 socks, 12 colors — at least two socks must share a color.

**Generalized:** If N items are placed in k containers, at least one container has ⌈N/k⌉ items.

**Applications in CS:**

- **Birthday paradox:** In a group of 367 people, at least 2 share a birthday (366 possible days).
- **Hash collisions:** A hash function mapping infinite strings to 32-bit integers must have collisions — more inputs than outputs.
- **Compression limits:** Can't compress all files — more possible files than compressed versions.

**Classic example:** Prove that in any group of 27 English words, at least 2 start with the same letter.

```
26 letters (containers), 27 words (items)
By pigeonhole: at least ⌈27/26⌉ = 2 words share a starting letter ✓
```

---

## Part 2 — Permutations

### Permutations (Ordered Arrangements)

A **permutation** is an ordered arrangement of objects.

**How many ways to arrange n distinct objects?**
```
n! = n × (n-1) × (n-2) × ... × 2 × 1
```

**Example:** 5 books on a shelf: 5! = 120 ways.

**Analogy:** How many ways can 5 people sit in 5 distinct chairs? Person 1 has 5 choices, Person 2 has 4 remaining choices, etc.

### P(n, r) — Permutations of r from n

How many ways to choose AND arrange r items from n distinct items?

```
P(n, r) = n!/(n-r)!  =  n × (n-1) × ... × (n-r+1)
```

**Example:** How many ways can a gold, silver, and bronze medal be given to 3 of 10 athletes?
```
P(10, 3) = 10 × 9 × 8 = 720
```

Order matters here — gold to Alice and silver to Bob is different from silver to Alice and gold to Bob.

**In code:**
```python
from math import perm
perm(10, 3)  # 720
```

---

## Part 3 — Combinations

### C(n, r) — Combinations

How many ways to choose r items from n distinct items when **order doesn't matter**?

```
C(n, r) = n! / (r! × (n-r)!)   also written as (n choose r) or ⁿCᵣ
```

**Analogy:** Choosing a committee vs. awarding medals.
- Medal (ordered) → permutation
- Committee (unordered) → combination

**Example:** Choose a 3-person committee from 10 people:
```
C(10, 3) = 10!/(3! × 7!) = (10 × 9 × 8)/(3 × 2 × 1) = 120
```

Compare: P(10, 3) = 720 = 6 × C(10, 3). Each combination of 3 people can be ordered 3! = 6 ways.

**In code:**
```python
from math import comb
comb(10, 3)  # 120
```

### Key Properties

```
C(n, 0) = C(n, n) = 1
C(n, 1) = C(n, n-1) = n
C(n, r) = C(n, n-r)         ← symmetry
C(n, r) = C(n-1, r-1) + C(n-1, r)   ← Pascal's identity
```

**Pascal's identity explained:** To choose r items from n, either the last item is included (choose r-1 from n-1) or it isn't (choose r from n-1).

---

## Part 4 — Binomial Theorem

### Pascal's Triangle

```
Row 0:          1
Row 1:        1   1
Row 2:      1   2   1
Row 3:    1   3   3   1
Row 4:  1   4   6   4   1
```

Entry in row n, position r = C(n, r).

Each entry is the sum of the two entries above it — Pascal's identity in action.

### Binomial Theorem

```
(x + y)ⁿ = Σₖ₌₀ⁿ C(n,k) xⁿ⁻ᵏ yᵏ
```

**Example:**
```
(x + y)³ = C(3,0)x³ + C(3,1)x²y + C(3,2)xy² + C(3,3)y³
         = x³ + 3x²y + 3xy² + y³
```

**Application:** Probability of exactly k successes in n independent trials (Binomial distribution).

**Special cases:**
```
(1+1)ⁿ = Σ C(n,k) = 2ⁿ    → sum of all C(n,k) = 2ⁿ
(1-1)ⁿ = Σ (-1)ᵏ C(n,k) = 0  → alternating sum = 0
```

---

## Part 5 — Advanced Counting

### Permutations with Repetition

How many arrangements of n items where there are n₁ of type 1, n₂ of type 2, ..., nₖ of type k?

```
n! / (n₁! × n₂! × ... × nₖ!)
```

**Example:** How many distinct arrangements of the letters in "MISSISSIPPI"?

```
M: 1, I: 4, S: 4, P: 2
Total = 11! / (1! × 4! × 4! × 2!) = 34,650
```

### Combinations with Repetition

How many ways to choose r items from n types when repetition is allowed and order doesn't matter?

```
C(n + r - 1, r)
```

**Analogy:** Buying r donuts from n flavors — you can get multiple of the same flavor.

**Example:** Choose 3 toppings for a pizza from 8 options (repetition allowed):
```
C(8 + 3 - 1, 3) = C(10, 3) = 120
```

**Stars and Bars method:** Represent r choices as r stars, with n-1 bars separating n groups.

```
3 donuts from 4 flavors: ★★|★|| means 2 of flavor 1, 1 of flavor 3, none of 2 or 4
Arrangements = C(3+3, 3) = C(6,3) = 20
```

### Derangements

A **derangement** is a permutation where no element appears in its original position.

**Example:** Secret Santa where nobody gets their own name.

Number of derangements of n items:
```
D(n) = n! × Σₖ₌₀ⁿ (-1)ᵏ/k!
     ≈ n!/e  for large n
```

```
D(1) = 0
D(2) = 1    ({2,1} only)
D(3) = 2    ({2,3,1} and {3,1,2})
D(4) = 9
```

---

## Part 6 — Recurrence Relations

### What is a Recurrence?

A **recurrence relation** defines a sequence where each term depends on previous terms.

```
aₙ = aₙ₋₁ + aₙ₋₂   with a₀ = 0, a₁ = 1
```

This is the Fibonacci sequence: 0, 1, 1, 2, 3, 5, 8, 13, 21, ...

**Why do they matter in CS?** The time complexity of recursive algorithms is expressed as recurrences:
```
Merge sort: T(n) = 2T(n/2) + O(n)
Binary search: T(n) = T(n/2) + O(1)
```

### Solving Linear Recurrences

For **first-order linear recurrences** aₙ = caₙ₋₁ + f(n):

**Homogeneous case** (f(n) = 0): Solution is aₙ = A·cⁿ

**Example:** aₙ = 3aₙ₋₁, a₀ = 2
```
Solution: aₙ = 2·3ⁿ
Verify: a₁ = 2·3 = 6 ✓, a₂ = 2·9 = 18 ✓
```

### Second-Order Recurrences

**Form:** aₙ = c₁aₙ₋₁ + c₂aₙ₋₂

**Step 1:** Write characteristic equation: r² = c₁r + c₂

**Step 2:** Solve for roots r₁, r₂

**Step 3:**
- If r₁ ≠ r₂: aₙ = A·r₁ⁿ + B·r₂ⁿ
- If r₁ = r₂ = r: aₙ = (A + Bn)·rⁿ

**Example — Fibonacci:**
```
aₙ = aₙ₋₁ + aₙ₋₂
Characteristic equation: r² = r + 1 → r² - r - 1 = 0
Roots: r = (1 ± √5)/2

r₁ = (1+√5)/2 = φ (golden ratio ≈ 1.618)
r₂ = (1-√5)/2 ≈ -0.618

Solution: aₙ = A·φⁿ + B·((1-√5)/2)ⁿ
Using a₀=0, a₁=1: aₙ = (φⁿ - (1-φ)ⁿ)/√5
```

This is Binet's formula — an exact closed form for Fibonacci numbers.

### Master Theorem

For recurrences of the form T(n) = aT(n/b) + f(n):

```
Case 1: If f(n) = O(nˡᵒᵍ_b(a) - ε) → T(n) = Θ(nˡᵒᵍ_b(a))
Case 2: If f(n) = Θ(nˡᵒᵍ_b(a))    → T(n) = Θ(nˡᵒᵍ_b(a) log n)
Case 3: If f(n) = Ω(nˡᵒᵍ_b(a) + ε) → T(n) = Θ(f(n))
```

**Examples:**

| Algorithm | Recurrence | Master Theorem | Result |
|-----------|-----------|----------------|--------|
| Merge Sort | T(n) = 2T(n/2) + n | Case 2: n^log₂2 = n | Θ(n log n) |
| Binary Search | T(n) = T(n/2) + 1 | Case 2: n^log₂1 = 1 | Θ(log n) |
| Strassen | T(n) = 7T(n/2) + n² | Case 1 | Θ(n^log₂7) ≈ Θ(n^2.807) |

---

## Practice Problems

**Basic Counting:**

1. How many 4-digit PINs exist (0000-9999)?

2. A restaurant offers 5 starters, 8 mains, and 4 desserts. How many 3-course meals?

3. How many integers from 1 to 1000 are divisible by 4 or 6?

4. In a group of 100 CS students, prove that at least two have the same last two digits in their student ID (assuming IDs are 4-digit numbers).

**Permutations and Combinations:**

5. How many ways to arrange 8 books on a shelf?

6. A team of 4 must be chosen from 10 people. How many ways? How many if a specific person must be included?

7. How many ways to distribute 12 identical balls into 4 distinct boxes?

8. How many distinct strings can be made from the letters in "ALGORITHM"?

9. A password must have exactly 3 uppercase, 2 digits, and 2 lowercase letters (in any order). How many passwords are possible?

**Recurrences:**

10. Solve: aₙ = 5aₙ₋₁ - 6aₙ₋₂, a₀ = 1, a₁ = 4.

11. Use the Master Theorem to solve T(n) = 4T(n/2) + n.

12. What is the time complexity of an algorithm with T(n) = 3T(n/3) + n?

---

## Answers to Selected Problems

**Problem 3:**
```
Div by 4: ⌊1000/4⌋ = 250
Div by 6: ⌊1000/6⌋ = 166
Div by 12 (lcm): ⌊1000/12⌋ = 83
Total = 250 + 166 − 83 = 333
```

**Problem 6:**
```
Without restriction: C(10,4) = 210
With specific person: choose 3 more from 9 remaining = C(9,3) = 84
```

**Problem 7:**
```
Combinations with repetition: C(12+4-1, 12) = C(15,12) = C(15,3) = 455
```

**Problem 8:**
```
ALGORITHM has 9 distinct letters: 9! = 362,880
```

**Problem 9:**
```
Choose positions: C(7,3) × C(4,2) × C(2,2) = 35 × 6 × 1 = 210 arrangements
Fill positions: 26³ × 10² × 26² = 17,576 × 100 × 676 = 1,188,137,600
Total = 210 × 1,188,137,600 = 249,508,896,000,000
```

**Problem 10:**
```
Characteristic equation: r² - 5r + 6 = 0 → (r-2)(r-3) = 0
Roots: r₁ = 2, r₂ = 3
General solution: aₙ = A·2ⁿ + B·3ⁿ
a₀ = 1: A + B = 1
a₁ = 4: 2A + 3B = 4
Solving: B = 2, A = -1
Answer: aₙ = -2ⁿ + 2·3ⁿ
```

**Problem 11:**
```
T(n) = 4T(n/2) + n
a=4, b=2, f(n)=n
log_b(a) = log₂(4) = 2
f(n) = n = O(n^(2-1)) → Case 1
T(n) = Θ(n²)
```

**Problem 12:**
```
T(n) = 3T(n/3) + n
a=3, b=3, f(n)=n
log_b(a) = log₃(3) = 1
f(n) = n = Θ(n¹) → Case 2
T(n) = Θ(n log n)
```

---

## References

- Rosen, K.H. — *Discrete Mathematics and Its Applications* — Chapters 6, 8
- Graham, Knuth, Patashnik — *Concrete Mathematics* (advanced)
- MIT 6.042J — [Counting and Probability](https://ocw.mit.edu/courses/6-042j-mathematics-for-computer-science-fall-2010/)
- Art of Problem Solving — [Combinatorics](https://artofproblemsolving.com/wiki/index.php/Combinatorics)
