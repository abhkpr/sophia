# Templates and Generic Programming

## The Problem Templates Solve

Imagine writing a `max` function. You write one for `int`, then realize you need it for `double`, then `string`, then your custom `Student` class. Without templates, you write four nearly identical functions. With templates, you write one.

**Templates let you write code that works for any type** — the compiler generates the specific version for each type you actually use.

---

## Part 1 — Function Templates

### Basic Syntax

```cpp
template <typename T>
T maximum(T a, T b) {
    return (a > b) ? a : b;
}

// Usage
cout << maximum(3, 5);          // T = int → returns 5
cout << maximum(3.14, 2.72);    // T = double → returns 3.14
cout << maximum("abc", "xyz");  // T = string → returns "xyz"
```

The compiler generates separate functions for each type — this is called **template instantiation**.

### Multiple Type Parameters

```cpp
template <typename T, typename U>
auto add(T a, U b) {
    return a + b;  // auto return type deduced
}

cout << add(3, 4.5);    // int + double = double
cout << add(1, 2);      // int + int = int
```

### Explicit Instantiation

Sometimes the compiler can't deduce the type:

```cpp
template <typename T>
T zero() {
    return T(0);  // no parameters to deduce from
}

cout << zero<int>();     // explicitly say T = int
cout << zero<double>();  // T = double
```

### Template Specialization

Provide a different implementation for a specific type:

```cpp
template <typename T>
void print(T val) {
    cout << val << "\n";
}

// Specialization for bool
template <>
void print<bool>(bool val) {
    cout << (val ? "true" : "false") << "\n";
}

print(42);     // uses general template → "42"
print(true);   // uses specialization → "true"
```

---

## Part 2 — Class Templates

### Basic Class Template

```cpp
template <typename T>
class Stack {
private:
    vector<T> data;

public:
    void push(const T& val) {
        data.push_back(val);
    }

    void pop() {
        if (!empty()) data.pop_back();
    }

    T& top() {
        return data.back();
    }

    bool empty() const {
        return data.empty();
    }

    int size() const {
        return data.size();
    }
};

// Usage
Stack<int> intStack;
intStack.push(1);
intStack.push(2);
cout << intStack.top();  // 2

Stack<string> strStack;
strStack.push("hello");
strStack.push("world");
cout << strStack.top();  // "world"
```

### Template with Non-Type Parameters

```cpp
template <typename T, int SIZE>
class FixedArray {
private:
    T data[SIZE];
    int count = 0;

public:
    void add(const T& val) {
        if (count < SIZE) data[count++] = val;
    }

    T& operator[](int i) { return data[i]; }
    int size() const { return count; }
};

FixedArray<int, 10> arr;    // array of 10 ints
FixedArray<double, 5> darr; // array of 5 doubles
```

### Implementing a Generic Pair

```cpp
template <typename First, typename Second>
class Pair {
public:
    First first;
    Second second;

    Pair(First f, Second s) : first(f), second(s) {}

    void swap() {
        // Only works if First == Second
        std::swap(first, second);
    }

    bool operator<(const Pair& other) const {
        if (first != other.first) return first < other.first;
        return second < other.second;
    }
};

Pair<int, string> p(1, "Alice");
cout << p.first << " " << p.second;
```

---

## Part 3 — Template Constraints (C++20 Concepts)

Templates accept any type by default — but some types don't make sense:

```cpp
template <typename T>
T maximum(T a, T b) {
    return (a > b) ? a : b;  // requires > operator
}

// maximum(complex<double>(1,2), complex<double>(3,4)) would fail at compile time
// — complex numbers don't support >
```

**Concepts (C++20)** let you express constraints:

```cpp
#include <concepts>

template <typename T>
requires std::totally_ordered<T>  // T must support comparison
T maximum(T a, T b) {
    return (a > b) ? a : b;
}

// Or shorthand:
auto maximum(std::totally_ordered auto a, std::totally_ordered auto b) {
    return (a > b) ? a : b;
}
```

**Pre-C++20 approach — SFINAE** (Substitution Failure Is Not An Error):

```cpp
#include <type_traits>

template <typename T>
typename enable_if<is_arithmetic<T>::value, T>::type
absolute(T x) {
    return x < 0 ? -x : x;
}

// absolute(5) works, absolute("hello") gives clear error
```

---

## Part 4 — Variadic Templates (C++11)

Templates with a variable number of parameters:

```cpp
// Base case
void print() {}

// Variadic template
template <typename T, typename... Args>
void print(T first, Args... rest) {
    cout << first << " ";
    print(rest...);  // recursively print remaining
}

print(1, 2.5, "hello", true);
// output: 1 2.5 hello 1
```

**Fold expressions (C++17)** — cleaner:

