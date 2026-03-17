# C++ Fundamentals

## Why C++?

C++ sits at a rare intersection: it gives you the control of C (direct memory management, pointer arithmetic, hardware-level access) while offering the abstraction of high-level languages (classes, templates, the STL). No other mainstream language does both as well.

**Where C++ dominates:**
- Competitive programming (fast I/O, STL, no garbage collection overhead)
- Game engines (Unreal Engine, most AAA games)
- Systems programming (OS kernels, device drivers, databases)
- High-frequency trading (microsecond latency matters)
- Embedded systems (microcontrollers, robotics)
- Compilers and interpreters (LLVM, V8 engine are C++)

---

## Part 1 — Program Structure

### Your First Program

```cpp
#include <iostream>
using namespace std;

int main() {
    cout << "Hello, World!" << endl;
    return 0;
}
```

**Breaking it down:**

`#include <iostream>` — tells the preprocessor to paste the contents of the iostream header file here. iostream defines `cin`, `cout`, and other I/O functionality.

`using namespace std` — tells the compiler that when you write `cout`, you mean `std::cout`. Without this line, you'd need to write `std::cout` every time.

`int main()` — the entry point. Every C++ program starts here. Returns `int` to signal success (0) or failure (non-zero) to the operating system.

`return 0` — signals successful execution. The OS receives this value.

### Compilation Pipeline

```
source.cpp
    ↓ preprocessor (#include, #define resolved)
preprocessed source
    ↓ compiler (translates to assembly)
assembly code
    ↓ assembler (translates to machine code)
object file (source.o)
    ↓ linker (combines object files + libraries)
executable (a.out or program.exe)
```

```bash
g++ -o program source.cpp        # compile and link
g++ -std=c++17 -O2 -o prog src.cpp  # C++17, optimized
g++ -Wall -Wextra -o prog src.cpp   # show all warnings
```

**Flags you should know:**
```
-std=c++17    use C++17 standard (recommended)
-O2           optimize for speed (always use in competitive programming)
-Wall         enable common warnings
-g            include debug info (for gdb)
-fsanitize=address  detect memory errors at runtime
```

---

## Part 2 — Data Types

### Primitive Types

```cpp
// Integer types
int     a = 42;          // typically 32-bit, ±2.1 billion
long    b = 1000000000L; // at least 32-bit
long long c = 9e18;      // 64-bit, ±9.2 × 10¹⁸ — use for large numbers

// Unsigned (non-negative only, double the positive range)
unsigned int  d = 4294967295U;
unsigned long long e = 18446744073709551615ULL;

// Floating point
float  f = 3.14f;     // 32-bit, ~7 decimal digits of precision
double g = 3.14159;   // 64-bit, ~15 decimal digits — prefer over float
long double h = 3.14L; // 80 or 128-bit

// Character
char ch = 'A';     // 8-bit signed integer, stores ASCII value
char ch2 = 65;     // same as 'A' — char is just a small integer

// Boolean
bool flag = true;   // true = 1, false = 0
bool flag2 = false;

// No value
void   // only for function return types and pointers
```

### Size Guarantees

```cpp
#include <climits>
#include <cfloat>

cout << sizeof(int) << endl;       // typically 4 bytes
cout << sizeof(long long) << endl; // typically 8 bytes
cout << INT_MAX << endl;           // 2147483647
cout << LLONG_MAX << endl;         // 9223372036854775807
```

**Key rule for competitive programming:** When a number might exceed 2×10⁹, use `long long`. When it might exceed 9×10¹⁸, you need big integer arithmetic.

### Type Conversions

**Implicit (automatic):**
```cpp
int a = 5;
double b = a;  // int → double, no data loss, safe
double c = 3.9;
int d = c;     // double → int, truncates to 3 — data loss, silent!
```

**Explicit (cast):**
```cpp
double x = 3.9;
int y = (int)x;           // C-style cast — works but avoid
int z = static_cast<int>(x); // C++ style — prefer this

// Why use static_cast?
// It's explicit and searchable — easy to find all casts in code
// It catches invalid conversions at compile time
```

**Common pitfall — integer division:**
```cpp
int a = 7, b = 2;
cout << a / b;          // prints 3, not 3.5!
cout << (double)a / b;  // prints 3.5 ✓
cout << a / (double)b;  // prints 3.5 ✓
```

### Auto Keyword (C++11)

```cpp
auto x = 42;          // int
auto y = 3.14;        // double
auto z = "hello";     // const char*
auto w = true;        // bool

// Most useful with long type names
auto it = myVector.begin();  // instead of vector<int>::iterator it
```

---

## Part 3 — Variables and Constants

### Variable Declaration

```cpp
int x;          // declared but uninitialized — contains garbage!
int y = 10;     // initialized to 10
int z(10);      // same thing, constructor syntax
int w{10};      // brace initialization (C++11) — prefer this
                // prevents narrowing conversions
```

