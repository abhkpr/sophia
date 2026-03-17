# Relations and Functions

## The Big Picture

In mathematics, a **relation** captures the idea of a connection between objects. A **function** is a special kind of relation — one that behaves like a machine: one input, exactly one output. These are the formal foundations behind every database relationship, every function you write in code, and every graph algorithm you use.

---

## Part 1 — Relations

### Defining a Relation

A **binary relation** R from set A to set B is a subset of the Cartesian product A × B.

If (a, b) ∈ R, we write **a R b** and say "a is related to b."

**Example:**
```
A = {1, 2, 3},  B = {a, b}
R = {(1,a), (2,b), (3,a)}

1 R a ✓   (1 is related to a)
2 R a ✗   (2 is not related to a)
```

**Real-world example:** The "is enrolled in" relation between Students and Courses.
```
R = {(Alice, Math), (Alice, CS), (Bob, Math), (Carol, CS)}
```

### Relations on a Set

When A = B, we have a **relation on A** — A × A.

**Example:** The "divides" relation on {1, 2, 3, 4, 6}:
```
a | b means "a divides b evenly"
R = {(1,1),(1,2),(1,3),(1,4),(1,6),(2,2),(2,4),(2,6),(3,3),(3,6),(4,4),(6,6)}
```

### Properties of Relations

These properties are the foundation of databases, orderings, and equivalences.

#### Reflexive

**a R a** for every a ∈ A. Every element is related to itself.

```
"is equal to" → reflexive (a = a always ✓)
"is less than" → NOT reflexive (a < a is false)
"divides" → reflexive (a | a always ✓)
```

**Analogy:** A reflexive relation is like "knows themselves" — everyone is related to themselves.

#### Symmetric

If **a R b** then **b R a**.

```
"is married to" → symmetric (if A married B, then B married A ✓)
"is a parent of" → NOT symmetric (if A is parent of B, B is not parent of A)
"is equal to" → symmetric ✓
```

#### Antisymmetric

If **a R b** AND **b R a**, then **a = b**.

In other words: two different elements can't be related in both directions.

```
"≤" on integers → antisymmetric (if a ≤ b and b ≤ a, then a = b ✓)
"divides" → antisymmetric ✓
"is a sibling of" → NOT antisymmetric
```

#### Transitive

If **a R b** and **b R c**, then **a R c**.

```
"is less than" → transitive (if a < b and b < c, then a < c ✓)
"is a parent of" → NOT transitive (parent of parent is grandparent, not parent)
"is an ancestor of" → transitive ✓
```

**Application:** Transitive closure of a graph — can node A reach node C through intermediate nodes? This is what algorithms like Floyd-Warshall compute.

### Equivalence Relations

A relation that is **reflexive, symmetric, and transitive** is an **equivalence relation**.

**Examples:**
- "=" on integers
- "has the same birthday as" on people
- "≡ mod n" (congruence modulo n) on integers

**Equivalence classes:** An equivalence relation partitions the set into groups where all elements in a group are equivalent.

```
Relation: "same remainder when divided by 3" on ℤ
Classes:  [0] = {..., -3, 0, 3, 6, ...}
          [1] = {..., -2, 1, 4, 7, ...}
          [2] = {..., -1, 2, 5, 8, ...}
```

**Application:** Hash tables use modular equivalence to group keys into buckets.

### Partial Orders

A relation that is **reflexive, antisymmetric, and transitive** is a **partial order**.

Notation: (A, ≤) is a **partially ordered set (poset)**.

**Examples:**
- (ℤ, ≤) — standard "less than or equal to"
- (P(A), ⊆) — subsets ordered by inclusion
- (ℤ⁺, |) — positive integers ordered by divisibility

**Partial** means some pairs may be incomparable — neither a ≤ b nor b ≤ a.

```
In (P({1,2,3}), ⊆):
{1} and {2} are incomparable — neither is a subset of the other
```

**Total order:** Every pair is comparable. Standard ≤ on integers is a total order.

---

## Part 2 — Functions

### Defining a Function

A **function** f: A → B assigns to each element of A exactly one element of B.

