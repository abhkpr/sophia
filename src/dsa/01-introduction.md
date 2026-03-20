# Introduction to DSA & Complexity Analysis

## What is DSA and Why Does It Matter?

Every program you write manipulates data. The way you **structure** that data and the **steps** you take to process it determines whether your program handles 100 users or 100 million users.

**Real-world analogy:** Imagine finding a name in a phone book. You could start from page 1 and read every name until you find it — that works for 10 names, but with 10 million names it takes forever. Or you could open the middle, check if the name is before or after, and repeat — finding any name in about 23 steps regardless of size. Same problem, completely different approach. That's the difference DSA makes.

**Data Structure** — how you organize data in memory (array, tree, hash table, graph...)

**Algorithm** — the step-by-step procedure to solve a problem using that data

---

## Part 1 — Complexity Analysis

### Why We Measure Complexity

We need a way to compare algorithms that is:
- **Independent of hardware** (a fast computer makes every algorithm faster — that doesn't help comparison)
- **Independent of language** (Python vs C++ implementation details)
- **Focused on growth** (how does performance change as input grows?)

### Big O Notation

Big O describes an algorithm's **worst-case growth rate** as input size n grows toward infinity.

**Formal definition:** f(n) = O(g(n)) means there exist constants c and n₀ such that f(n) ≤ c·g(n) for all n ≥ n₀.

**Practical meaning:** We drop constants and lower-order terms, keep only the dominant term.

```
T(n) = 3n² + 5n + 100
     = O(n²)    ← drop constants, drop lower terms
```

**Why drop constants?** Because constants depend on hardware and implementation. O(2n) and O(n) both describe linear growth — they scale identically.

### Common Complexity Classes

From fastest to slowest:

| Notation | Name | Example | n=1000 operations |
|----------|------|---------|-------------------|
| O(1) | Constant | Array access | 1 |
| O(log n) | Logarithmic | Binary search | ~10 |
| O(n) | Linear | Linear search | 1,000 |
| O(n log n) | Linearithmic | Merge sort | ~10,000 |
| O(n²) | Quadratic | Bubble sort | 1,000,000 |
| O(n³) | Cubic | Matrix multiply (naive) | 1,000,000,000 |
| O(2ⁿ) | Exponential | All subsets | 2^1000 (impossible) |
| O(n!) | Factorial | All permutations | 1000! (astronomical) |

**Analogy for each:**

- **O(1):** Looking up a word in a dictionary you memorized — instant regardless of size
- **O(log n):** Finding a word in an actual dictionary by halving pages — 23 steps for a million words
- **O(n):** Reading every page of a book to find a phrase
- **O(n log n):** Sorting a deck of cards using merge sort
- **O(n²):** Checking every pair of people in a room for shared birthdays
- **O(2ⁿ):** Trying every possible combination on a lock with n dials

### Rules for Calculating Complexity

**Rule 1 — Drop constants:**
```
O(5n) = O(n)
O(1000) = O(1)
```

**Rule 2 — Drop lower-order terms:**
```
O(n² + n) = O(n²)
O(n + log n) = O(n)
```

**Rule 3 — Sequential steps add:**
```cpp
for (int i = 0; i < n; i++) { ... }   // O(n)
for (int i = 0; i < n; i++) { ... }   // O(n)
// Total: O(n) + O(n) = O(2n) = O(n)
```

**Rule 4 — Nested steps multiply:**
```cpp
for (int i = 0; i < n; i++)       // O(n)
    for (int j = 0; j < n; j++)   // O(n) each
        { ... }
// Total: O(n × n) = O(n²)
```

**Rule 5 — Different inputs use different variables:**
```cpp
for (int i = 0; i < a; i++) { ... }   // O(a)
for (int i = 0; i < b; i++) { ... }   // O(b)
// Total: O(a + b) NOT O(n)
```

### Worked Examples

**Example 1:** What is the complexity?
```cpp
int sum = 0;
for (int i = 1; i <= n; i++)
    for (int j = 1; j <= i; j++)
        sum++;
```

Inner loop runs 1, 2, 3, ..., n times → total = n(n+1)/2 = **O(n²)**

**Example 2:**
```cpp
int i = n;
while (i > 1)
    i = i / 2;
```

How many times can you divide n by 2 before reaching 1? log₂(n) times → **O(log n)**

**Example 3:**
```cpp
for (int i = 0; i < n; i++)
    for (int j = 0; j < log(n); j++)
        { ... }
```

Outer loop: n times. Inner loop: log n times each. Total: **O(n log n)**

### Space Complexity

Space complexity measures the **extra memory** used by an algorithm (not counting input).

```cpp
// O(1) space — only a few variables
int sum(vector<int>& arr) {
    int total = 0;
    for (int x : arr) total += x;
    return total;
}

// O(n) space — extra array proportional to input
vector<int> duplicate(vector<int>& arr) {
    vector<int> result(arr.size());  // n extra space
    for (int i = 0; i < arr.size(); i++)
        result[i] = arr[i];
    return result;
}

// O(n) space — recursion stack depth n
int factorial(int n) {
    if (n == 0) return 1;
    return n * factorial(n-1);  // n frames on stack
}
```

### Other Notations

| Notation | Meaning |
|----------|---------|
| O(f) | Upper bound — worst case (most common) |
| Ω(f) | Lower bound — best case |
| Θ(f) | Tight bound — both best and worst are same |

**Example — linear search:**
- Best case: Ω(1) — element is first
- Worst case: O(n) — element is last or not present
- No tight bound Θ — best and worst differ

**Example — merge sort:**
- Always O(n log n) regardless → Θ(n log n)

---

## Part 2 — Asymptotic Analysis in Practice

### Amortized Analysis

Sometimes a single operation is expensive, but the average over many operations is cheap.

**Example — dynamic array (vector) push_back:**
- Most pushes: O(1) — just add to end
- Occasional resize: O(n) — copy everything to new array
- But resizing doubles capacity each time, so it happens rarely

**Amortized cost:** Over n pushes, at most n copies total → O(1) amortized per push.

### Best, Average, Worst Case

**Quick sort example:**
- Best case: O(n log n) — pivot always splits evenly
- Average case: O(n log n) — random pivot is usually decent
- Worst case: O(n²) — pivot always picks smallest/largest (sorted input)

This is why randomized pivot selection is important in practice.

---

## Practice Problems

1. What is the time complexity of each?
   ```cpp
   // a)
   for (int i = 0; i < n; i += 2) { ... }

   // b)
   for (int i = n; i > 0; i /= 3) { ... }

   // c)
   for (int i = 0; i < n; i++)
       for (int j = i; j < n; j++)
           { ... }

   // d)
   int fib(int n) {
       if (n <= 1) return n;
       return fib(n-1) + fib(n-2);
   }
   ```

2. An algorithm takes 1 second for n=1000. Estimate time for n=10000 if it is:
   a) O(n)
   b) O(n²)
   c) O(n log n)

3. Rank these functions from slowest to fastest growth:
   n!, 2ⁿ, n³, n², n log n, n, log n, 1

---

## Answers

**Problem 1:**
```
a) O(n) — loop variable increases by 2, still n/2 iterations = O(n)
b) O(log n) — dividing by 3 each time
c) O(n²) — triangular sum: n + (n-1) + ... + 1 = n(n+1)/2
d) O(2ⁿ) — each call branches into 2 more, depth n
```

**Problem 2:**
```
a) O(n): 10× input → 10× time → 10 seconds
b) O(n²): 10× input → 100× time → 100 seconds
c) O(n log n): 10× input → ~11× time → ~11 seconds
```

**Problem 3 (slowest to fastest):**
```
n! > 2ⁿ > n³ > n² > n log n > n > log n > 1
```

---

## References

- Cormen et al. — *Introduction to Algorithms* (CLRS) — Chapter 3
- Sedgewick & Wayne — *Algorithms* (4th ed.) — Chapter 1
- MIT 6.006 — [Lecture 1: Algorithmic Thinking](https://ocw.mit.edu/courses/6-006-introduction-to-algorithms-fall-2011/)
- Big-O Cheat Sheet — [bigocheatsheet.com](https://www.bigocheatsheet.com)
