# Greedy Algorithms

## Make the Best Choice Now

A greedy algorithm makes the locally optimal choice at each step, hoping it leads to a globally optimal solution. Unlike DP which considers all possibilities, greedy commits to one choice and never looks back.

**Real-world analogy:** A hiker choosing which mountain trail to take. A greedy hiker always picks the path that climbs highest immediately. This works perfectly for some landscapes (smooth hills) but fails for others (a gentle slope to a tall peak vs a steep path to a dead end). The art of greedy is knowing when local optimal = global optimal.

**When greedy works:** The problem has the **greedy choice property** — a locally optimal choice is always part of some globally optimal solution.

---

## Part 1 — Classic Greedy Problems

### Activity Selection (Interval Scheduling)

Given n activities with start and end times, select maximum activities that don't overlap.

**Greedy choice:** Always pick the activity that finishes earliest.

**Why it works:** Finishing early leaves maximum time for remaining activities.

```cpp
int activitySelection(vector<pair<int,int>>& activities) {
    // Sort by end time
    sort(activities.begin(), activities.end(),
         [](auto& a, auto& b) { return a.second < b.second; });

    int count = 1;
    int lastEnd = activities[0].second;

    for (int i = 1; i < activities.size(); i++) {
        if (activities[i].first >= lastEnd) {  // starts after last ends
            count++;
            lastEnd = activities[i].second;
        }
    }
    return count;
}
// {(1,4),(3,5),(0,6),(5,7),(3,9),(5,9),(6,10),(8,11),(8,12),(2,14),(12,16)}
// → 4 activities selected
```

### Coin Change (Greedy — US Coins)

Make change for n cents using minimum coins {25, 10, 5, 1}.

**Important:** Greedy works ONLY for specific coin systems (US cents, but NOT all). Use DP for general case.

```cpp
vector<int> coinChangeGreedy(int amount, vector<int>& coins) {
    // Works only when coins are "canonical" (each coin > sum of all smaller coins)
    sort(coins.rbegin(), coins.rend());
    vector<int> result;
    for (int coin : coins) {
        while (amount >= coin) {
            result.push_back(coin);
            amount -= coin;
        }
    }
    return result;
}
// 41 cents with {25,10,5,1}: 25+10+5+1 = 4 coins ✓
// Fails for {1,3,4} to make 6: greedy gives 4+1+1=3 coins, optimal is 3+3=2 coins
```

### Fractional Knapsack

Unlike 0/1 knapsack, you can take fractions of items. Greedy works here.

**Greedy choice:** Take item with highest value/weight ratio first.

```cpp
double fractionalKnapsack(vector<pair<int,int>>& items, int capacity) {
    // Sort by value/weight ratio descending
    sort(items.begin(), items.end(), [](auto& a, auto& b) {
        return (double)a.first/a.second > (double)b.first/b.second;
    });

    double totalValue = 0;
    for (auto [value, weight] : items) {
        if (capacity >= weight) {
            totalValue += value;
            capacity -= weight;
        } else {
            totalValue += (double)value / weight * capacity;
            break;
        }
    }
    return totalValue;
}
// items={(60,10),(100,20),(120,30)}, capacity=50
// → 240.0 (take all of first two + 2/3 of third)
```

### Huffman Coding

Build optimal prefix-free encoding. Characters that appear more often get shorter codes.

```cpp
struct HuffNode {
    char ch;
    int freq;
    HuffNode *left, *right;
    HuffNode(char c, int f) : ch(c), freq(f), left(nullptr), right(nullptr) {}
};

HuffNode* buildHuffman(map<char,int>& freq) {
    auto cmp = [](HuffNode* a, HuffNode* b) { return a->freq > b->freq; };
    priority_queue<HuffNode*, vector<HuffNode*>, decltype(cmp)> pq(cmp);

    for (auto& [ch, f] : freq) pq.push(new HuffNode(ch, f));

    while (pq.size() > 1) {
        HuffNode* left = pq.top(); pq.pop();
        HuffNode* right = pq.top(); pq.pop();
        HuffNode* merged = new HuffNode('\0', left->freq + right->freq);
        merged->left = left;
        merged->right = right;
        pq.push(merged);
    }
    return pq.top();
}

void getCodes(HuffNode* root, string code, map<char,string>& codes) {
    if (!root) return;
    if (!root->left && !root->right) { codes[root->ch] = code; return; }
    getCodes(root->left, code+"0", codes);
    getCodes(root->right, code+"1", codes);
}
// "abracadabra": a→0, b→10, r→110, c→1110, d→1111
// Average bits per character reduced from 3 (fixed) to ~2.04
```