- A is the **domain**
- B is the **codomain**
- The **range** (or image) is the set of all actual output values: {f(a) | a ∈ A}

**Key rule:** Every input has exactly one output. Not zero outputs. Not two outputs. Exactly one.

**Analogy:** A function is like a vending machine. You press B3, you get exactly one item. Pressing B3 always gives the same item. You can't press B3 and get nothing, and you can't press B3 and get two things.

```
f: {1, 2, 3} → {a, b, c}
f(1) = a, f(2) = a, f(3) = c

This IS a function — each input has exactly one output.
Note: two inputs (1 and 2) can map to the same output (a).
Note: b is in the codomain but not in the range.
```

**Not a function:**
```
g(1) = a, g(1) = b  ✗  (1 has two outputs)
h(2) is undefined   ✗  (2 has no output)
```

### Types of Functions

#### Injective (One-to-One)

Different inputs always give different outputs: if a ≠ b then f(a) ≠ f(b).

**Equivalently:** f(a) = f(b) implies a = b.

**Analogy:** An injective function is like a locker assignment where no two students share a locker.

```
f(x) = 2x on ℤ is injective (different x → different 2x ✓)
f(x) = x² on ℤ is NOT injective (f(2) = f(-2) = 4)
```

#### Surjective (Onto)

Every element of the codomain is hit by at least one input.

**Formally:** For every b ∈ B, there exists a ∈ A such that f(a) = b.

**Analogy:** Every seat in a theater is occupied by at least one person.

```
f: {1,2,3} → {a,b}
f(1) = a, f(2) = b, f(3) = a

Surjective ✓ — both a and b are in the range.
```

#### Bijective (One-to-One Correspondence)

Both injective AND surjective. Every element of B is hit by exactly one element of A.

**Analogy:** A perfect pairing — like assigning one student to each seat with no empty seats and no shared seats.

**Critical application:** Two sets have the **same cardinality** if and only if there exists a bijection between them. This is how mathematicians compare infinite sets — Cantor's insight.

### Function Composition

Given f: A → B and g: B → C, the composition **g ∘ f: A → C** is:
```
(g ∘ f)(x) = g(f(x))
```

Apply f first, then g.

```
f(x) = x + 1
g(x) = x²
(g ∘ f)(x) = g(f(x)) = g(x+1) = (x+1)²
(f ∘ g)(x) = f(g(x)) = f(x²) = x² + 1
```

Note: g ∘ f ≠ f ∘ g in general — composition is not commutative.

**In code:**
```python
def f(x): return x + 1
def g(x): return x ** 2

def compose(g, f):
    return lambda x: g(f(x))

gf = compose(g, f)
gf(3)  # g(f(3)) = g(4) = 16
```

### Inverse Functions

If f: A → B is bijective, its **inverse** f⁻¹: B → A satisfies:
```
f⁻¹(f(a)) = a  for all a ∈ A
f(f⁻¹(b)) = b  for all b ∈ B
```

**Only bijections have inverses.** This is why:
- Non-injective: f(x) = x² has no inverse over ℝ (is it +√y or -√y?)
- Non-surjective: doesn't map back to the whole domain

**Application:** Encryption functions must be bijective — otherwise you can't decrypt. The encryption function and decryption function are inverses of each other.

### Floor and Ceiling Functions

Extremely common in CS — used everywhere in algorithm analysis.

**Floor ⌊x⌋:** Largest integer ≤ x.
```
⌊3.7⌋ = 3
⌊-2.3⌋ = -3
⌊5⌋ = 5
```

**Ceiling ⌈x⌉:** Smallest integer ≥ x.
```
⌈3.2⌉ = 4
⌈-2.7⌉ = -2
⌈5⌉ = 5
```

**Application:**
```python
# Number of pages needed to print n items, k per page:
pages = math.ceil(n / k)

# Middle index in binary search:
mid = (left + right) // 2  # floor division
```

---

## Part 3 — Sequences and Summations

### Sequences

A **sequence** is a function from ℕ (or a subset) to some set — an ordered list.

