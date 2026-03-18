# Pointers and Memory Management

## The Most Important Chapter in C++

Pointers are what make C++ both powerful and dangerous. They give you direct access to memory — the ability to create data structures of arbitrary shape, manage resources efficiently, and write code that runs close to the hardware. They also give you the ability to crash programs in spectacular ways if misused.

Understand pointers deeply. Everything else in C++ builds on this.

---

## Part 1 — Memory Model

### How Memory is Organized

When a program runs, the OS gives it memory organized into regions:

```
High addresses
┌─────────────────┐
│   Stack         │ ← local variables, function calls
│   (grows down)  │
├─────────────────┤
│                 │
│   (free space)  │
│                 │
├─────────────────┤
│   Heap          │ ← dynamic allocation (new/delete)
│   (grows up)    │
├─────────────────┤
│   BSS           │ ← uninitialized global/static variables
├─────────────────┤
│   Data          │ ← initialized global/static variables
├─────────────────┤
│   Text (Code)   │ ← compiled program instructions
└─────────────────┘
Low addresses
```

**Stack:** Fast, automatic management. Variables are created when a function is called and destroyed when it returns. Limited size (~1-8 MB typically).

**Heap:** Slower, manual management. You control when memory is allocated and freed. Limited only by available RAM.

---

## Part 2 — Pointers

### What is a Pointer?

A **pointer** is a variable that stores the memory address of another variable.

**Analogy:** If a variable is a house, a pointer is the street address of that house. The address tells you where to find the house, but the address itself isn't the house.

```cpp
int x = 42;
int* ptr = &x;  // ptr stores the address of x

cout << x;      // 42    — the value at x
cout << &x;     // 0x7ffd... — the address of x
cout << ptr;    // 0x7ffd... — the address stored in ptr (same as &x)
cout << *ptr;   // 42    — dereferencing: value at the address ptr holds
```

**Two key operators:**
- `&` (address-of): gives the address of a variable
- `*` (dereference): gives the value at a memory address

### Pointer Declarations

```cpp
int*    ptr;     // pointer to int
double* dptr;    // pointer to double
char*   cptr;    // pointer to char
int**   pptr;    // pointer to pointer to int

// Style note — * belongs to the variable, not the type
int* a, b;  // a is int*, b is int (not int*)
int *a, *b; // both are int* — clearer
```

### Null Pointers

A pointer that doesn't point to anything valid:

```cpp
int* ptr = nullptr;  // C++11 — prefer this
int* ptr2 = NULL;    // old C style
int* ptr3 = 0;       // also works but avoid

// Always check before dereferencing
if (ptr != nullptr)
    cout << *ptr;
```

**Never dereference a null pointer** — it's undefined behavior (usually a crash).

### Pointer Arithmetic

Pointers support arithmetic that moves by the size of the pointed-to type:

```cpp
int arr[] = {10, 20, 30, 40, 50};
int* ptr = arr;  // points to arr[0]

cout << *ptr;      // 10
cout << *(ptr+1);  // 20 — moves 4 bytes forward (sizeof int)
cout << *(ptr+2);  // 30

ptr++;             // ptr now points to arr[1]
cout << *ptr;      // 20

// arr[i] is equivalent to *(arr + i)
```

### Pointers and Arrays

In most contexts, an array name decays to a pointer to its first element:

```cpp
int arr[5] = {1, 2, 3, 4, 5};
int* ptr = arr;  // points to arr[0]

// These are equivalent:
arr[3] == *(arr + 3) == ptr[3] == *(ptr + 3)  // all equal 4
```

**Key difference:** `arr` is a constant pointer — can't do `arr++`. `ptr` is a pointer variable — can increment.

---

## Part 3 — References

### References vs Pointers

A **reference** is an alias — another name for an existing variable.

```cpp
int x = 42;
int& ref = x;   // ref is another name for x

ref = 100;       // modifies x
cout << x;       // 100

// References vs pointers:
// - References must be initialized, can't be null, can't be reassigned
// - Pointers can be null, can be reassigned, need dereferencing syntax
```

