# Number Theory

## Why Number Theory in CS?

Number theory sounds like pure mathematics with no practical use. It is actually the foundation of modern cryptography. Every time you visit an HTTPS website, your browser uses RSA encryption — which is entirely built on number theory. Every time you use a hash table, modular arithmetic is running underneath.

---

## Part 1 — Divisibility

### Basic Definitions

**a divides b** (written a | b) if there exists an integer k such that b = ak.

```
3 | 12  ✓  (12 = 3 × 4)
5 | 30  ✓  (30 = 5 × 6)
4 | 10  ✗  (no integer k satisfies 10 = 4k)
```

**Properties:**
```
If a | b and a | c, then a | (b + c)
If a | b, then a | bc for any integer c
If a | b and b | c, then a | c  (transitivity)
```

### Division Algorithm

For any integers a and d (d > 0), there exist unique integers q and r such that:
```
a = dq + r,   where 0 ≤ r < d
```

- q is the **quotient**
- r is the **remainder**

```
17 = 5 × 3 + 2    (17 ÷ 5: quotient=3, remainder=2)
-7 = 3 × (-3) + 2  (-7 ÷ 3: quotient=-3, remainder=2)
```

**In code:**
```python
q, r = divmod(17, 5)  # q=3, r=2
```

### GCD — Greatest Common Divisor

GCD(a, b) is the largest integer that divides both a and b.

```
GCD(48, 18) = 6
GCD(100, 75) = 25
GCD(17, 13) = 1  ← coprime (or relatively prime)
```

**Euclidean Algorithm** — one of the oldest algorithms (300 BC):

```
GCD(a, b) = GCD(b, a mod b)
GCD(a, 0) = a
```

**Example:**
```
GCD(48, 18):
  GCD(48, 18) = GCD(18, 48 mod 18) = GCD(18, 12)
  GCD(18, 12) = GCD(12, 18 mod 12) = GCD(12, 6)
  GCD(12, 6)  = GCD(6, 12 mod 6)  = GCD(6, 0)
  GCD(6, 0)   = 6 ✓
```

**In code:**
```python
def gcd(a, b):
    while b:
        a, b = b, a % b
    return a

# Or: math.gcd(a, b)
```

**Time complexity:** O(log(min(a,b))) — extremely fast.

### LCM — Least Common Multiple

LCM(a, b) is the smallest positive integer divisible by both a and b.

```
LCM(a, b) = |a × b| / GCD(a, b)

LCM(4, 6) = 24/2 = 12
LCM(12, 18) = 216/6 = 36
```

**Application:** Finding when two periodic events coincide — if event A repeats every 4 days and event B every 6 days, they coincide every LCM(4,6)=12 days.

---

## Part 2 — Modular Arithmetic

### Congruence

a is **congruent to b modulo n** (written a ≡ b (mod n)) if n | (a - b).

Equivalently: a and b have the same remainder when divided by n.

```
17 ≡ 5 (mod 12)   (both have remainder 5 when divided by 12)
-3 ≡ 9 (mod 12)   (-3 + 12 = 9)
100 ≡ 2 (mod 7)   (100 = 14×7 + 2)
```

**Analogy:** Clock arithmetic. 17 hours from now is the same time as 5 hours from now on a 12-hour clock.

### Arithmetic in Modular World

Modular arithmetic preserves addition and multiplication:

```
(a + b) mod n = ((a mod n) + (b mod n)) mod n
(a × b) mod n = ((a mod n) × (b mod n)) mod n
```

**Example:** 
```
(99 + 101) mod 10 = ((99 mod 10) + (101 mod 10)) mod 10
                  = (9 + 1) mod 10
                  = 0
```

**Application — preventing overflow:**
```python
# Computing (a * b) mod m without overflow risk
result = (a % m) * (b % m) % m
```

### Modular Exponentiation

Computing aᵇ mod n efficiently — critical for cryptography.

**Naive approach:** Compute aᵇ then take mod → too slow, aᵇ is astronomically large.

