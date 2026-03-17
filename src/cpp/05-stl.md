# STL — Standard Template Library

## What is the STL?

The STL is a collection of ready-made data structures and algorithms included with every C++ compiler. Instead of implementing a binary search tree, hash table, or sorting algorithm from scratch, you use the STL versions — which are highly optimized, battle-tested, and work with each other.

**The STL has three parts:**
- **Containers** — data structures (vector, map, set, queue, ...)
- **Algorithms** — operations on data (sort, search, transform, ...)
- **Iterators** — the glue connecting containers and algorithms

---

## Part 1 — Vectors

The most important container. A dynamic array that grows automatically.

```cpp
#include <vector>

vector<int> v;               // empty
vector<int> v2(5);           // 5 zeros
vector<int> v3(5, 7);        // {7, 7, 7, 7, 7}
vector<int> v4 = {1, 2, 3};  // initializer list
```

### Essential Operations

```cpp
vector<int> v = {1, 2, 3, 4, 5};

// Size and capacity
v.size();       // 5 — number of elements
v.empty();      // false — is it empty?
v.capacity();   // >= 5 — allocated space

// Access
v[0];           // 1 — no bounds check
v.at(0);        // 1 — throws if out of bounds
v.front();      // 1 — first element
v.back();       // 5 — last element

// Modify
v.push_back(6);     // {1,2,3,4,5,6} — add to end
v.pop_back();       // {1,2,3,4,5} — remove from end
v.insert(v.begin() + 2, 99);  // {1,2,99,3,4,5} — insert at position
v.erase(v.begin() + 2);       // removes element at position 2
v.clear();          // empty the vector

// Resize
v.resize(10);       // extend to size 10 (new elements = 0)
v.resize(3);        // shrink to size 3 (excess removed)
v.reserve(100);     // pre-allocate space for 100 (no size change)
```

### Iteration

```cpp
vector<int> v = {1, 2, 3, 4, 5};

// Range-based (simplest)
for (int x : v)
    cout << x << " ";

// Index-based
for (int i = 0; i < v.size(); i++)
    cout << v[i] << " ";

// Iterator
for (auto it = v.begin(); it != v.end(); ++it)
    cout << *it << " ";

// Reverse
for (auto it = v.rbegin(); it != v.rend(); ++it)
    cout << *it << " ";
```

### 2D Vector

```cpp
int rows = 3, cols = 4;
vector<vector<int>> grid(rows, vector<int>(cols, 0));

grid[1][2] = 42;

// Iterate
for (auto& row : grid)
    for (int val : row)
        cout << val << " ";
```

### Time Complexities

| Operation | Time |
|-----------|------|
| push_back | O(1) amortized |
| pop_back | O(1) |
| Access [i] | O(1) |
| insert at position | O(n) |
| erase at position | O(n) |
| size | O(1) |

---

## Part 2 — Strings (STL)

```cpp
#include <string>
string s = "Hello, World!";

// Most operations same as shown in Functions chapter
// Additional useful ones:

// Transform
transform(s.begin(), s.end(), s.begin(), ::toupper);  // uppercase
transform(s.begin(), s.end(), s.begin(), ::tolower);  // lowercase

// Split by delimiter (no built-in, use stringstream)
#include <sstream>
string line = "one two three";
stringstream ss(line);
string word;
vector<string> words;
while (ss >> word)
    words.push_back(word);
// words = {"one", "two", "three"}
```

---

## Part 3 — Pairs and Tuples

```cpp
#include <utility>  // pair
#include <tuple>    // tuple

// Pair
pair<int, string> p = {1, "Alice"};
pair<int, string> p2 = make_pair(2, "Bob");
cout << p.first << " " << p.second;   // 1 Alice

// Tuple (3+ elements)
tuple<int, string, double> t = {1, "Alice", 3.14};
cout << get<0>(t) << " " << get<1>(t);  // 1 Alice
auto [id, name, score] = t;  // structured binding (C++17)
```

**Common use:** Returning multiple values from a function, sorting by multiple keys.

---

## Part 4 — Stack and Queue

### Stack (LIFO)

```cpp
#include <stack>

stack<int> st;
st.push(1);
st.push(2);
st.push(3);
cout << st.top();   // 3 — peek at top
st.pop();           // remove top
cout << st.top();   // 2
cout << st.size();  // 2
cout << st.empty(); // false
```

**Applications:** Function call stack, undo operations, bracket matching, DFS.

### Queue (FIFO)

```cpp
#include <queue>

queue<int> q;
q.push(1);
q.push(2);
q.push(3);
cout << q.front();  // 1 — first in
cout << q.back();   // 3 — last in
q.pop();            // remove front
cout << q.front();  // 2
```

**Applications:** BFS, task scheduling, printer queue.

### Priority Queue (Heap)

