# Arrays

## The Foundation of All Data Structures

An array is a contiguous block of memory holding elements of the same type. Almost every other data structure is built on arrays or inspired by them.

**Real-world analogy:** A row of numbered post-office boxes. Every box has a fixed number (index), the same size, next to its neighbors. To reach box 47, you go directly — not through boxes 1 to 46. That directness is what makes arrays O(1) access.

---

## Part 1 — Memory Layout

```cpp
int arr[5] = {10, 20, 30, 40, 50};
```

```
Memory Address:  1000   1004   1008   1012   1016
Value stored:     10     20     30     40     50
Array index:     [0]    [1]    [2]    [3]    [4]
```

**Why O(1) access:**
```
address of arr[i] = base_address + (i × sizeof(element))
address of arr[3] = 1000 + (3 × 4) = 1012   ← one multiply + one add
```

**Cache friendliness:** CPUs fetch 64 bytes (a cache line = 16 integers) at once. Accessing arr[0] loads arr[0..15] into cache. arr[1] through arr[15] are then instant. This makes arrays much faster than linked lists in practice despite the same algorithmic complexity.

---

## Part 2 — Static vs Dynamic Arrays

```cpp
// Static — size fixed at compile time, lives on stack
int arr[100];
int arr2[5] = {1, 2, 3, 4, 5};
int arr3[5] = {};     // all zeros

// Dynamic — std::vector (use this in C++)
#include <vector>
vector<int> v;             // empty
vector<int> v2(5, 0);      // {0,0,0,0,0}
vector<int> v3 = {1,2,3};  // initializer list

v.push_back(10);     // add to end — O(1) amortized
v.pop_back();        // remove from end — O(1)
v[i];                // access — O(1)
v.size();            // count — O(1)
v.insert(v.begin()+i, x); // insert at i — O(n)
v.erase(v.begin()+i);     // erase at i — O(n)
v.reserve(1000);     // pre-allocate to avoid reallocations
```

**How vector grows:**
```
Capacity doubles when full:
Size: 1  2  3  4  5  6  7  8  9
Cap:  1  2  4  4  8  8  8  8  16

Total copies over n push_backs ≤ 1+2+4+...+n ≤ 2n → O(1) amortized
```

---

## Part 3 — Time Complexities

```
Operation           Time        Notes
Access arr[i]       O(1)        Direct address calculation
Search (unsorted)   O(n)        Must check every element
Search (sorted)     O(log n)    Binary search
Insert at end       O(1) amort  Vector doubling
Insert at i         O(n)        Shifts elements right
Delete at end       O(1)
Delete at i         O(n)        Shifts elements left
Sort                O(n log n)  Optimal comparison sort
```

---

## Part 4 — Core Techniques

### Two Pointers

Two indices that move to reduce O(n²) problems to O(n).

**Visualization — pair sum in sorted array:**
```
arr = [1, 3, 4, 5, 7, 9]   target = 12

Step 1: left=0(1), right=5(9)  sum=10 < 12 → move left right
        [1, 3, 4, 5, 7, 9]
         ↑              ↑
Step 2: left=1(3), right=5(9)  sum=12 = 12 ✓ FOUND
        [1, 3, 4, 5, 7, 9]
            ↑           ↑
```

```cpp
bool hasPairSum(vector<int>& arr, int target) {
    int left = 0, right = arr.size() - 1;
    while (left < right) {
        int sum = arr[left] + arr[right];
        if (sum == target) return true;
        else if (sum < target) left++;
        else right--;
    }
    return false;
}
// Time: O(n)  Space: O(1)
```

**Remove duplicates from sorted array:**
```
[1, 1, 2, 3, 3, 4]
 w  r              → equal, skip
 w     r           → different, write++
    w     r        → different, write++
       w     r     → equal, skip
       w        r  → different, write++
          w

Result: [1, 2, 3, 4, ...]  length = 4
```

```cpp
int removeDuplicates(vector<int>& arr) {
    int write = 0;
    for (int read = 1; read < arr.size(); read++)
        if (arr[read] != arr[write]) arr[++write] = arr[read];
    return write + 1;
}
```

---

### Sliding Window

Window of size k slides across array. Update in O(1) by adding new, removing old.

