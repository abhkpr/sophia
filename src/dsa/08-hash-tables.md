# Hash Tables

## The Dictionary of Data Structures

Hash tables give you O(1) average time for insert, delete, and lookup. No other data structure matches this for key-value operations.

**Real-world analogy:** A library with a smart card catalog. Instead of searching alphabetically (O(log n)), the catalog computes a "shelf number" from the book title directly. To find "Algorithms by Cormen", the catalog function tells you "Shelf 47, Row 3" instantly. That computation is the hash function.

---

## Part 1 — How Hash Tables Work

### Hash Function

A hash function maps a key to an index in an array:

```
hash("Alice") → 3
hash("Bob")   → 7
hash("Carol") → 3   ← COLLISION! Same index as Alice
```

**Properties of a good hash function:**
1. Deterministic: same key always gives same hash
2. Uniform distribution: spreads keys evenly
3. Fast to compute: O(1)

```cpp
// Simple hash for strings
int hash(string key, int tableSize) {
    long long h = 0;
    for (char c : key)
        h = (h * 31 + c) % tableSize;
    return h;
}
```

### Collision Resolution

**Chaining (Separate Chaining):**
Each bucket holds a linked list of all elements that hash to it.

```
Index 0: []
Index 1: [Bob]
Index 2: []
Index 3: [Alice] → [Carol] → [Eve]
Index 4: []
...
```

**Open Addressing (Linear Probing):**
If bucket is occupied, try next bucket, then next, ...

```cpp
// Insert with linear probing
void insert(vector<pair<int,int>>& table, int key, int val) {
    int idx = key % table.size();
    while (table[idx].first != -1 && table[idx].first != key)
        idx = (idx + 1) % table.size();
    table[idx] = {key, val};
}
```

### Load Factor

**Load factor α = n/m** where n = number of elements, m = table size.

- α < 0.7: good performance
- α > 0.7: performance degrades, time to resize

When load factor exceeds threshold, resize (typically double) and rehash everything.

---

## Part 2 — STL Hash Tables

### unordered_map — Hash Map

```cpp
#include <unordered_map>

unordered_map<string, int> scores;

// Insert
scores["Alice"] = 95;
scores["Bob"] = 87;
scores.insert({"Charlie", 92});
scores.emplace("Dave", 78);

// Access
cout << scores["Alice"];           // 95 — creates entry if key not found!
cout << scores.at("Alice");        // 95 — throws if key not found
cout << scores.at("Unknown");      // throws std::out_of_range

// Check existence
if (scores.count("Alice"))         // 0 or 1
    cout << "Alice exists";
if (scores.find("Alice") != scores.end())
    cout << "Alice exists";
auto it = scores.find("Alice");
if (it != scores.end()) cout << it->second;

// Erase
scores.erase("Bob");

// Iterate
for (auto& [name, score] : scores)
    cout << name << ": " << score << "\n";

// Size
scores.size();   // number of key-value pairs
scores.empty();  // is it empty?
scores.clear();  // remove all entries

// Common pattern: count frequency
string text = "hello world hello";
unordered_map<string, int> freq;
stringstream ss(text);
string word;
while (ss >> word) freq[word]++;
// freq = {"hello":2, "world":1}
```

### unordered_set — Hash Set

```cpp
#include <unordered_set>

unordered_set<int> seen;
seen.insert(1);
seen.insert(2);
seen.insert(1);  // duplicate — ignored
cout << seen.size();    // 2
cout << seen.count(1);  // 1 (exists) or 0 (doesn't)
seen.erase(1);

// Remove duplicates from array
vector<int> arr = {3,1,4,1,5,9,2,6,5,3};
unordered_set<int> unique(arr.begin(), arr.end());
// unique = {1,2,3,4,5,6,9} — no duplicates, unordered
```

### map vs unordered_map

| | map | unordered_map |
|-|-----|---------------|
| Implementation | Red-black tree | Hash table |
| Insert/Find/Delete | O(log n) | O(1) average |
| Ordered? | Yes | No |
| Worst case | O(log n) | O(n) — hash collisions |
| Use when | Need sorted order | Just need fast lookup |

---

## Part 3 — Classic Hash Table Problems

### Two Sum

```cpp
vector<int> twoSum(vector<int>& nums, int target) {
    unordered_map<int, int> seen; // {value → index}
    for (int i = 0; i < nums.size(); i++) {
        int complement = target - nums[i];
        if (seen.count(complement))
            return {seen[complement], i};
        seen[nums[i]] = i;
    }
    return {};
}
// {2,7,11,15}, target=9 → {0,1}
// Time: O(n), Space: O(n)
```

### Longest Consecutive Sequence

