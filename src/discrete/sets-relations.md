# Sets and Relations

## What is a Set?

A **set** is an unordered collection of distinct objects. No duplicates, no order.

**Real life analogy:** Think of a set like a bag of marbles — what matters is which marbles are in the bag, not the order they sit in, and you can't have two identical marbles.

In CS, sets appear everywhere: the set of valid usernames, the set of reachable states in a program, the set of prime numbers used in encryption.

Sets are written with curly braces: A = {1, 2, 3, 4, 5}

---

## Set Notation and Terminology

**Element / Member:** x ∈ A means "x is an element of A"

```
A = {1, 2, 3, 4}
2 ∈ A    → TRUE
7 ∈ A    → FALSE
7 ∉ A    → TRUE
```

**Cardinality:** |A| = number of elements in A

```
A = {a, b, c, d}    |A| = 4
B = {1, 2, 2, 3}    |B| = 3  (duplicates don't count)
```

**Empty Set:** ∅ or {} — the set with no elements. |∅| = 0.

**Real life analogy:** An empty set is like an empty room. It exists, it's just empty.

**Universal Set:** U — the set of all elements under consideration in a given problem.

---

## Describing Sets

### Roster Method
List all elements explicitly:
```
Primes under 10 = {2, 3, 5, 7}
Vowels = {a, e, i, o, u}
```

### Set-Builder Notation
Describe by a rule:
```
{x | x is an integer and x > 0}       — positive integers
{x ∈ ℤ | x² < 25}                     — integers whose square is less than 25 = {-4,-3,-2,-1,0,1,2,3,4}
{x | x = 2k for some integer k}        — even integers
```

Read the `|` as "such that."

### Important Number Sets

| Symbol | Name | Examples |
|--------|------|---------|
| ℕ | Natural numbers | 0, 1, 2, 3, ... |
| ℤ | Integers | ..., -2, -1, 0, 1, 2, ... |
| ℚ | Rational numbers | 1/2, -3/4, 5 |
| ℝ | Real numbers | π, √2, 3.14... |
| ℂ | Complex numbers | 2+3i |

---

## Subsets

A is a **subset** of B (A ⊆ B) if every element of A is also in B.

```
A = {1, 2}
B = {1, 2, 3, 4}
A ⊆ B → TRUE    (every element of A appears in B)
B ⊆ A → FALSE   (3 is in B but not in A)
```

**Analogy:** If B is the set of all vehicles and A is the set of all cars, then A ⊆ B. Every car is a vehicle.

**Proper Subset (⊂):** A ⊂ B means A ⊆ B AND A ≠ B (A is strictly smaller).

**Key facts:**
- ∅ ⊆ A for any set A (empty set is a subset of everything)
- A ⊆ A for any set A (every set is a subset of itself)
- If A ⊆ B and B ⊆ A, then A = B

---

## Power Set

The **power set** P(A) is the set of ALL subsets of A, including ∅ and A itself.

```
A = {1, 2, 3}
P(A) = { ∅, {1}, {2}, {3}, {1,2}, {1,3}, {2,3}, {1,2,3} }
```

**Key fact:** If |A| = n, then |P(A)| = 2ⁿ

```
|A| = 3 → |P(A)| = 2³ = 8   ✓ (count above)
|A| = 0 → |P(A)| = 2⁰ = 1  (just the empty set)
```

**In CS:** Power sets appear in dynamic programming (subset problems), boolean functions, and database query optimization.

---

## Set Operations

### Union — A ∪ B

All elements in A **or** B (or both).

```
A = {1, 2, 3}
B = {3, 4, 5}
A ∪ B = {1, 2, 3, 4, 5}
```

**Analogy:** Combining two guest lists for a party. Include everyone from both lists (no duplicates).

**In SQL:** `SELECT * FROM A UNION SELECT * FROM B`

### Intersection — A ∩ B

Only elements in **both** A and B.

```
A = {1, 2, 3, 4}
B = {3, 4, 5, 6}
A ∩ B = {3, 4}
```

**Analogy:** Friends you have in common with someone.

**In SQL:** `SELECT * FROM A INNER JOIN B`

### Difference — A − B

Elements in A but **not** in B.

