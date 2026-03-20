# Introduction to Computer Architecture & Digital Logic

## What is Computer Architecture?

Computer Architecture is the study of how computers are designed and built — the bridge between software and hardware. It answers the question: **how does a computer actually execute your code?**

When you write `int x = 5 + 3;` in C++, a remarkable chain of events happens:
1. The compiler translates it to machine instructions
2. The CPU fetches those instructions from memory
3. The ALU adds the binary numbers
4. The result is stored in a register
5. Eventually written back to RAM

Understanding this chain makes you a better programmer. You'll know why cache misses slow your code, why branch prediction matters, why memory layout affects performance, and why parallel code is hard.

**Three views of computer architecture:**

```
High Level (What programmer sees):
  int x = a + b;

Assembly Level (What CPU sees):
  ADD R1, R2, R3   ; R1 = R2 + R3

Hardware Level (What transistors do):
  Billions of switches turning on/off
  billions of times per second
```

---

## Part 1 — Number Systems

### Why Binary?

Computers use binary (base-2) because electronic circuits have two stable states:
- **High voltage** (~5V or 3.3V) = **1**
- **Low voltage** (~0V) = **0**

Using base-10 would require 10 stable voltage levels — nearly impossible to distinguish reliably. Binary is robust, simple, and fast.

**Real-world analogy:** Light switches. A switch is either ON (1) or OFF (0). A row of 8 switches can represent 2⁸ = 256 different combinations — one for each possible byte value.

### Binary (Base-2)

**Converting decimal to binary:**
```
Decimal 45 to binary:

45 ÷ 2 = 22 remainder 1  ← LSB (least significant bit)
22 ÷ 2 = 11 remainder 0
11 ÷ 2 =  5 remainder 1
 5 ÷ 2 =  2 remainder 1
 2 ÷ 2 =  1 remainder 0
 1 ÷ 2 =  0 remainder 1  ← MSB (most significant bit)

Read remainders bottom to top: 101101
45 = 0b101101
```

**Converting binary to decimal:**
```
0b101101

Position:  5    4    3    2    1    0
Bit:       1    0    1    1    0    1
Value:    32    0    8    4    0    1

Sum: 32 + 8 + 4 + 1 = 45 ✓
```

**Binary arithmetic:**
```
Addition:          Subtraction:
  0+0=0              1-0=1
  0+1=1              1-1=0
  1+0=1              10-1=1
  1+1=10 (carry)     0-1= borrow needed

Example:
  1011  (11)       1011  (11)
+ 0110  ( 6)     - 0011  ( 3)
──────              ──────
  10001 (17)        1000  ( 8)
```

### Hexadecimal (Base-16)

Binary is verbose. Hexadecimal groups 4 bits into one digit.

```
Binary → Hex mapping:
0000=0  0001=1  0010=2  0011=3
0100=4  0101=5  0110=6  0111=7
1000=8  1001=9  1010=A  1011=B
1100=C  1101=D  1110=E  1111=F

Binary: 1010 1111 0011 1100
Hex:      A    F    3    C
        = 0xAF3C

Decimal: A×16³ + F×16² + 3×16 + C
       = 10×4096 + 15×256 + 3×16 + 12
       = 40960 + 3840 + 48 + 12
       = 44860
```

**In C++:**
```cpp
int hex = 0xFF;        // 255
int bin = 0b11111111;  // 255 (C++14)
int oct = 0377;        // 255 (octal)
printf("%x\n", 255);   // prints: ff
printf("%X\n", 255);   // prints: FF
printf("%o\n", 255);   // prints: 377
printf("%b\n", 255);   // not standard; use bit manipulation
```

### Signed Number Representation

**Sign-Magnitude:** First bit = sign, rest = magnitude
```
+5 = 0101
-5 = 1101
Problem: two zeros (+0 and -0), complex arithmetic
```

**Two's Complement (used by all modern computers):**

To negate: flip all bits, add 1.
```
+5  = 0000 0101
Flip = 1111 1010
Add 1 = 1111 1011 = -5

Verify: 5 + (-5) = 0000 0101 + 1111 1011 = 1 0000 0000
                 = 0000 0000 (ignoring overflow carry) ✓
```