```cpp
int longestConsecutive(vector<int>& nums) {
    unordered_set<int> numSet(nums.begin(), nums.end());
    int maxLen = 0;

    for (int num : numSet) {
        // only start counting from the beginning of a sequence
        if (!numSet.count(num - 1)) {
            int curr = num, len = 1;
            while (numSet.count(curr + 1)) { curr++; len++; }
            maxLen = max(maxLen, len);
        }
    }
    return maxLen;
}
// {100,4,200,1,3,2} → 4 (sequence: 1,2,3,4)
// Time: O(n) — each element visited at most twice
```

### Group Anagrams

```cpp
vector<vector<string>> groupAnagrams(vector<string>& words) {
    unordered_map<string, vector<string>> groups;
    for (string& w : words) {
        string key = w;
        sort(key.begin(), key.end());
        groups[key].push_back(w);
    }
    vector<vector<string>> result;
    for (auto& [key, group] : groups)
        result.push_back(group);
    return result;
}
// {"eat","tea","tan","ate","nat","bat"}
// → [["eat","tea","ate"],["tan","nat"],["bat"]]
```

### Subarray Sum Equals K

Find the number of contiguous subarrays that sum to k.

```cpp
int subarraySum(vector<int>& nums, int k) {
    unordered_map<int, int> prefixCount;
    prefixCount[0] = 1;  // empty prefix
    int sum = 0, count = 0;

    for (int x : nums) {
        sum += x;
        // if sum-k exists as a prefix sum, those subarrays sum to k
        if (prefixCount.count(sum - k))
            count += prefixCount[sum - k];
        prefixCount[sum]++;
    }
    return count;
}
// {1,1,1}, k=2 → 2 (subarrays: [1,1] starting at idx 0 and 1)
// Key insight: sum[i..j] = prefix[j] - prefix[i-1] = k
```

### First Non-Repeating Character

```cpp
char firstUnique(string s) {
    unordered_map<char, int> freq;
    for (char c : s) freq[c]++;
    for (char c : s)
        if (freq[c] == 1) return c;
    return '\0';
}
// "leetcode" → 'l'
```

---

## Part 4 — Custom Hash Functions

For custom types as keys:

```cpp
struct Point { int x, y; };

struct PointHash {
    size_t operator()(const Point& p) const {
        return hash<int>()(p.x) ^ (hash<int>()(p.y) << 1);
    }
};

struct PointEqual {
    bool operator()(const Point& a, const Point& b) const {
        return a.x == b.x && a.y == b.y;
    }
};

unordered_map<Point, int, PointHash, PointEqual> pointMap;
pointMap[{1, 2}] = 5;
```

**Common trick — encode pair as string key:**
```cpp
unordered_map<string, int> grid;
// use "x,y" as key
grid[to_string(x) + "," + to_string(y)] = val;
```

---

## Practice Problems

1. Find if there exist two elements in an array with sum exactly k.
2. Find the longest subarray with equal number of 0s and 1s.
3. Implement a phone directory (store names and phone numbers, lookup by name).
4. Given two strings, check if one is a permutation of the other.
5. Find the top k most frequent elements.

---

## Answers to Selected Problems

**Problem 2 (Equal 0s and 1s):**
```cpp
int findMaxLength(vector<int>& nums) {
    // Replace 0 with -1, find longest subarray with sum 0
    unordered_map<int, int> firstOccurrence;
    firstOccurrence[0] = -1;
    int sum = 0, maxLen = 0;

    for (int i = 0; i < nums.size(); i++) {
        sum += nums[i] == 0 ? -1 : 1;
        if (firstOccurrence.count(sum))
            maxLen = max(maxLen, i - firstOccurrence[sum]);
        else
            firstOccurrence[sum] = i;
    }
    return maxLen;
}
// {0,1,0,1,1,0} → 6 (entire array)
```

**Problem 5 (Top k frequent):**
```cpp
vector<int> topKFrequent(vector<int>& nums, int k) {
    unordered_map<int, int> freq;
    for (int x : nums) freq[x]++;

    priority_queue<pair<int,int>, vector<pair<int,int>>, greater<>> minPQ;
    for (auto& [val, cnt] : freq) {
        minPQ.push({cnt, val});
        if (minPQ.size() > k) minPQ.pop();
    }

    vector<int> result;
    while (!minPQ.empty()) { result.push_back(minPQ.top().second); minPQ.pop(); }
    return result;
}
// {1,1,1,2,2,3}, k=2 → {1,2}
```

---

## References

- Cormen et al. — *CLRS* — Chapter 11 (Hash Tables)
- Sedgewick & Wayne — *Algorithms* — Chapter 3.4 (Hash Tables)
- LeetCode — [Hash Table problems](https://leetcode.com/tag/hash-table/)