**Visualization — max sum of size 3:**
```
arr = [3, 1, 4, 1, 5, 9, 2, 6]

Window [3,1,4] sum=8
         remove 3, add 1 → [1,4,1] sum=6
                 remove 1, add 5 → [4,1,5] sum=10
                         remove 4, add 9 → [1,5,9] sum=15 ← max
                                 remove 1, add 2 → [5,9,2] sum=16 ← new max
                                         remove 5, add 6 → [9,2,6] sum=17 ← new max
```

```cpp
int maxSumWindow(vector<int>& arr, int k) {
    int windowSum = 0;
    for (int i = 0; i < k; i++) windowSum += arr[i];
    int maxSum = windowSum;

    for (int i = k; i < arr.size(); i++) {
        windowSum += arr[i];      // add incoming
        windowSum -= arr[i - k];  // remove outgoing
        maxSum = max(maxSum, windowSum);
    }
    return maxSum;
}
// Time: O(n)  compare to brute force: O(nk)
```

**Variable window:**
```cpp
// Longest subarray with sum ≤ k
int longestSubarray(vector<int>& arr, int k) {
    int left = 0, sum = 0, maxLen = 0;
    for (int right = 0; right < arr.size(); right++) {
        sum += arr[right];
        while (sum > k) sum -= arr[left++];   // shrink
        maxLen = max(maxLen, right - left + 1);
    }
    return maxLen;
}
```

---

### Prefix Sum

Precompute cumulative sums for O(1) range queries.

```
arr    = [3,  1,  4,  1,  5,  9,  2,  6]
prefix = [0,  3,  4,  8,  9, 14, 23, 25, 31]

sum(arr[2..5]) = prefix[6] - prefix[2] = 23 - 4 = 19
verify: 4+1+5+9 = 19 ✓
```

```cpp
vector<int> buildPrefix(vector<int>& arr) {
    vector<int> p(arr.size() + 1, 0);
    for (int i = 0; i < arr.size(); i++)
        p[i+1] = p[i] + arr[i];
    return p;
}

int rangeSum(vector<int>& p, int l, int r) {
    return p[r+1] - p[l];    // O(1) query
}
```

**Count subarrays with sum = k:**
```cpp
int countSubarrays(vector<int>& arr, int k) {
    unordered_map<int,int> freq;
    freq[0] = 1;
    int sum = 0, count = 0;
    for (int x : arr) {
        sum += x;
        count += freq[sum - k];   // subarrays ending here with sum k
        freq[sum]++;
    }
    return count;
}
// Time: O(n)  — arr=[1,2,3], k=3 → 2 subarrays
```

---

### Kadane's Algorithm — Maximum Subarray

At each position: extend current subarray OR start fresh — whichever is larger.

**Visualization:**
```
arr  = [-2,  1, -3,  4, -1,  2,  1, -5,  4]
curr = [-2,  1, -2,  4,  3,  5,  6,  1,  5]
max  = [-2,  1,  1,  4,  4,  5,  6,  6,  6]

curr[i] = max(arr[i], curr[i-1] + arr[i])
        = "start fresh" vs "extend"
```

```cpp
int maxSubarraySum(vector<int>& arr) {
    int curr = arr[0], best = arr[0];
    for (int i = 1; i < arr.size(); i++) {
        curr = max(arr[i], curr + arr[i]);
        best = max(best, curr);
    }
    return best;
}
// Time: O(n)  Space: O(1)
// [-2,1,-3,4,-1,2,1,-5,4] → 6 (subarray [4,-1,2,1])
```

---

## Part 5 — Sorting Algorithms

### Bubble Sort

Repeatedly swap adjacent out-of-order elements. Largest bubbles to end.

**Visualization:**
```
Pass 1: [5,3,8,1,2] → [3,5,1,2,8]  (8 bubbled to end)
Pass 2: [3,5,1,2,8] → [3,1,2,5,8]  (5 bubbled to position)
Pass 3: [3,1,2,5,8] → [1,2,3,5,8]
Pass 4: no swaps → done
```

```cpp
void bubbleSort(vector<int>& arr) {
    int n = arr.size();
    for (int i = 0; i < n-1; i++) {
        bool swapped = false;
        for (int j = 0; j < n-i-1; j++)
            if (arr[j] > arr[j+1]) { swap(arr[j], arr[j+1]); swapped = true; }
        if (!swapped) break;  // already sorted
    }
}
// Best: O(n)  Avg/Worst: O(n²)  Space: O(1)  Stable: Yes
```

---

### Selection Sort