```
{aₙ} where aₙ = n²: 1, 4, 9, 16, 25, ...
{aₙ} where aₙ = 1/n: 1, 1/2, 1/3, 1/4, ...
```

**Geometric sequence:** Each term is a constant multiple of the previous.
```
aₙ = ar^(n-1)
Example: 2, 6, 18, 54, ... (r = 3, a = 2)
```

**Arithmetic sequence:** Each term differs by a constant.
```
aₙ = a + (n-1)d
Example: 3, 7, 11, 15, ... (d = 4, a = 3)
```

### Summation Formulas

These come up constantly in algorithm analysis:

**Arithmetic sum:**
```
1 + 2 + 3 + ... + n = n(n+1)/2
```

**Sum of squares:**
```
1² + 2² + 3² + ... + n² = n(n+1)(2n+1)/6
```

**Geometric sum:**
```
1 + r + r² + ... + rⁿ = (rⁿ⁺¹ - 1)/(r - 1)  for r ≠ 1
```

**Special case (r = 2):**
```
1 + 2 + 4 + ... + 2ⁿ = 2ⁿ⁺¹ - 1
```

This is why a complete binary tree with n levels has 2ⁿ⁺¹ - 1 nodes.

---

## Practice Problems

**Relations:**

1. Let R be the relation on {1, 2, 3, 4} where a R b if a divides b. List all pairs and determine if R is reflexive, symmetric, antisymmetric, transitive.

2. Determine if each is an equivalence relation on ℤ:
   a) a R b if |a - b| ≤ 1
   b) a R b if a ≡ b (mod 5)
   c) a R b if a + b is even

3. Draw the Hasse diagram for the divisibility relation on {1, 2, 3, 4, 6, 12}.

**Functions:**

4. Which functions f: {1,2,3,4} → {a,b,c,d} are injective? Surjective? Bijective?
   a) f(1)=a, f(2)=b, f(3)=c, f(4)=d
   b) f(1)=a, f(2)=a, f(3)=b, f(4)=c
   c) f(1)=a, f(2)=b, f(3)=a, f(4)=b

5. Find (g ∘ f)(x) and (f ∘ g)(x) where f(x) = 3x + 1 and g(x) = x².

6. Prove that if f: A → B and g: B → C are both injective, then g ∘ f is injective.

7. How many pages are needed to print 1000 records if each page holds 48 records?

**Summations:**

8. Find a closed form for: 1 + 3 + 5 + ... + (2n-1).

9. In an algorithm, the inner loop runs j times for outer loop iteration i, where i goes from 1 to n. Find the total number of inner loop iterations.

---

## Answers to Selected Problems

**Problem 1:**
```
R = {(1,1),(1,2),(1,3),(1,4),(2,2),(2,4),(3,3),(4,4)}
Reflexive: ✓ (every element divides itself)
Symmetric: ✗ (1|2 but 2∤1)
Antisymmetric: ✓ (if a|b and b|a then a=b, for positive integers)
Transitive: ✓ (if a|b and b|c then a|c)
```

**Problem 4:**
```
a) Bijective ✓ (injective ✓, surjective ✓)
b) Neither (not injective: f(1)=f(2)=a; not surjective: d not in range)
c) Not injective: f(1)=f(3)=a; not surjective: c,d not in range
```

**Problem 7:**
```
⌈1000/48⌉ = ⌈20.833...⌉ = 21 pages
```

**Problem 8:**
```
1 + 3 + 5 + ... + (2n-1) = n²
Proof by induction:
Base: n=1, sum = 1 = 1² ✓
Inductive step: assume sum of first k odd numbers = k²
k² + (2k+1) = k² + 2k + 1 = (k+1)² ✓
```

**Problem 9:**
```
Total = Σᵢ₌₁ⁿ i = n(n+1)/2   →   O(n²)
```

---

## References

- Rosen, K.H. — *Discrete Mathematics and Its Applications* — Chapters 2, 9
- MIT 6.042J — [Relations and Functions lecture notes](https://ocw.mit.edu/courses/6-042j-mathematics-for-computer-science-fall-2010/)
- Grimaldi, R.P. — *Discrete and Combinatorial Mathematics* — Chapter 5