```
A = {1, 2, 3, 4}
B = {3, 4, 5, 6}
A − B = {1, 2}
B − A = {5, 6}
```

**Note:** A − B ≠ B − A (order matters)

**Analogy:** Friends you have that the other person doesn't.

### Complement — Ā or A'

Everything in the universal set U that is **not** in A.

```
U = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
A = {2, 4, 6, 8, 10}
Ā = {1, 3, 5, 7, 9}
```

**Analogy:** Everyone NOT on the invite list.

### Symmetric Difference — A ⊕ B

Elements in A or B but **not in both** (XOR for sets).

```
A = {1, 2, 3, 4}
B = {3, 4, 5, 6}
A ⊕ B = {1, 2, 5, 6}
```

A ⊕ B = (A ∪ B) − (A ∩ B) = (A − B) ∪ (B − A)

---

## Set Identities

These mirror the logical equivalences exactly:

| Identity | Law |
|----------|-----|
| A ∪ ∅ = A | Identity |
| A ∩ U = A | Identity |
| A ∪ U = U | Domination |
| A ∩ ∅ = ∅ | Domination |
| A ∪ A = A | Idempotent |
| A ∩ A = A | Idempotent |
| (Ā)' = A | Double Complement |
| A ∪ B = B ∪ A | Commutative |
| A ∩ B = B ∩ A | Commutative |
| A ∪ (B ∪ C) = (A ∪ B) ∪ C | Associative |
| A ∪ (B ∩ C) = (A ∪ B) ∩ (A ∪ C) | Distributive |
| A ∩ (B ∪ C) = (A ∩ B) ∪ (A ∩ C) | Distributive |
| (A ∪ B)' = A' ∩ B' | De Morgan's |
| (A ∩ B)' = A' ∪ B' | De Morgan's |

---

## Cartesian Product

The **Cartesian product** A × B is the set of all **ordered pairs** (a, b) where a ∈ A and b ∈ B.

```
A = {1, 2}
B = {x, y, z}
A × B = {(1,x), (1,y), (1,z), (2,x), (2,y), (2,z)}
```

|A × B| = |A| × |B| = 2 × 3 = 6

**Real life analogy:** A restaurant menu. If A = {soup, salad} and B = {coffee, tea, juice}, then A × B gives all possible meal combinations.

**In CS:** Database tables are Cartesian products. A table with columns (Name, Age, Score) is a subset of String × ℕ × ℝ.

---

## Relations

A **binary relation** R from set A to set B is a subset of A × B. It specifies which pairs (a, b) are "related."

```
A = {1, 2, 3}
B = {1, 2, 3}
R = {(1,1), (1,2), (2,2), (2,3), (3,3)}  — "less than or equal to"
```

We write aRb or (a, b) ∈ R to mean a is related to b.

### Representing Relations

**Matrix representation:**

For a relation on A = {1, 2, 3}, create a matrix M where M[i][j] = 1 if (i,j) ∈ R:

```
R = "≤" on {1,2,3}
     1  2  3
1  [ 1  1  1 ]
2  [ 0  1  1 ]
3  [ 0  0  1 ]
```

**Graph/Digraph representation:** Draw nodes for each element, draw an arrow from a to b if (a,b) ∈ R.

---

## Properties of Relations

These properties are critical for understanding databases, algorithms, and formal systems.

### Reflexive

Every element is related to itself: ∀a ∈ A, (a,a) ∈ R

**Example:** "≤" is reflexive (1 ≤ 1, 2 ≤ 2, 3 ≤ 3) ✓

**Example:** "<" is NOT reflexive (1 < 1 is false) ✗

**In matrix:** All diagonal entries are 1.

### Symmetric

If a is related to b, then b is related to a: ∀a,b, (a,b) ∈ R → (b,a) ∈ R

**Example:** "is a sibling of" is symmetric ✓

**Example:** "is the parent of" is NOT symmetric ✗

**In matrix:** The matrix equals its own transpose (M = Mᵀ).

### Antisymmetric

If a is related to b AND b is related to a, then a = b: (a,b) ∈ R ∧ (b,a) ∈ R → a = b

**Example:** "≤" is antisymmetric. If a ≤ b and b ≤ a, then a = b ✓