**Why brace initialization is better:**
```cpp
int a = 3.9;    // silently truncates to 3
int b{3.9};     // compile error — narrowing conversion caught ✓
```

### Constants

```cpp
const double PI = 3.14159265358979;  // can't be changed after init
PI = 3.14;  // compile error ✓

// constexpr — evaluated at compile time
constexpr int MAX_N = 100005;
constexpr int ARRAY_SIZE = MAX_N * 2;
int arr[ARRAY_SIZE];  // valid — size known at compile time
```

**`const` vs `constexpr`:**
```
const:     value can't change, but might be determined at runtime
constexpr: value must be determined at compile time
```

### Scope

```cpp
int x = 10;  // global scope — accessible everywhere

int main() {
    int x = 20;  // local scope — shadows global x
    {
        int x = 30;  // inner block scope
        cout << x;   // 30
    }
    cout << x;       // 20 (inner x gone)
    cout << ::x;     // 10 (:: refers to global scope)
    return 0;
}
```

---

## Part 4 — Operators

### Arithmetic

```cpp
int a = 17, b = 5;
cout << a + b;   // 22
cout << a - b;   // 12
cout << a * b;   // 85
cout << a / b;   // 3  (integer division — truncates)
cout << a % b;   // 2  (modulo — remainder)

// Compound assignment
a += b;   // a = a + b
a -= b;   // a = a - b
a *= b;   // a = a * b
a /= b;   // a = a / b
a %= b;   // a = a % b
```

### Increment and Decrement

```cpp
int x = 5;
cout << x++;  // prints 5, then x becomes 6 (post-increment)
cout << ++x;  // x becomes 7, then prints 7 (pre-increment)
cout << x--;  // prints 7, then x becomes 6 (post-decrement)
cout << --x;  // x becomes 5, then prints 5 (pre-decrement)
```

**Rule of thumb:** In standalone statements (not inside expressions), `++x` and `x++` are identical. Inside expressions, they differ. Prefer `++x` — it's never slower and sometimes faster.

### Comparison and Logical

```cpp
// Comparison — return bool
a == b   // equal
a != b   // not equal
a < b    // less than
a > b    // greater than
a <= b   // less than or equal
a >= b   // greater than or equal

// Logical
!a       // NOT
a && b   // AND — short-circuit: if a is false, b not evaluated
a || b   // OR  — short-circuit: if a is true, b not evaluated
```

**Short-circuit evaluation:**
```cpp
int* ptr = nullptr;
if (ptr != nullptr && *ptr > 5)  // safe — if ptr is null, *ptr never evaluated
    cout << *ptr;
```

### Bitwise Operators

```cpp
int a = 0b1010;  // 10 in binary
int b = 0b1100;  // 12 in binary

a & b   // AND:  0b1000 = 8
a | b   // OR:   0b1110 = 14
a ^ b   // XOR:  0b0110 = 6
~a      // NOT:  flips all bits (−11 for int)
a << 2  // left shift:  0b101000 = 40 (multiply by 4)
a >> 1  // right shift: 0b0101  = 5  (divide by 2)
```

**Bit tricks used in competitive programming:**
```cpp
// Check if bit k is set
bool is_set = (n >> k) & 1;

// Set bit k
n |= (1 << k);

// Clear bit k
n &= ~(1 << k);

// Toggle bit k
n ^= (1 << k);

// Check if n is power of 2
bool is_pow2 = n > 0 && (n & (n-1)) == 0;

// Count set bits (C++20)
#include <bit>
int count = __builtin_popcount(n);  // GCC built-in
```

---

## Part 5 — Input and Output

### Basic I/O

```cpp
#include <iostream>
using namespace std;

int main() {
    int n;
    cin >> n;           // read integer

    double x;
    cin >> x;           // read double

    string s;
    cin >> s;           // reads word (stops at whitespace)

    string line;
    getline(cin, line); // reads entire line including spaces

    cout << "n = " << n << "\n";
    cout << "x = " << x << endl;  // endl flushes buffer (slower)
    cout << "s = " << s << "\n";  // "\n" is faster than endl
}
```

### Formatted Output

```cpp
#include <iomanip>

double pi = 3.14159265;
cout << fixed << setprecision(2) << pi;    // 3.14
cout << fixed << setprecision(5) << pi;    // 3.14159
cout << scientific << pi;                   // 3.141593e+00
cout << setw(10) << 42;                    // "        42" (right-aligned)
cout << left << setw(10) << 42;            // "42        " (left-aligned)
cout << setfill('0') << setw(5) << 42;     // "00042"
```

### Fast I/O for Competitive Programming

```cpp
ios_base::sync_with_stdio(false);
cin.tie(NULL);
```

