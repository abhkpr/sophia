# C++

## Overview

C++ is a general-purpose programming language created by Bjarne Stroustrup as an extension of C. It adds object-oriented programming, generic programming, and low-level memory manipulation while maintaining C's performance characteristics.

C++ compiles directly to machine code, giving it performance comparable to C while offering high-level abstractions. It is widely used in systems programming, game development, competitive programming, embedded systems, and performance-critical applications.

## Why Learn C++?

**Performance** — C++ gives you control over memory layout, cache behavior, and hardware. When performance matters at the microsecond level, C++ is the tool.

**Competitive Programming** — C++ is the dominant language in competitive programming because of its performance and the STL (Standard Template Library) which provides ready-made data structures and algorithms.

**Understanding fundamentals** — writing C++ forces you to understand pointers, memory allocation, and how computers actually work. This knowledge transfers to every other language.

## Basic Program Structure

```cpp
#include <iostream>
using namespace std;

int main() {
    cout << "Hello, World!" << endl;
    return 0;
}
```

- `#include <iostream>` — includes the input/output library
- `using namespace std` — avoids writing `std::` before standard library names
- `main()` — entry point of every C++ program
- `return 0` — signals successful execution to the OS

## Compilation

C++ is compiled, not interpreted. Source code → object code → executable:

```bash
g++ -o program program.cpp      # compile
./program                        # run

g++ -O2 -o program program.cpp  # compile with optimization
g++ -std=c++17 -o prog prog.cpp # use C++17 standard
```

## Topics in This Section

- Variables and Data Types
- Control Flow
- Functions
- Arrays and Strings
- Pointers and References
- Object-Oriented Programming
- Templates
- STL — Standard Template Library
- Memory Management
- Competitive Programming Patterns