Find minimum, place at front. Minimum swaps among O(n²) sorts.

**Visualization:**
```
[64,25,12,22,11]
 find min(11) → swap with arr[0]
[11,25,12,22,64]
    find min(12) → swap with arr[1]
[11,12,25,22,64]
       find min(22) → swap with arr[2]
[11,12,22,25,64]  ✓
```

```cpp
void selectionSort(vector<int>& arr) {
    int n = arr.size();
    for (int i = 0; i < n-1; i++) {
        int minIdx = i;
        for (int j = i+1; j < n; j++)
            if (arr[j] < arr[minIdx]) minIdx = j;
        swap(arr[i], arr[minIdx]);
    }
}
// Best/Avg/Worst: O(n²)  Space: O(1)  Stable: No  Swaps: O(n)
```

---

### Insertion Sort

Build sorted section one element at a time. Like sorting playing cards.

**Visualization:**
```
[5, 2, 4, 6, 1]
[5 | 2, 4, 6, 1]   sorted=[5]
key=2: shift 5 → [2, 5 | 4, 6, 1]
key=4: shift 5 → [2, 4, 5 | 6, 1]
key=6: no shift → [2, 4, 5, 6 | 1]
key=1: shift 6,5,4,2 → [1, 2, 4, 5, 6]  ✓
```

```cpp
void insertionSort(vector<int>& arr) {
    for (int i = 1; i < arr.size(); i++) {
        int key = arr[i], j = i-1;
        while (j >= 0 && arr[j] > key) { arr[j+1] = arr[j]; j--; }
        arr[j+1] = key;
    }
}
// Best: O(n)  Avg/Worst: O(n²)  Space: O(1)  Stable: Yes
// Best for: small arrays (n<50) and nearly sorted arrays
```

---

### Merge Sort

Divide in half, recursively sort, merge. Classic divide-and-conquer.

**Visualization:**
```
[38,27,43,3,9,82,10]
    ↙             ↘
[38,27,43,3]   [9,82,10]
  ↙     ↘       ↙    ↘
[38,27] [43,3] [9,82] [10]
  ↙↘     ↙↘    ↙↘
[38][27][43][3][9][82]
  ↘↙     ↘↙    ↘↙
[27,38] [3,43] [9,82]  [10]
    ↘       ↙       ↘  ↙
  [3,27,38,43]    [9,10,82]
         ↘            ↙
    [3,9,10,27,38,43,82]  ✓
```

**Merge step:**
```
Left: [27,38]   Right: [3,43]
Compare: 3<27 → take 3  → [3]
Compare: 27<43 → take 27 → [3,27]
Compare: 38<43 → take 38 → [3,27,38]
Remaining: take 43       → [3,27,38,43] ✓
```

```cpp
void merge(vector<int>& arr, int l, int m, int r) {
    vector<int> tmp;
    int i = l, j = m+1;
    while (i <= m && j <= r)
        tmp.push_back(arr[i] <= arr[j] ? arr[i++] : arr[j++]);
    while (i <= m) tmp.push_back(arr[i++]);
    while (j <= r) tmp.push_back(arr[j++]);
    for (int k = l; k <= r; k++) arr[k] = tmp[k-l];
}

void mergeSort(vector<int>& arr, int l, int r) {
    if (l >= r) return;
    int m = l + (r-l)/2;
    mergeSort(arr, l, m);
    mergeSort(arr, m+1, r);
    merge(arr, l, m, r);
}
// Call: mergeSort(arr, 0, arr.size()-1)
// Best/Avg/Worst: O(n log n)  Space: O(n)  Stable: Yes
```

**Recurrence:** T(n) = 2T(n/2) + O(n) → O(n log n) by Master Theorem.

---

### Quick Sort

Pick pivot, partition around it, recurse. Fastest in practice.

**Partition visualization:**
```
arr = [3,6,8,10,1,2,1]   pivot = arr[6] = 1
i = -1

j=0: 3>1, skip
j=1: 6>1, skip
j=2: 8>1, skip
j=3: 10>1, skip
j=4: 1≤1, i++, swap(arr[0],arr[4]) → [1,6,8,10,3,2,1]  i=0
j=5: 2>1, skip
end: swap(arr[i+1], pivot) → [1,1,8,10,3,2,6]  pivot at index 1

Left:[1]  Pivot:[1]  Right:[8,10,3,2,6]
```