**8-bit two's complement range:** -128 to +127
```
0000 0000 =   0
0000 0001 =   1
...
0111 1111 = +127  (max positive)
1000 0000 = -128  (min negative, most negative)
1111 1110 =  -2
1111 1111 =  -1
```

**Why two's complement is brilliant:**
```
  0000 0101  (+5)
+ 1111 1011  (-5)
─────────────────
1 0000 0000  → ignore carry → 0000 0000 (0) ✓

Same addition hardware works for both positive and negative!
No special subtraction circuit needed.
```

**Integer overflow in C++:**
```cpp
int8_t x = 127;
x++;              // overflow! wraps to -128
// This is undefined behavior for signed integers
// but defined for unsigned integers

uint8_t y = 255;
y++;              // wraps to 0 (defined behavior for unsigned)
```

### Floating Point (IEEE 754)

```
32-bit float layout:
┌─┬──────────┬───────────────────────┐
│S│ Exponent │       Mantissa        │
│1│    8     │          23           │
└─┴──────────┴───────────────────────┘

Value = (-1)^S × 1.Mantissa × 2^(Exponent-127)

Example: 3.14159
Sign = 0 (positive)
3.14159 in binary ≈ 11.00100100001111...
= 1.100100100001111 × 2^1
Exponent = 1 + 127 = 128 = 10000000
Mantissa = 10010010000111101011100...

Final: 0 10000000 10010010000111101011100
```

**Floating point pitfalls:**
```cpp
// Never compare floats with ==
double a = 0.1 + 0.2;
double b = 0.3;
cout << (a == b);           // prints 0 (false!)
cout << fixed << setprecision(17) << a;  // 0.30000000000000004

// Use epsilon comparison
bool equal = abs(a - b) < 1e-9;

// Range of doubles:
// Precision: ~15-17 significant decimal digits
// Range: ±5 × 10^-324 to ±1.8 × 10^308
```

---

## Part 2 — Digital Logic Gates

### Basic Logic Gates

Every computation in a computer ultimately reduces to combinations of these gates.

**NOT Gate (Inverter):**
```
Input → ●─[NOT]─→ Output

Truth table:
A | Q
0 | 1
1 | 0

Symbol:  A ──▷○── Q
```

**AND Gate:**
```
A ──┐
    ├─[AND]─→ Q    Q = A · B = AB
B ──┘

A | B | Q
0 | 0 | 0
0 | 1 | 0
1 | 0 | 0
1 | 1 | 1      (output 1 only when BOTH inputs are 1)

Symbol:  A ──┐
             ├D── Q
         B ──┘
```

**OR Gate:**
```
A | B | Q
0 | 0 | 0
0 | 1 | 1
1 | 0 | 1
1 | 1 | 1      (output 1 when AT LEAST ONE input is 1)

Q = A + B
```

**NAND Gate (NOT AND):**
```
A | B | Q
0 | 0 | 1
0 | 1 | 1
1 | 0 | 1
1 | 1 | 0

NAND is functionally complete — you can build any circuit with just NAND gates.
```

**NOR Gate (NOT OR):**
```
A | B | Q
0 | 0 | 1
0 | 1 | 0
1 | 0 | 0
1 | 1 | 0

NOR is also functionally complete.
```

**XOR Gate (Exclusive OR):**
```
A | B | Q
0 | 0 | 0
0 | 1 | 1
1 | 0 | 1
1 | 1 | 0      (output 1 when inputs DIFFER)

Q = A ⊕ B
Key property: A ⊕ A = 0,  A ⊕ 0 = A
Used in: addition circuits, parity, cryptography
```

**XNOR Gate:**
```
A | B | Q
0 | 0 | 1
0 | 1 | 0
1 | 0 | 0
1 | 1 | 1      (output 1 when inputs are EQUAL)

Q = A ⊙ B = ¬(A ⊕ B)
```

### Boolean Algebra Laws

```
Identity:     A + 0 = A,    A · 1 = A
Null:         A + 1 = 1,    A · 0 = 0
Idempotent:   A + A = A,    A · A = A
Complement:   A + Ā = 1,    A · Ā = 0
Double neg:   ¬(¬A) = A
Commutative:  A+B = B+A,    A·B = B·A
Associative:  (A+B)+C = A+(B+C)
Distributive: A·(B+C) = A·B + A·C
Absorption:   A + A·B = A,  A·(A+B) = A

De Morgan's (CRITICAL):
  ¬(A · B) = Ā + B̄     NOT(A AND B) = NOTA OR NOTB
  ¬(A + B) = Ā · B̄     NOT(A OR B)  = NOTA AND NOTB
```