**Fast Exponentiation (square and multiply):**
```python
def mod_pow(base, exp, mod):
    result = 1
    base = base % mod
    while exp > 0:
        if exp % 2 == 1:  # odd exponent
            result = (result * base) % mod
        exp //= 2
        base = (base * base) % mod
    return result

mod_pow(2, 100, 1000000007)  # computed in O(log 100) = 7 steps
```

**Time:** O(log exp) — computing 2^1000000 mod p takes only ~20 multiplications.

---

## Part 3 — Primes

### Definition and Fundamental Theorem

A **prime** p > 1 is divisible only by 1 and itself.

**Fundamental Theorem of Arithmetic:** Every integer > 1 can be written as a unique product of primes.

```
12 = 2² × 3
100 = 2² × 5²
360 = 2³ × 3² × 5
```

This factorization is unique — there is only one way to factor any number into primes (up to ordering).

### Sieve of Eratosthenes

Find all primes up to n efficiently:

```
1. Write numbers 2 to n
2. Start with p = 2
3. Mark all multiples of p (2p, 3p, ...) as composite
4. Find next unmarked number — it's prime
5. Repeat until p² > n
```

```python
def sieve(n):
    is_prime = [True] * (n + 1)
    is_prime[0] = is_prime[1] = False
    for p in range(2, int(n**0.5) + 1):
        if is_prime[p]:
            for multiple in range(p*p, n+1, p):
                is_prime[multiple] = False
    return [p for p in range(2, n+1) if is_prime[p]]
```

**Time:** O(n log log n) — very fast.

**Application:** Primality testing, generating cryptographic keys.

### Infinitely Many Primes

**Theorem (Euclid):** There are infinitely many primes.

**Proof by contradiction:**
```
Assume finitely many primes: p₁, p₂, ..., pₖ
Consider N = (p₁ × p₂ × ... × pₖ) + 1
N is either prime (contradicts our list being complete)
or has a prime factor p.
But p can't be any pᵢ — dividing N by any pᵢ leaves remainder 1.
Contradiction. ∎
```

### Primality Testing

**Trial division:** Test if n is divisible by any number from 2 to √n.
```
Time: O(√n) — slow for large n
```

**Fermat's Little Theorem:** If p is prime and gcd(a,p) = 1:
```
aᵖ⁻¹ ≡ 1 (mod p)
```

This gives a probabilistic primality test — compute aᵖ⁻¹ mod p; if ≠ 1, definitely not prime.

**Miller-Rabin Test:** Used in practice — O(k log² n) where k is accuracy parameter.

---

## Part 4 — RSA Cryptography

### The Core Ideas

RSA is built on one observation: multiplying two large primes is easy, but factoring the result is computationally infeasible.

```
p = 1000003 (prime)
q = 1000033 (prime)
n = p × q = 1,000,036,000,099   (easy to compute)
Factor 1,000,036,000,099 back to p and q?  (hard — takes billions of years for large enough n)
```

### RSA Algorithm

**Key generation:**
```
1. Choose two large primes p, q (2048+ bits each in practice)
2. Compute n = p × q
3. Compute φ(n) = (p-1)(q-1)   (Euler's totient)
4. Choose e: 1 < e < φ(n), gcd(e, φ(n)) = 1  (commonly e = 65537)
5. Find d: e × d ≡ 1 (mod φ(n))  (modular inverse)

Public key:  (e, n)
Private key: (d, n)
```

**Encryption (public key):**
```
ciphertext = messageᵉ mod n
```

**Decryption (private key):**
```
message = ciphertextᵈ mod n
```

**Why it works:** Euler's theorem guarantees that (mᵉ)ᵈ ≡ m (mod n) when ed ≡ 1 (mod φ(n)).

**Small example:**
```
p=5, q=11, n=55, φ(n)=40
e=3 (gcd(3,40)=1 ✓)
d=27 (3×27=81=2×40+1 ≡ 1 mod 40 ✓)

Encrypt m=9: 9³ mod 55 = 729 mod 55 = 14
Decrypt 14: 14²⁷ mod 55 = 9 ✓
```

---

## Part 5 — Euler's Totient and Chinese Remainder Theorem

### Euler's Totient Function

φ(n) = number of integers from 1 to n that are coprime to n.

