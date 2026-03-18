# Functions and Arrays

## Part 1 — Functions

### Why Functions?

A function packages a computation under a name so you can reuse it. Without functions, every program would be a single massive block of code — unreadable, unmaintainable, impossible to test.

**Analogy:** A function is like a recipe. You write the recipe once (define it) and then cook it whenever you need (call it). The inputs are ingredients (parameters) and the output is the dish (return value).

### Function Anatomy

```cpp
return_type function_name(parameter_list) {
    // body
    return value;  // if not void
}

// Example
int add(int a, int b) {
    return a + b;
}

// Calling it
int result = add(3, 4);  // result = 7
```

### Return Types

```cpp
int square(int x) {
    return x * x;
}

void printHello() {   // void = no return value
    cout << "Hello\n";
    // no return needed (or use bare return;)
}

bool isEven(int n) {
    return n % 2 == 0;
}

double average(double a, double b) {
    return (a + b) / 2.0;
}
```

### Function Declarations (Prototypes)

C++ reads top to bottom. If `main` calls `square` before `square` is defined, you need a declaration:

```cpp
int square(int x);  // declaration (prototype) — just the signature

int main() {
    cout << square(5);  // works because declared above
    return 0;
}

int square(int x) {  // definition
    return x * x;
}
```

### Pass by Value vs Reference

**By value:** A copy is made. Original unchanged.

```cpp
void doubleIt(int x) {
    x *= 2;   // modifies local copy only
}

int main() {
    int a = 5;
    doubleIt(a);
    cout << a;  // still 5
}
```

**By reference (&):** No copy. Function operates on the original.

```cpp
void doubleIt(int& x) {
    x *= 2;   // modifies original
}

int main() {
    int a = 5;
    doubleIt(a);
    cout << a;  // 10 ✓
}
```

**By const reference:** Read-only access to the original — no copy, no modification.

```cpp
void print(const string& s) {
    // can read s but not modify it
    // efficient for large objects — no copy made
    cout << s;
}
```

**Rule of thumb:**
```
Small types (int, double, bool, char): pass by value
Large types (string, vector, struct):  pass by const reference
Want to modify:                        pass by reference
```

### Default Parameters

```cpp
int power(int base, int exp = 2) {  // exp defaults to 2
    int result = 1;
    for (int i = 0; i < exp; i++) result *= base;
    return result;
}

power(3);     // 3² = 9
power(3, 3);  // 3³ = 27
```

Default parameters must be at the end of the parameter list.

### Function Overloading

Multiple functions with the same name but different parameters:

```cpp
int max(int a, int b) {
    return a > b ? a : b;
}

double max(double a, double b) {
    return a > b ? a : b;
}

string max(string a, string b) {
    return a > b ? a : b;
}

max(3, 5);           // calls int version
max(3.0, 5.5);       // calls double version
max("abc", "xyz");   // calls string version
```

The compiler picks the right version based on argument types — this is called **overload resolution**.

### Recursion

A function that calls itself. Two parts:
1. **Base case:** The simplest case that doesn't recurse
2. **Recursive case:** Reduce the problem and recurse

```cpp
int factorial(int n) {
    if (n == 0) return 1;         // base case
    return n * factorial(n - 1);  // recursive case
}

// factorial(4)
// = 4 * factorial(3)
// = 4 * 3 * factorial(2)
// = 4 * 3 * 2 * factorial(1)
// = 4 * 3 * 2 * 1 * factorial(0)
// = 4 * 3 * 2 * 1 * 1 = 24
```

**Stack frames:** Each recursive call adds a frame to the call stack. Too deep recursion → stack overflow.

```cpp
// Fibonacci — naive recursion
int fib(int n) {
    if (n <= 1) return n;
    return fib(n-1) + fib(n-2);
}
// Time: O(2ⁿ) — exponential! Recalculates same values many times

// Fibonacci — with memoization
map<int,int> memo;
int fib(int n) {
    if (n <= 1) return n;
    if (memo.count(n)) return memo[n];
    return memo[n] = fib(n-1) + fib(n-2);
}
// Time: O(n) — each value computed once
```

### Lambda Functions (C++11)

Anonymous functions — define and use inline:

```cpp
auto square = [](int x) { return x * x; };
cout << square(5);  // 25

// With capture — access local variables
int offset = 10;
auto addOffset = [offset](int x) { return x + offset; };

// Useful with algorithms
vector<int> v = {3, 1, 4, 1, 5, 9};
sort(v.begin(), v.end(), [](int a, int b) { return a > b; }); // descending sort
```

---

## Part 2 — Arrays

### Static Arrays

Fixed-size, stack-allocated. Size must be known at compile time.

```cpp
int arr[5];                         // uninitialized — contains garbage
int arr2[5] = {1, 2, 3, 4, 5};     // initialized
int arr3[5] = {1, 2};               // {1, 2, 0, 0, 0} — rest are zero
int arr4[] = {1, 2, 3, 4, 5};      // size inferred = 5
int arr5[5] = {};                   // {0, 0, 0, 0, 0} — all zeros
```

**Accessing elements:**
```cpp
cout << arr2[0];   // 1 — zero-indexed
cout << arr2[4];   // 5 — last element
arr2[2] = 99;      // modify element
```

**No bounds checking!** `arr[5]` on a size-5 array is undefined behavior — may crash, may corrupt memory, may silently work and cause bugs later.

### Arrays and Memory

Array elements are stored contiguously in memory:

```cpp
int arr[5] = {10, 20, 30, 40, 50};
// Memory: [10][20][30][40][50]
// Address: 100 104  108  112  116   (4 bytes each)

arr[i] == *(arr + i)  // arr is a pointer to the first element
```