**De Morgan's in code:**
```cpp
// These are equivalent:
if (!(a && b)) { ... }
if (!a || !b)  { ... }   // De Morgan's applied

if (!(a || b)) { ... }
if (!a && !b)  { ... }   // De Morgan's applied
```

---

## Part 3 — Combinational Circuits

Circuits whose output depends only on current inputs (no memory).

### Half Adder

Adds two 1-bit numbers.

```
Inputs: A, B
Outputs: Sum (S), Carry (C)

A | B | S | C
0 | 0 | 0 | 0
0 | 1 | 1 | 0
1 | 0 | 1 | 0
1 | 1 | 0 | 1   ← 1+1=10 in binary (sum=0, carry=1)

S = A ⊕ B    (XOR)
C = A · B    (AND)

Circuit:
A ──┬──[XOR]── S
    │
B ──┴──[AND]── C
```

### Full Adder

Adds two 1-bit numbers PLUS a carry-in. Needed to chain adders together.

```
Inputs: A, B, Cin
Outputs: Sum (S), Cout

S    = A ⊕ B ⊕ Cin
Cout = (A·B) + (B·Cin) + (A·Cin)

Truth table (selected rows):
A | B | Cin | S | Cout
0 | 0 |  0  | 0 |  0
0 | 1 |  1  | 0 |  1
1 | 1 |  0  | 0 |  1
1 | 1 |  1  | 1 |  1   ← 1+1+1=11 in binary

Implementation with two half adders:
[Half Adder 1]: A,B → S1, C1
[Half Adder 2]: S1,Cin → S, C2
Cout = C1 OR C2
```

### 4-bit Ripple Carry Adder

Chain four full adders to add 4-bit numbers.

```
A3 A2 A1 A0       B3 B2 B1 B0
│  │  │  │         │  │  │  │
┌──┴──┴──┴─────────┴──┴──┴──┴──┐
│ FA3  FA2  FA1  FA0            │
│  │    │    │    │   Cin=0     │
│  └────┘    └────┘             │
└───┬───────────────────────────┘
    │
  Cout   S3  S2  S1  S0

Problem: carry must "ripple" through each stage
Time = 4 × gate_delay  (linear in n bits)

For 64-bit addition: 64 × delay — too slow!
Solution: Carry Lookahead Adder (CLA) — computes all carries simultaneously
```

### Multiplexer (MUX)

Select one of N inputs based on a selector.

```
2-to-1 MUX:
          ┌────┐
D0 ───────┤    │
          │MUX ├──── Y
D1 ───────┤    │
          └──┬─┘
             │
             S (selector)

S=0: Y = D0
S=1: Y = D1

Y = (¬S · D0) + (S · D1)

4-to-1 MUX has 4 data inputs, 2 selector bits (2²=4)
```

**MUX in action — implementing any function:**
```
A 4-input MUX can implement any 2-variable boolean function:
Set D0,D1,D2,D3 to truth table outputs.

Example: F(A,B) = A XNOR B
Truth table: 00→1, 01→0, 10→0, 11→1
Set: D0=1, D1=0, D2=0, D3=1
Done!
```

### Decoder

Convert n-bit binary input to one of 2ⁿ outputs.

```
2-to-4 Decoder:
Input A1A0 → activates one of 4 outputs

A1 A0 | D3 D2 D1 D0
 0  0  |  0  0  0  1   ← D0 active
 0  1  |  0  0  1  0   ← D1 active
 1  0  |  0  1  0  0   ← D2 active
 1  1  |  1  0  0  0   ← D3 active

Used in: memory addressing (select which memory row to activate)
```

---

## Part 4 — Sequential Circuits

Circuits whose output depends on current inputs AND previous state (memory).

### SR Latch (Basic Memory Cell)

```
S ──┬──[NOR]──┬── Q
    │          │
    └──[NOR]──┴── Q̄
    │
R ──┘

Operation:
S=1, R=0: Set   → Q=1
S=0, R=1: Reset → Q=0
S=0, R=0: Hold  → Q unchanged (memory!)
S=1, R=1: FORBIDDEN (both outputs would be 0, then race condition)

This is the fundamental memory cell — stores 1 bit!
```