```cpp
template <typename... Args>
auto sum(Args... args) {
    return (args + ...);  // fold expression
}

cout << sum(1, 2, 3, 4, 5);  // 15
cout << sum(1.0, 2.5, 3.7);  // 7.2
```

---

## Part 5 — Template Metaprogramming

Templates can compute values at **compile time** — no runtime cost.

### Compile-Time Factorial

```cpp
template <int N>
struct Factorial {
    static const int value = N * Factorial<N-1>::value;
};

template <>
struct Factorial<0> {
    static const int value = 1;
};

cout << Factorial<5>::value;  // 120 — computed at compile time!
```

### constexpr Functions (Modern Approach)

```cpp
constexpr int factorial(int n) {
    return n <= 1 ? 1 : n * factorial(n-1);
}

constexpr int result = factorial(5);  // evaluated at compile time
int arr[factorial(5)];                // array of 120 elements
```

### Type Traits

Query properties of types at compile time:

```cpp
#include <type_traits>

is_integral<int>::value       // true
is_integral<double>::value    // false
is_pointer<int*>::value       // true
is_same<int, long>::value     // false (platform-dependent)

// Use in templates
template <typename T>
void process(T val) {
    if constexpr (is_integral_v<T>) {
        cout << "integer: " << val << "\n";
    } else if constexpr (is_floating_point_v<T>) {
        cout << fixed << setprecision(2) << val << "\n";
    } else {
        cout << "other: " << val << "\n";
    }
}
```

---

## Part 6 — The STL Iterator Model

Understanding iterators lets you use STL algorithms with any container.

### Iterator Categories

```
Input Iterator      → read once, forward only (istream)
Output Iterator     → write once, forward only (ostream)
Forward Iterator    → read/write, forward only (forward_list)
Bidirectional       → forward and backward (list, set, map)
Random Access       → jump to any position (vector, deque, array)
```

### Iterator Operations

```cpp
vector<int> v = {1, 2, 3, 4, 5};

auto it = v.begin();  // points to first element
auto end = v.end();   // points past last element

*it;            // dereference — get value (1)
++it;           // advance (points to 2)
--it;           // go back (points to 1)
it + 3;         // random access (points to 4) — only random access iterators
it[2];          // same as *(it + 2)

end - it;       // distance between iterators
it < end;       // comparison

// Distance
distance(v.begin(), v.end());  // 5 — works for all iterator types

// Advance
advance(it, 3);  // move forward 3 positions — works for all types
```

### Writing a Generic Function

```cpp
// Works with any container that has begin/end
template <typename Container>
void printAll(const Container& c) {
    for (const auto& elem : c)
        cout << elem << " ";
    cout << "\n";
}

printAll(vector<int>{1,2,3});
printAll(set<string>{"a","b","c"});
printAll(array<double, 3>{1.1, 2.2, 3.3});
```

---

## Practice Problems

1. Write a template function `clamp(value, min, max)` that returns value clamped to [min, max].

2. Write a template class `MinStack` that supports push, pop, top, and getMin in O(1).

3. Write a variadic template function `maximum` that returns the maximum of any number of arguments.

4. Write a template function `contains(container, value)` that returns true if the container holds the value.

5. What is the output?
   ```cpp
   template <int N>
   struct Fib {
       static const int value = Fib<N-1>::value + Fib<N-2>::value;
   };
   template <> struct Fib<0> { static const int value = 0; };
   template <> struct Fib<1> { static const int value = 1; };
   cout << Fib<7>::value;
   ```

---

## Answers to Selected Problems

**Problem 1:**
```cpp
template <typename T>
T clamp(T value, T lo, T hi) {
    return max(lo, min(value, hi));
}
```

**Problem 2:**
```cpp
template <typename T>
class MinStack {
    stack<T> st;
    stack<T> minSt;
public:
    void push(T val) {
        st.push(val);
        if (minSt.empty() || val <= minSt.top())
            minSt.push(val);
    }
    void pop() {
        if (st.top() == minSt.top()) minSt.pop();
        st.pop();
    }
    T top() { return st.top(); }
    T getMin() { return minSt.top(); }
};
```

**Problem 3:**
```cpp
template <typename T>
T maximum(T a) { return a; }

template <typename T, typename... Args>
T maximum(T first, Args... rest) {
    return max(first, maximum(rest...));
}

cout << maximum(3, 1, 4, 1, 5, 9);  // 9
```

**Problem 5:** Output is `13` (7th Fibonacci number: 0,1,1,2,3,5,8,13).

---

## References

- Stroustrup, B. — *The C++ Programming Language* — Chapters 23-25
- Vandevoorde, Josuttis — *C++ Templates: The Complete Guide* (advanced)
- cppreference.com — [Templates](https://en.cppreference.com/w/cpp/language/templates)
- C++20 Concepts — [cppreference](https://en.cppreference.com/w/cpp/language/constraints)