```
φ(1) = 1
φ(p) = p-1    for prime p  (all numbers 1 to p-1 are coprime to p)
φ(p²) = p² - p = p(p-1)
φ(pq) = (p-1)(q-1)  for distinct primes p, q
```

**Euler's Theorem:** For gcd(a, n) = 1:
```
aᵠ⁽ⁿ⁾ ≡ 1 (mod n)
```

Fermat's Little Theorem is a special case where n = p (prime).

### Chinese Remainder Theorem (CRT)

If n₁, n₂, ..., nₖ are pairwise coprime, then the system:
```
x ≡ a₁ (mod n₁)
x ≡ a₂ (mod n₂)
...
x ≡ aₖ (mod nₖ)
```

has a unique solution modulo N = n₁ × n₂ × ... × nₖ.

**Example:**
```
x ≡ 2 (mod 3)
x ≡ 3 (mod 5)
x ≡ 2 (mod 7)

Solution: x ≡ 23 (mod 105)
Verify: 23 = 7×3+2 ✓, 23 = 4×5+3 ✓, 23 = 3×7+2 ✓
```

**Applications:**
- Efficient computation with large numbers (split into smaller moduli)
- Secret sharing schemes
- RSA optimization (CRT form is 4× faster)

---

## Practice Problems

**Divisibility:**

1. Find GCD(252, 198) using the Euclidean algorithm.

2. Find LCM(84, 126) using the GCD.

3. Prove: If GCD(a,b) = 1 and a | bc, then a | c.

**Modular Arithmetic:**

4. Find 7²³⁴⁵ mod 11 using Fermat's Little Theorem.

5. Find 2¹⁰⁰⁰ mod 13.

6. Solve: 5x ≡ 3 (mod 11).

**Primes:**

7. Find all primes up to 50 using the Sieve of Eratosthenes.

8. Find the prime factorization of 3600.

9. Prove that for any prime p > 3, p ≡ 1 or 5 (mod 6).

**RSA:**

10. In RSA with p=7, q=11:
    a) Find n and φ(n)
    b) Choose a valid e
    c) Find d
    d) Encrypt m=5, decrypt back

---

## Answers to Selected Problems

**Problem 1:**
```
GCD(252, 198):
GCD(252, 198) = GCD(198, 54)
GCD(198, 54) = GCD(54, 36)
GCD(54, 36) = GCD(36, 18)
GCD(36, 18) = GCD(18, 0) = 18
```

**Problem 4:**
```
Fermat: a^(p-1) ≡ 1 (mod p) for prime p
7^10 ≡ 1 (mod 11)
2345 = 234 × 10 + 5
7^2345 = (7^10)^234 × 7^5 ≡ 1^234 × 7^5 = 7^5 (mod 11)
7^2 = 49 ≡ 5 (mod 11)
7^4 ≡ 25 ≡ 3 (mod 11)
7^5 ≡ 21 ≡ 10 (mod 11)
Answer: 10
```

**Problem 6:**
```
5x ≡ 3 (mod 11)
Need: 5⁻¹ (mod 11)
5 × 9 = 45 = 4×11+1, so 5⁻¹ ≡ 9 (mod 11)
x ≡ 9 × 3 = 27 ≡ 5 (mod 11)
```

**Problem 10:**
```
n = 7×11 = 77
φ(n) = 6×10 = 60
Choose e = 7 (gcd(7,60)=1 ✓)
d: 7d ≡ 1 (mod 60) → d = 43 (7×43=301=5×60+1 ✓)

Encrypt m=5: 5^7 mod 77 = 78125 mod 77 = 47
Decrypt 47: 47^43 mod 77 = 5 ✓
```

---

## References

- Rosen, K.H. — *Discrete Mathematics and Its Applications* — Chapter 4
- Hardy & Wright — *An Introduction to the Theory of Numbers*
- MIT 6.042J — [Number Theory and Cryptography](https://ocw.mit.edu/courses/6-042j-mathematics-for-computer-science-fall-2010/)
- Khan Academy — [Cryptography](https://www.khanacademy.org/computing/computer-science/cryptography)
- [RSA Algorithm — Stanford Crypto](https://crypto.stanford.edu/~dabo/courses/cs255_winter04/rsa.pdf)
