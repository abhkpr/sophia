# Arrays

## Definition

An **array** is a contiguous block of memory that stores elements of the same type. Elements are accessed by index in O(1) time.

```cpp
int arr[5] = {10, 20, 30, 40, 50};
cout << arr[2]; // 30 — O(1) access
```

## Memory Layout

Arrays are stored in contiguous memory. If an integer takes 4 bytes and the array starts at address 1000:

```
Index:   0     1     2     3     4
Address: 1000  1004  1008  1012  1016
Value:   10    20    30    40    50
```

`arr[i]` is computed as `base_address + (i × element_size)` — this is why access is O(1) regardless of index.

## Time Complexity

| Operation | Time |
|-----------|------|
| Access by index | O(1) |
| Search (unsorted) | O(n) |
| Search (sorted, binary) | O(log n) |
| Insert at end | O(1) amortized |
| Insert at position | O(n) |
| Delete at position | O(n) |

## Dynamic Arrays

A **dynamic array** (like `vector` in C++ or `ArrayList` in Java) grows automatically when full. When capacity is exceeded, a new array of double the size is allocated and all elements are copied.

```cpp
#include <vector>
vector<int> v;
v.push_back(1);  // O(1) amortized
v.push_back(2);
v.push_back(3);
cout << v[1];    // O(1) — 2
```

The **amortized** O(1) for push_back comes from the doubling strategy. Most insertions are O(1). Occasional resize is O(n) but happens so rarely that the average cost per insertion stays O(1).

## Two Pointer Technique

Many array problems can be solved efficiently using two pointers moving toward each other or in the same direction.

**Example — find pair that sums to target in sorted array:**

```cpp
int left = 0, right = arr.size() - 1;
while (left < right) {
    int sum = arr[left] + arr[right];
    if (sum == target) return {left, right};
    else if (sum < target) left++;
    else right--;
}
```

Time: O(n) instead of O(n²) brute force.

## Sliding Window

Used for problems involving contiguous subarrays of fixed or variable size.

**Example — maximum sum subarray of size k:**

```cpp
int windowSum = 0, maxSum = 0;
for (int i = 0; i < k; i++) windowSum += arr[i];
maxSum = windowSum;

for (int i = k; i < arr.size(); i++) {
    windowSum += arr[i] - arr[i - k];
    maxSum = max(maxSum, windowSum);
}
```

Time: O(n) instead of O(nk) brute force.

## Common Patterns

- **Prefix sums** — precompute cumulative sums for O(1) range queries
- **Kadane's algorithm** — maximum subarray sum in O(n)
- **Dutch National Flag** — three-way partition in O(n)
- **Merge sorted arrays** — two pointer approach in O(m+n)