**When to use which:**
```
Reference:  when you always have a valid target and won't reassign
Pointer:    when you might not have a value (nullable), or need to reassign
```

### Const Pointers

Four combinations:

```cpp
int x = 10, y = 20;

int* ptr = &x;           // can change ptr, can change *ptr
const int* ptr2 = &x;   // can change ptr2, CANNOT change *ptr2
int* const ptr3 = &x;   // CANNOT change ptr3, can change *ptr3
const int* const ptr4 = &x; // CANNOT change either

// Reading: right to left
// ptr3: ptr3 is a const pointer to int
// ptr2: ptr2 is a pointer to const int
```

---

## Part 4 — Dynamic Memory

### Stack vs Heap Allocation

```cpp
// Stack — automatic, fast, limited size
void function() {
    int x = 5;          // on stack
    int arr[1000];      // on stack
}   // x and arr automatically destroyed here

// Heap — manual, slower, large
void function() {
    int* x = new int(5);         // on heap
    int* arr = new int[1000];    // on heap
    // must manually free:
    delete x;
    delete[] arr;
}   // memory still exists after function returns unless deleted
```

### new and delete

```cpp
// Allocate single value
int* ptr = new int;       // uninitialized
int* ptr2 = new int(42);  // initialized to 42
int* ptr3 = new int{42};  // same, brace syntax

// Allocate array
int* arr = new int[10];       // uninitialized
int* arr2 = new int[10]();    // all zeros
int* arr3 = new int[10]{1,2,3}; // partially initialized

// Free memory
delete ptr;     // free single value
delete[] arr;   // free array — MUST use [] for arrays

ptr = nullptr;  // good practice after delete
```

### Memory Leaks

Forgetting to `delete` = memory leak. The memory is never returned to the OS:

```cpp
void badFunction() {
    int* ptr = new int[1000];
    // ... do something ...
    return;  // forgot delete[] ptr — 4KB leaked every call!
}

// With 1000 calls, 4MB leaked.
// Long-running programs eventually crash.
```

**Detect leaks:** Use `-fsanitize=address` or Valgrind.

### Dangling Pointers

Pointer to memory that has been freed:

```cpp
int* ptr = new int(42);
delete ptr;
cout << *ptr;  // undefined behavior — ptr is dangling!
ptr = nullptr; // safe: set to null after delete
```

### Double Free

Freeing memory twice — undefined behavior:

```cpp
int* ptr = new int(42);
delete ptr;
delete ptr;  // crash or corruption!
ptr = nullptr; // prevents this: delete nullptr is safe
```

---

## Part 5 — Smart Pointers (C++11)

Modern C++ provides smart pointers that manage memory automatically — like garbage collection but without the overhead.

```cpp
#include <memory>
```

### unique_ptr

Owns the resource exclusively. Automatically deletes when it goes out of scope.

```cpp
unique_ptr<int> ptr = make_unique<int>(42);
cout << *ptr;      // 42
// No need to delete — destroyed automatically when ptr goes out of scope

unique_ptr<int[]> arr = make_unique<int[]>(10);
arr[0] = 5;        // access like array

// Can't copy, can only move
unique_ptr<int> ptr2 = move(ptr);  // ownership transferred
// ptr is now null, ptr2 owns the memory
```

### shared_ptr

Multiple owners. Deleted when the last owner is destroyed.

```cpp
shared_ptr<int> ptr1 = make_shared<int>(42);
shared_ptr<int> ptr2 = ptr1;  // both own the same int
cout << ptr1.use_count();      // 2 — two owners

ptr1.reset();  // ptr1 releases ownership
cout << ptr2.use_count();  // 1 — only ptr2 owns it
// memory freed when ptr2 also goes out of scope
```

### weak_ptr

Non-owning reference to a shared_ptr. Used to break circular references.

```cpp
shared_ptr<int> sp = make_shared<int>(42);
weak_ptr<int> wp = sp;  // doesn't increase reference count
cout << wp.use_count();  // 1 — only sp owns it

if (auto locked = wp.lock()) {  // get a shared_ptr if still alive
    cout << *locked;
}
```