**Example:** Friendship is NOT antisymmetric (if A is friends with B, B is friends with A, but A ≠ B) ✗

### Transitive

If a relates to b and b relates to c, then a relates to c: (a,b) ∈ R ∧ (b,c) ∈ R → (a,c) ∈ R

**Example:** "is an ancestor of" is transitive ✓

**Example:** "is the parent of" is NOT transitive (grandparent ≠ parent) ✗

---

## Equivalence Relations

A relation is an **equivalence relation** if it is:
1. **Reflexive**
2. **Symmetric**
3. **Transitive**

**Real life analogy:** "Has the same birthday as." 
- Reflexive: You have the same birthday as yourself ✓
- Symmetric: If A has the same birthday as B, then B has the same birthday as A ✓
- Transitive: If A and B share a birthday, and B and C share a birthday, then A and C share a birthday ✓

**In CS:** Equivalence relations partition elements into **equivalence classes** — groups where everything in the group is equivalent to everything else. This is the basis of:
- Union-Find data structure
- Graph connected components
- Modular arithmetic (≡ mod n)

**Example:** Congruence modulo 3. 1 ≡ 4 ≡ 7 ≡ 10 (mod 3) are all in the same equivalence class.

---

## Partial Orders

A relation is a **partial order** if it is:
1. **Reflexive**
2. **Antisymmetric**
3. **Transitive**

A set with a partial order is a **partially ordered set (poset)**.

**Example:** "≤" on integers — reflexive, antisymmetric, transitive ✓

**"Partial"** means not every pair needs to be comparable. Example: subset relation ⊆ on sets. {1,2} and {3,4} are both subsets of {1,2,3,4} but neither is a subset of the other — they're incomparable.

**In CS:** Partial orders appear in:
- Dependency resolution (package managers, task scheduling)
- Version control (commit history forms a DAG)
- Type hierarchies in OOP

A **total order** (or linear order) is a partial order where every pair is comparable. Example: "≤" on real numbers.

---

## Practice Problems

**Q1.** Let A = {1, 2, 3, 4, 5, 6}
- a) List all elements of A where x ∈ A and x is odd
- b) List A ∩ {x | x is prime}
- c) Find |P(A)|

**Q2.** Let A = {a, b, c} and B = {1, 2}. Write out A × B.

**Q3.** Determine which properties (reflexive, symmetric, antisymmetric, transitive) the following relations on ℤ satisfy:
- a) R = {(a,b) | a = b²}
- b) R = {(a,b) | a + b is even}
- c) R = {(a,b) | a divides b}

**Q4.** Is the relation "has the same number of characters as" on the set of all strings an equivalence relation? Prove or disprove.

**Q5.** Give an example of a relation that is symmetric and transitive but NOT reflexive.

---

## Answers

**Q1.**
- a) {1, 3, 5}
- b) {2, 3, 5} (primes in A)
- c) |P(A)| = 2⁶ = 64

**Q2.** A × B = {(a,1),(a,2),(b,1),(b,2),(c,1),(c,2)}

**Q3.**
- a) Not reflexive (2=2² is false for most a), not symmetric (if a=b² then b=a² is not generally true), not transitive
- b) Reflexive (a+a=2a, even) ✓, Symmetric (if a+b even then b+a even) ✓, Transitive (if a+b and b+c both even, then a,b,c all same parity, so a+c even) ✓ → Equivalence relation
- c) Reflexive (a|a) ✓, NOT symmetric (2|4 but 4∤2), Antisymmetric (if a|b and b|a then a=±b, for positives a=b) ✓, Transitive ✓ → Partial order (on positive integers)

**Q4.** Yes — equivalence relation. Reflexive (string has same length as itself), Symmetric, Transitive.

**Q5.** Let A = ∅. The empty relation on any set is vacuously symmetric and transitive, but not reflexive unless the set itself is empty.

---

## References

- Rosen, K.H. — *Discrete Mathematics and Its Applications*, Chapters 2 and 9
- [MIT 6.042J Lecture Notes — Sets](https://ocw.mit.edu/courses/6-042j-mathematics-for-computer-science-fall-2010/pages/readings/)