```cpp
#include <queue>

// Max-heap (default) — largest element on top
priority_queue<int> pq;
pq.push(3);
pq.push(1);
pq.push(4);
pq.push(1);
pq.push(5);
cout << pq.top();  // 5 — largest
pq.pop();
cout << pq.top();  // 4

// Min-heap — smallest element on top
priority_queue<int, vector<int>, greater<int>> minpq;
minpq.push(3); minpq.push(1); minpq.push(4);
cout << minpq.top();  // 1

// Custom comparator
auto cmp = [](pair<int,int> a, pair<int,int> b) {
    return a.second > b.second;  // sort by second element, min on top
};
priority_queue<pair<int,int>, vector<pair<int,int>>, decltype(cmp)> pq2(cmp);
```

**Applications:** Dijkstra's algorithm, scheduling, finding k-th largest/smallest.

---

## Part 5 — Deque

Double-ended queue — O(1) insert/remove at both ends:

```cpp
#include <deque>

deque<int> dq;
dq.push_back(3);    // add to back
dq.push_front(1);   // add to front
dq.push_back(4);
cout << dq.front(); // 1
cout << dq.back();  // 4
dq.pop_front();     // remove from front
dq.pop_back();      // remove from back
dq[1];              // random access
```

**Use case:** Sliding window problems, BFS where you need front and back access.

---

## Part 6 — Set and Multiset

### Set — Unique Sorted Elements

```cpp
#include <set>

set<int> s;
s.insert(3);
s.insert(1);
s.insert(4);
s.insert(1);  // duplicate — ignored
s.insert(5);
// s = {1, 3, 4, 5} — sorted, unique

s.count(3);    // 1 (exists) or 0 (doesn't)
s.find(3);     // iterator to 3, or s.end() if not found
s.erase(3);    // remove 3
s.size();      // 3
s.lower_bound(3);  // iterator to first element >= 3
s.upper_bound(3);  // iterator to first element > 3
```

**Time:** O(log n) for insert, find, erase.

### Multiset — Sorted with Duplicates

```cpp
multiset<int> ms;
ms.insert(3);
ms.insert(3);
ms.insert(1);
// ms = {1, 3, 3}

ms.count(3);    // 2
ms.erase(ms.find(3));  // remove ONE occurrence of 3
ms.erase(3);           // remove ALL occurrences of 3
```

---

## Part 7 — Map and Unordered Map

### Map — Sorted Key-Value Store

```cpp
#include <map>

map<string, int> scores;
scores["Alice"] = 95;
scores["Bob"] = 87;
scores["Charlie"] = 92;

// Access
cout << scores["Alice"];      // 95
cout << scores.at("Alice");   // 95 — throws if key not found
// scores["new_key"] creates entry with default value 0!

// Check existence
if (scores.count("Alice"))    // count is 0 or 1
    cout << "Alice found";
if (scores.find("Alice") != scores.end())
    cout << "Alice found";

// Iterate (in sorted key order)
for (auto& [name, score] : scores)
    cout << name << ": " << score << "\n";

// Erase
scores.erase("Bob");

// Useful pattern — frequency count
string text = "hello world";
map<char, int> freq;
for (char c : text)
    freq[c]++;
```

**Time:** O(log n) for all operations. Internally a red-black tree.

### Unordered Map — Hash Table

```cpp
#include <unordered_map>

unordered_map<string, int> scores;
scores["Alice"] = 95;
// Same interface as map, but:
// Average O(1) for insert/find/erase
// Worst case O(n) if many hash collisions
// NOT sorted
// Faster than map in most cases
```

**When to use which:**
```
map:           need sorted order, or ordered iteration
unordered_map: just need fast lookup, order doesn't matter
```

---

## Part 8 — Algorithms

All in `<algorithm>`. Work on any container via iterators.

### Sorting

```cpp
#include <algorithm>

vector<int> v = {3, 1, 4, 1, 5, 9, 2, 6};

sort(v.begin(), v.end());               // ascending: {1,1,2,3,4,5,6,9}
sort(v.begin(), v.end(), greater<int>()); // descending: {9,6,5,4,3,2,1,1}

// Custom comparator
sort(v.begin(), v.end(), [](int a, int b) { return abs(a) < abs(b); });

// Sort pairs by second element
vector<pair<int,int>> vp = {{1,3},{2,1},{3,2}};
sort(vp.begin(), vp.end(), [](auto& a, auto& b) { return a.second < b.second; });
// vp = {{2,1},{3,2},{1,3}}

// Stable sort (preserves relative order of equal elements)
stable_sort(v.begin(), v.end());
```

**Time:** O(n log n) for sort, O(n log n) for stable_sort.

### Searching

```cpp
vector<int> v = {1, 2, 3, 4, 5, 6, 7, 8, 9};

// Linear search
auto it = find(v.begin(), v.end(), 5);
if (it != v.end()) cout << "Found at index " << it - v.begin();

// Binary search (requires sorted array)
bool found = binary_search(v.begin(), v.end(), 5);  // true

// Lower bound — first element >= value
auto lb = lower_bound(v.begin(), v.end(), 5);  // points to 5
// Upper bound — first element > value
auto ub = upper_bound(v.begin(), v.end(), 5);  // points to 6

// Count occurrences in sorted array
int count = upper_bound(v.begin(), v.end(), 5)
           - lower_bound(v.begin(), v.end(), 5);
```

### Min, Max, Sum