### Jump Game

Given array where arr[i] = max jump from position i. Can you reach the end?

```cpp
bool canJump(vector<int>& nums) {
    int maxReach = 0;
    for (int i = 0; i < nums.size(); i++) {
        if (i > maxReach) return false;  // stuck
        maxReach = max(maxReach, i + nums[i]);
    }
    return true;
}
// {2,3,1,1,4} → true, {3,2,1,0,4} → false
// Greedy: track furthest reachable position
```

**Minimum Jumps:**

```cpp
int minJumps(vector<int>& nums) {
    int jumps = 0, currEnd = 0, farthest = 0;
    for (int i = 0; i < nums.size()-1; i++) {
        farthest = max(farthest, i + nums[i]);
        if (i == currEnd) {  // must jump
            jumps++;
            currEnd = farthest;
        }
    }
    return jumps;
}
// {2,3,1,1,4} → 2 (jump to 3, then to end)
```

---

## Part 2 — Interval Problems

### Merge Intervals

```cpp
vector<pair<int,int>> mergeIntervals(vector<pair<int,int>>& intervals) {
    sort(intervals.begin(), intervals.end());
    vector<pair<int,int>> merged;

    for (auto& [start, end] : intervals) {
        if (!merged.empty() && start <= merged.back().second)
            merged.back().second = max(merged.back().second, end);
        else
            merged.push_back({start, end});
    }
    return merged;
}
// {{1,3},{2,6},{8,10},{15,18}} → {{1,6},{8,10},{15,18}}
```

### Meeting Rooms II (Min Rooms)

```cpp
int minMeetingRooms(vector<pair<int,int>>& intervals) {
    vector<int> starts, ends;
    for (auto& [s, e] : intervals) { starts.push_back(s); ends.push_back(e); }
    sort(starts.begin(), starts.end());
    sort(ends.begin(), ends.end());

    int rooms = 0, endIdx = 0;
    for (int start : starts) {
        if (start < ends[endIdx]) rooms++;
        else endIdx++;
    }
    return rooms;
}
// {{0,30},{5,10},{15,20}} → 2 rooms needed
```

---

## Part 3 — Greedy vs DP

| Problem | Approach |
|---------|----------|
| Activity selection | Greedy ✓ |
| Fractional knapsack | Greedy ✓ |
| 0/1 knapsack | DP required |
| Coin change (canonical coins) | Greedy ✓ |
| Coin change (arbitrary coins) | DP required |
| Shortest path (no negative weights) | Greedy (Dijkstra) ✓ |
| Shortest path (negative weights) | DP (Bellman-Ford) required |

**How to tell:** Prove or disprove the exchange argument — can you always swap a non-greedy choice for a greedy one without getting worse?

---

## Practice Problems

1. Assign tasks to workers to minimize completion time (each worker does one task).
2. Given meeting times, find if a person can attend all meetings.
3. Given an array of non-negative integers, maximize the sum by removing at most k elements from each end.
4. Find the minimum number of platforms needed at a train station.
5. Given positive integers, arrange them to form the largest number.

---

## Answers to Selected Problems

**Problem 4 (Minimum platforms):**
```cpp
int minPlatforms(vector<int>& arrival, vector<int>& departure) {
    sort(arrival.begin(), arrival.end());
    sort(departure.begin(), departure.end());
    int platforms = 0, maxPlatforms = 0;
    int i = 0, j = 0, n = arrival.size();

    while (i < n) {
        if (arrival[i] <= departure[j]) {
            platforms++; i++;
        } else {
            platforms--; j++;
        }
        maxPlatforms = max(maxPlatforms, platforms);
    }
    return maxPlatforms;
}
```

**Problem 5 (Largest number):**
```cpp
string largestNumber(vector<int>& nums) {
    vector<string> strs;
    for (int x : nums) strs.push_back(to_string(x));
    sort(strs.begin(), strs.end(), [](string& a, string& b) {
        return a + b > b + a;  // compare "34"+"3" vs "3"+"34"
    });
    if (strs[0] == "0") return "0";
    string result = "";
    for (string& s : strs) result += s;
    return result;
}
// {3,30,34,5,9} → "9534330"
```

---

## References

- Cormen et al. — *CLRS* — Chapter 16 (Greedy Algorithms)
- LeetCode — [Greedy problems](https://leetcode.com/tag/greedy/)
- CP-algorithms — [Greedy](https://cp-algorithms.com/)