```cpp
int partition(vector<int>& arr, int lo, int hi) {
    int pivot = arr[hi], i = lo-1;
    for (int j = lo; j < hi; j++)
        if (arr[j] <= pivot) swap(arr[++i], arr[j]);
    swap(arr[i+1], arr[hi]);
    return i+1;
}

void quickSort(vector<int>& arr, int lo, int hi) {
    if (lo < hi) {
        // Randomize pivot to avoid O(n²) on sorted input
        swap(arr[lo + rand()%(hi-lo+1)], arr[hi]);
        int p = partition(arr, lo, hi);
        quickSort(arr, lo, p-1);
        quickSort(arr, p+1, hi);
    }
}
// Avg: O(n log n)  Worst: O(n²)  Space: O(log n)  Stable: No
```

---

### Binary Search

Search sorted array by halving search space each step.

**Visualization:**
```
arr = [1,3,5,7,9,11,13,15]   target = 7

left=0, right=7, mid=3, arr[3]=7 → FOUND at index 3 ✓

Another: target = 6
left=0, right=7, mid=3, arr[3]=7  → 7>6, right=2
left=0, right=2, mid=1, arr[1]=3  → 3<6, left=2
left=2, right=2, mid=2, arr[2]=5  → 5<6, left=3
left=3 > right=2 → NOT FOUND (-1)
```

```cpp
int binarySearch(vector<int>& arr, int target) {
    int left = 0, right = arr.size()-1;
    while (left <= right) {
        int mid = left + (right-left)/2;  // avoids overflow
        if (arr[mid] == target) return mid;
        else if (arr[mid] < target) left = mid+1;
        else right = mid-1;
    }
    return -1;
}
// Time: O(log n)  Space: O(1)
```

**STL binary search:**
```cpp
// lower_bound: first position where arr[i] >= target
auto it = lower_bound(arr.begin(), arr.end(), target);

// upper_bound: first position where arr[i] > target
auto it2 = upper_bound(arr.begin(), arr.end(), target);

// Count occurrences:
int count = upper_bound(arr.begin(), arr.end(), x)
          - lower_bound(arr.begin(), arr.end(), x);
```

---

## Sorting Comparison Table

```
Algorithm   Best       Average    Worst      Space   Stable
Bubble      O(n)       O(n²)      O(n²)      O(1)    Yes
Selection   O(n²)      O(n²)      O(n²)      O(1)    No
Insertion   O(n)       O(n²)      O(n²)      O(1)    Yes
Merge       O(n lg n)  O(n lg n)  O(n lg n)  O(n)    Yes
Quick       O(n lg n)  O(n lg n)  O(n²)      O(lg n) No
```

**Lower bound:** Any comparison-based sort requires Ω(n log n). There are n! orderings → binary decision tree needs height ≥ log₂(n!) ≈ n log n.

---

## Practice Problems

**Easy:**
1. Find max and min in array.
2. Reverse array in-place.
3. Move zeros to end, keep relative order.
4. Find missing number in array of 1..n.

**Medium:**
5. Best time to buy and sell stock (one transaction).
6. Find minimum in rotated sorted array.
7. Maximum product subarray.
8. Count inversions (pairs i<j where arr[i]>arr[j]).

---

## Answers

**Problem 3:**
```cpp
void moveZeros(vector<int>& arr) {
    int write = 0;
    for (int x : arr) if (x != 0) arr[write++] = x;
    while (write < arr.size()) arr[write++] = 0;
}
```

**Problem 5:**
```cpp
int maxProfit(vector<int>& prices) {
    int minPrice = INT_MAX, profit = 0;
    for (int p : prices) {
        minPrice = min(minPrice, p);
        profit = max(profit, p - minPrice);
    }
    return profit;
}
```

**Problem 6:**
```cpp
int findMin(vector<int>& arr) {
    int lo = 0, hi = arr.size()-1;
    while (lo < hi) {
        int mid = lo + (hi-lo)/2;
        if (arr[mid] > arr[hi]) lo = mid+1;
        else hi = mid;
    }
    return arr[lo];
}
```

---

## References

- Cormen et al. — *CLRS* 4th ed. — Chapters 2, 7, 8
- Visualgo — [Sorting](https://visualgo.net/en/sorting)
- CSES — [Sorting and Searching](https://cses.fi/problemset/)
- LeetCode — [Array tag](https://leetcode.com/tag/array/)