**Rule of thumb for modern C++:**
```
Default:    use unique_ptr
Shared:     use shared_ptr
No ownership: use raw pointer or reference
Never:      use raw new/delete in application code
```

---

## Part 6 — Common Patterns

### Swap Using Pointers

```cpp
void swap(int* a, int* b) {
    int temp = *a;
    *a = *b;
    *b = temp;
}

int x = 5, y = 10;
swap(&x, &y);  // pass addresses
cout << x << " " << y;  // 10 5
```

### Dynamic 2D Array

```cpp
int rows = 3, cols = 4;

// Allocate
int** matrix = new int*[rows];
for (int i = 0; i < rows; i++)
    matrix[i] = new int[cols];

// Use
matrix[1][2] = 42;

// Free (reverse order!)
for (int i = 0; i < rows; i++)
    delete[] matrix[i];
delete[] matrix;

// Better: use vector<vector<int>> instead
```

### Linked List Node

```cpp
struct Node {
    int data;
    Node* next;

    Node(int val) : data(val), next(nullptr) {}
};

// Create nodes
Node* head = new Node(1);
head->next = new Node(2);
head->next->next = new Node(3);

// Traverse
Node* curr = head;
while (curr != nullptr) {
    cout << curr->data << " ";
    curr = curr->next;
}

// Free (must traverse and delete)
curr = head;
while (curr != nullptr) {
    Node* next = curr->next;
    delete curr;
    curr = next;
}
```

---

## Practice Problems

**Pointers:**

1. What is the output?
   ```cpp
   int x = 10;
   int* p = &x;
   *p = 20;
   cout << x;
   ```

2. What is the output?
   ```cpp
   int arr[] = {5, 10, 15, 20};
   int* p = arr + 2;
   cout << *p << " " << *(p-1) << " " << p[1];
   ```

3. Write a function `reverseArray(int* arr, int n)` that reverses an array in-place using pointers.

4. What's the difference between `const int* p` and `int* const p`?

**Dynamic Memory:**

5. Write a function that dynamically allocates an array of n integers, fills it with values 1 to n, and returns the pointer. (Caller must free.)

6. What's wrong with this code?
   ```cpp
   int* getArray() {
       int arr[5] = {1, 2, 3, 4, 5};
       return arr;
   }
   ```

7. Rewrite problem 5 using `unique_ptr`.

---

## Answers to Selected Problems

**Problem 1:** `20` — `*p = 20` modifies x through the pointer.

**Problem 2:** `15 10 20`

**Problem 3:**
```cpp
void reverseArray(int* arr, int n) {
    int* left = arr;
    int* right = arr + n - 1;
    while (left < right) {
        int temp = *left;
        *left = *right;
        *right = temp;
        left++;
        right--;
    }
}
```

**Problem 4:**
```
const int* p: p can change (point elsewhere), *p cannot be modified
int* const p: p cannot change (fixed address), *p can be modified
```

**Problem 6:**
```
Returns pointer to a local array.
Local array lives on the stack.
When function returns, stack frame is destroyed.
Pointer now points to invalid memory — undefined behavior.

Fix: allocate on heap with new, or better, return a vector.
```

**Problem 7:**
```cpp
unique_ptr<int[]> getArray(int n) {
    auto arr = make_unique<int[]>(n);
    for (int i = 0; i < n; i++)
        arr[i] = i + 1;
    return arr;  // ownership transferred to caller
}  // automatically freed when caller's unique_ptr goes out of scope
```

---

## References

- Stroustrup, B. — *The C++ Programming Language* — Chapter 7
- Lippman et al. — *C++ Primer* — Chapter 12 (Dynamic Memory)
- cppreference.com — [Pointer declaration](https://en.cppreference.com/w/cpp/language/pointer), [Memory management](https://en.cppreference.com/w/cpp/memory)
- Herb Sutter — [GotW #91: Smart Pointer Parameters](https://herbsutter.com/2013/06/05/gotw-91-solution-smart-pointer-parameters/)