### Passing Arrays to Functions

Arrays decay to pointers when passed to functions:

```cpp
void printArray(int arr[], int n) {
    // arr is actually int* here
    for (int i = 0; i < n; i++)
        cout << arr[i] << " ";
}

// Must pass size separately — sizeof won't work inside function
printArray(arr, 5);
```

### 2D Arrays

```cpp
int matrix[3][4];  // 3 rows, 4 columns

int grid[3][3] = {
    {1, 2, 3},
    {4, 5, 6},
    {7, 8, 9}
};

cout << grid[1][2];  // 6 (row 1, column 2)

// Traversal
for (int i = 0; i < 3; i++)
    for (int j = 0; j < 3; j++)
        cout << grid[i][j] << " ";
```

### std::array (C++11)

A safer, more modern fixed-size array:

```cpp
#include <array>

array<int, 5> arr = {1, 2, 3, 4, 5};
cout << arr.size();    // 5 — knows its own size
cout << arr.at(2);     // 3 — bounds-checked, throws exception if out of range
cout << arr[2];        // 3 — no bounds check, faster

// Can be passed to functions with size info preserved
void process(array<int, 5>& arr) { ... }
```

---

## Part 3 — Strings

### C-Style Strings (avoid in C++)

```cpp
char name[] = "Alice";   // stored as {'A','l','i','c','e','\0'}
// \0 is the null terminator — marks end of string
cout << strlen(name);    // 5 (not counting \0)
```

### std::string

Use this. Always.

```cpp
#include <string>

string s = "Hello";
string s2("World");
string s3(5, 'x');   // "xxxxx" — 5 copies of 'x'

// Size
cout << s.length();    // 5
cout << s.size();      // 5 — same thing

// Access
cout << s[0];          // 'H'
cout << s.at(0);       // 'H' — bounds-checked
cout << s.front();     // 'H'
cout << s.back();      // 'o'

// Concatenation
string full = s + " " + s2;   // "Hello World"
s += "!";                     // s = "Hello!"

// Comparison (lexicographic)
"abc" < "abd"   // true
"abc" == "abc"  // true

// Substrings
s = "Hello World";
cout << s.substr(6, 5);   // "World" — start at 6, length 5
cout << s.substr(6);      // "World" — from 6 to end

// Find
size_t pos = s.find("World");  // returns 6
if (pos != string::npos)       // string::npos means "not found"
    cout << "found at " << pos;

// Replace, insert, erase
s.replace(6, 5, "C++");  // "Hello C++"
s.insert(5, ",");         // "Hello, C++"
s.erase(5, 2);            // removes 2 chars starting at position 5

// Convert to/from number
string num_str = to_string(42);       // "42"
int num = stoi("42");                 // 42
double d = stod("3.14");              // 3.14

// Iterate
for (char c : s)
    cout << c;

for (int i = 0; i < s.size(); i++)
    cout << s[i];
```

---

## Practice Problems

**Functions:**

1. Write a function `isPalindrome(string s)` that returns true if s is a palindrome.

2. Write a recursive function to compute the sum 1² + 2² + 3² + ... + n².

3. Write an overloaded function `area` that computes:
   - Area of circle given radius
   - Area of rectangle given length and width
   - Area of triangle given base and height

4. What is the output?
   ```cpp
   void f(int x) { x = 10; }
   void g(int& x) { x = 10; }
   int a = 5, b = 5;
   f(a); g(b);
   cout << a << " " << b;
   ```

**Arrays:**

5. Write a function to find the second largest element in an array.

6. Write a function to rotate an array left by k positions.

7. Given a sorted array, write a function to find if a target value exists using binary search.

8. Write a function to merge two sorted arrays into one sorted array.

**Strings:**

9. Write a function to count the frequency of each character in a string.

10. Write a function to reverse words in a sentence ("Hello World" → "World Hello").

11. Check if two strings are anagrams of each other.

---

## Answers to Selected Problems

**Problem 1:**
```cpp
bool isPalindrome(string s) {
    int left = 0, right = s.size() - 1;
    while (left < right) {
        if (s[left] != s[right]) return false;
        left++; right--;
    }
    return true;
}
```

**Problem 4:**
```
5 10
f takes by value (copy), doesn't affect a.
g takes by reference, modifies b directly.
```

**Problem 5:**
```cpp
int secondLargest(int arr[], int n) {
    int first = INT_MIN, second = INT_MIN;
    for (int i = 0; i < n; i++) {
        if (arr[i] > first) {
            second = first;
            first = arr[i];
        } else if (arr[i] > second && arr[i] != first) {
            second = arr[i];
        }
    }
    return second;
}
```

**Problem 7 (Binary Search):**
```cpp
bool binarySearch(vector<int>& arr, int target) {
    int left = 0, right = arr.size() - 1;
    while (left <= right) {
        int mid = left + (right - left) / 2;  // avoids overflow
        if (arr[mid] == target) return true;
        else if (arr[mid] < target) left = mid + 1;
        else right = mid - 1;
    }
    return false;
}
```

**Problem 11:**
```cpp
bool isAnagram(string a, string b) {
    if (a.size() != b.size()) return false;
    sort(a.begin(), a.end());
    sort(b.begin(), b.end());
    return a == b;
    // Or: use frequency array for O(n) solution
}
```

---

## References

- Lippman, Lajoie, Moo — *C++ Primer* — Chapters 6, 3
- cppreference.com — [Functions](https://en.cppreference.com/w/cpp/language/functions), [string](https://en.cppreference.com/w/cpp/string/basic_string)
- LearnCpp.com — [Chapter 2 (Functions), Chapter 17 (Arrays)](https://www.learncpp.com)