These two lines speed up cin/cout to near scanf/printf speed. Add them at the start of `main()` in every competitive programming solution. **Do not mix cin/cout with scanf/printf after using these.**

### Reading Multiple Values

```cpp
// Read n numbers
int n;
cin >> n;
vector<int> arr(n);
for (int i = 0; i < n; i++)
    cin >> arr[i];

// Read until EOF
int x;
while (cin >> x)
    process(x);

// Read line by line
string line;
while (getline(cin, line))
    process(line);
```

---

## Part 6 — Control Flow

### If-Else

```cpp
int x = 15;

if (x > 10) {
    cout << "greater than 10\n";
} else if (x > 5) {
    cout << "greater than 5\n";
} else {
    cout << "5 or less\n";
}

// Ternary operator — compact if-else
int abs_x = (x >= 0) ? x : -x;
string msg = (x > 0) ? "positive" : "non-positive";
```

### Switch

```cpp
int day = 3;
switch (day) {
    case 1: cout << "Monday"; break;
    case 2: cout << "Tuesday"; break;
    case 3: cout << "Wednesday"; break;
    // ...
    default: cout << "Invalid day";
}
```

**Always include `break`** unless you intend fall-through. Fall-through is a common bug source.

### Loops

```cpp
// For loop
for (int i = 0; i < n; i++) {
    // runs n times, i = 0,1,...,n-1
}

// While loop
int i = 0;
while (i < n) {
    i++;
}

// Do-while (executes at least once)
do {
    cin >> n;
} while (n < 0);  // keep asking until valid input

// Range-based for (C++11)
vector<int> v = {1, 2, 3, 4, 5};
for (int x : v)
    cout << x << " ";

for (auto& x : v)  // use & to modify elements
    x *= 2;
```

### Loop Control

```cpp
for (int i = 0; i < 10; i++) {
    if (i == 3) continue;  // skip i=3, go to next iteration
    if (i == 7) break;     // exit loop entirely
    cout << i << " ";      // prints: 0 1 2 4 5 6
}

// goto — avoid in general, but sometimes used in competitive programming
// to break out of nested loops
outer:
for (int i = 0; i < n; i++)
    for (int j = 0; j < n; j++)
        if (arr[i][j] == target)
            goto found;
found:
    cout << "found\n";
```

---

## Practice Problems

**Types and Operations:**

1. What is the output?
   ```cpp
   int a = 7, b = 2;
   cout << a/b << " " << a%b << " " << (double)a/b;
   ```

2. What is the value of `x` after: `int x = 5; cout << x++ + ++x;`

3. Write a program that reads an integer and prints whether it's odd or even.

4. What value does `5 & 3` evaluate to? What about `5 | 3`? `5 ^ 3`?

**Control Flow:**

5. Print all numbers from 1 to 100. For multiples of 3 print "Fizz", for multiples of 5 print "Buzz", for multiples of both print "FizzBuzz".

6. Read n integers and print their sum, min, and max.

7. Print the following pattern for n=4:
   ```
   *
   **
   ***
   ****
   ```

8. Write a program to check if a number is prime.

---

## Answers to Selected Problems

**Problem 1:**
```
3 1 3.5
```

**Problem 2:**
```cpp
int x = 5;
cout << x++ + ++x;
// x++ evaluates to 5, then x becomes 6
// ++x increments x to 7, evaluates to 7
// output: 5+7 = 12, x is now 7
// Note: behavior is actually undefined in C++ (two modifications of x in same expression)
// Avoid writing code like this
```

**Problem 4:**
```
5 & 3 = 101 & 011 = 001 = 1
5 | 3 = 101 | 011 = 111 = 7
5 ^ 3 = 101 ^ 011 = 110 = 6
```

**Problem 5 (FizzBuzz):**
```cpp
for (int i = 1; i <= 100; i++) {
    if (i % 15 == 0) cout << "FizzBuzz\n";
    else if (i % 3 == 0) cout << "Fizz\n";
    else if (i % 5 == 0) cout << "Buzz\n";
    else cout << i << "\n";
}
```

**Problem 8 (Prime check):**
```cpp
bool isPrime(int n) {
    if (n < 2) return false;
    if (n == 2) return true;
    if (n % 2 == 0) return false;
    for (int i = 3; i * i <= n; i += 2)
        if (n % i == 0) return false;
    return true;
}
```

---

## References

- Stroustrup, B. — *The C++ Programming Language* (4th ed.)
- Lippman, Lajoie, Moo — *C++ Primer* (5th ed.) — best beginner book
- cppreference.com — [Complete C++ reference](https://en.cppreference.com)
- LearnCpp.com — [Free comprehensive C++ tutorial](https://www.learncpp.com)
- Competitive Programmer's Handbook — [Free PDF](https://cses.fi/book/book.pdf)