```cpp
vector<int> v = {3, 1, 4, 1, 5, 9};

cout << *min_element(v.begin(), v.end());   // 1
cout << *max_element(v.begin(), v.end());   // 9

auto [mn, mx] = minmax_element(v.begin(), v.end());

#include <numeric>
int sum = accumulate(v.begin(), v.end(), 0);  // 23
```

### Useful Algorithms

```cpp
// Reverse
reverse(v.begin(), v.end());

// Rotate — move k elements from front to back
rotate(v.begin(), v.begin() + k, v.end());

// Remove duplicates (must sort first)
sort(v.begin(), v.end());
v.erase(unique(v.begin(), v.end()), v.end());

// Fill
fill(v.begin(), v.end(), 0);     // fill with 0
fill_n(v.begin(), 3, 7);         // fill first 3 elements with 7

// Count
int cnt = count(v.begin(), v.end(), 5);        // count 5s
int cnt2 = count_if(v.begin(), v.end(), [](int x){ return x > 3; });

// Any, all, none
bool anyPos = any_of(v.begin(), v.end(), [](int x){ return x > 0; });
bool allPos = all_of(v.begin(), v.end(), [](int x){ return x > 0; });

// Next/prev permutation
vector<int> p = {1, 2, 3};
do {
    for (int x : p) cout << x << " ";
    cout << "\n";
} while (next_permutation(p.begin(), p.end()));
// Prints all 6 permutations of {1,2,3}
```

---

## Part 9 — Competitive Programming Patterns

### Frequency Map

```cpp
// Count frequency of elements
vector<int> arr = {1, 2, 2, 3, 3, 3};
map<int, int> freq;
for (int x : arr) freq[x]++;
// freq = {1:1, 2:2, 3:3}

// Or with array (for small values)
int freq2[100] = {};
for (int x : arr) freq2[x]++;
```

### Coordinate Compression

When values are large but count is small:

```cpp
vector<int> arr = {1000000, 5, 999999, 5, 1000000};
vector<int> sorted = arr;
sort(sorted.begin(), sorted.end());
sorted.erase(unique(sorted.begin(), sorted.end()), sorted.end());

// Map each value to its rank
for (int& x : arr)
    x = lower_bound(sorted.begin(), sorted.end(), x) - sorted.begin();
// arr = {2, 0, 1, 0, 2}
```

### Sliding Window with Multiset

```cpp
// Find min/max in sliding window of size k
deque<int> dq;  // stores indices
vector<int> arr = {1,3,1,3,5,3,6,7};
int k = 3;

for (int i = 0; i < arr.size(); i++) {
    // remove elements outside window
    while (!dq.empty() && dq.front() < i - k + 1)
        dq.pop_front();
    // remove smaller elements (for min window)
    while (!dq.empty() && arr[dq.back()] >= arr[i])
        dq.pop_back();
    dq.push_back(i);
    if (i >= k - 1) cout << arr[dq.front()] << " ";
}
```

---

## Practice Problems

1. Given a vector of integers, find the k-th largest element using a priority queue.

2. Given a string, find the first non-repeating character.

3. Given an array, find all pairs that sum to a target value (use unordered_map).

4. Implement a function that takes a sorted array and removes duplicates in-place (return new size).

5. Given a vector of intervals, merge overlapping intervals.

6. Count the number of distinct elements in each window of size k.

---

## Answers to Selected Problems

**Problem 1:**
```cpp
int kthLargest(vector<int>& arr, int k) {
    priority_queue<int, vector<int>, greater<int>> minHeap;
    for (int x : arr) {
        minHeap.push(x);
        if (minHeap.size() > k) minHeap.pop();
    }
    return minHeap.top();
}
```

**Problem 2:**
```cpp
char firstUnique(string s) {
    map<char, int> freq;
    for (char c : s) freq[c]++;
    for (char c : s)
        if (freq[c] == 1) return c;
    return '\0';
}
```

**Problem 3:**
```cpp
vector<pair<int,int>> twoSum(vector<int>& arr, int target) {
    unordered_map<int, int> seen;
    vector<pair<int,int>> result;
    for (int i = 0; i < arr.size(); i++) {
        int complement = target - arr[i];
        if (seen.count(complement))
            result.push_back({seen[complement], i});
        seen[arr[i]] = i;
    }
    return result;
}
```

**Problem 5:**
```cpp
vector<pair<int,int>> mergeIntervals(vector<pair<int,int>>& intervals) {
    sort(intervals.begin(), intervals.end());
    vector<pair<int,int>> result;
    for (auto& [start, end] : intervals) {
        if (!result.empty() && start <= result.back().second)
            result.back().second = max(result.back().second, end);
        else
            result.push_back({start, end});
    }
    return result;
}
```

---

## References

- cppreference.com — [STL Containers](https://en.cppreference.com/w/cpp/container), [Algorithms](https://en.cppreference.com/w/cpp/algorithm)
- Lippman et al. — *C++ Primer* — Part III (The STL)
- Competitive Programmer's Handbook — [Chapter 4-5](https://cses.fi/book/book.pdf)
- CSES Problem Set — [Practice problems](https://cses.fi/problemset/)