### D Flip-Flop

The most common storage element in digital circuits.

```
        ┌────┐
D ──────┤ D  ├──── Q
        │ FF │
CLK ────┤    ├──── Q̄
        └────┘

On rising edge of CLK: Q captures D
Between clock edges: Q holds its value

This is how registers work in a CPU!
Each bit of a register is a D flip-flop.
```

### Registers

A group of flip-flops storing multiple bits.

```
4-bit register:
         ┌────┐ ┌────┐ ┌────┐ ┌────┐
D3──────┤FF3 ├ ┤FF2 ├ ┤FF1 ├ ┤FF0 │
         │    │ │    │ │    │ │    │
         └──┬─┘ └──┬─┘ └──┬─┘ └──┬─┘
            │      │      │      │
            Q3     Q2     Q1     Q0
CLK ────────┴──────┴──────┴──────┘

All 4 flip-flops share the same clock.
On each rising clock edge: all 4 bits update simultaneously.

A 64-bit CPU register contains 64 flip-flops.
```

---

## Part 5 — Karnaugh Maps (K-Maps)

A visual method to simplify Boolean expressions.

### 2-Variable K-Map

```
         B=0  B=1
    A=0 │  0 │  1 │
    A=1 │  1 │  1 │

Groups of 1s:
- Right column: A=0,B=1 and A=1,B=1 → B (B alone covers both)
- Bottom row:   A=1,B=0 and A=1,B=1 → A
Combined: F = A + B
```

### 4-Variable K-Map

```
         CD=00 CD=01 CD=11 CD=10
    AB=00│  1  │  0  │  0  │  1  │
    AB=01│  1  │  0  │  0  │  1  │
    AB=11│  1  │  0  │  0  │  1  │
    AB=10│  1  │  0  │  0  │  1  │

The entire left column and right column are 1.
Left column: CD=00 → C'D'
Right column: CD=10 → CD'
Combined: F = D'   (D complement!)

Rules:
- Group sizes must be powers of 2: 1,2,4,8,16
- Groups must be rectangular
- Wrap around edges (torus topology)
- Find minimum number of largest groups
```

---

## Practice Problems

1. Convert the following to binary, hex, and decimal:
   - Decimal 173
   - Binary 0b11001010
   - Hex 0x3F

2. Using two's complement (8-bit):
   - Represent -73
   - Compute 45 + (-28)
   - What is the range?

3. Simplify: F = A'BC + ABC' + ABC + A'BC'

4. Draw the circuit for a 2-bit comparator that outputs 1 when A > B.

5. How many flip-flops are needed to store a 32-bit integer?

---

## Answers

**Problem 1:**
```
173 decimal:
  Binary: 173 = 128+32+8+4+1 = 10101101
  Hex: 1010 1101 = 0xAD

0b11001010:
  Decimal: 128+64+8+2 = 202
  Hex: 1100 1010 = 0xCA

0x3F:
  Binary: 0011 1111
  Decimal: 32+16+8+4+2+1 = 63
```

**Problem 2:**
```
-73 in two's complement:
  73 = 0100 1001
  Flip: 1011 0110
  +1:   1011 0111 = -73 ✓
  Verify: 1011 0111 = -128+32+16+4+2+1 = -73 ✓

45 + (-28):
  45 = 0010 1101
  -28: 28=0001 1100, flip=1110 0011, +1=1110 0100
  Sum: 0010 1101 + 1110 0100 = 0001 0001 = 17 ✓

8-bit range: -128 to +127
```

**Problem 3:**
```
F = A'BC + ABC' + ABC + A'BC'
  = BC(A'+A) + BC'(A+A')    ← factor
  = BC(1) + BC'(1)           ← complement law
  = BC + BC'
  = B(C+C')
  = B(1)
  = B
Simplified: F = B
```

---

## References

- Patterson & Hennessy — *Computer Organization and Design* (RISC-V ed.)
- Morris Mano — *Digital Design* 5th ed.
- Neso Academy — [Digital Electronics](https://www.youtube.com/c/nesoacademy)
- MIT 6.004 — [Computation Structures](https://ocw.mit.edu/courses/6-004-computation-structures-spring-2017/)
