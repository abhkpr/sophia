# Dynamic Programming

## The Art of Not Repeating Yourself

Dynamic programming (DP) solves problems by breaking them into subproblems, solving each subproblem once, and storing the result. It transforms exponential algorithms into polynomial ones.

**Real-world analogy:** Calculating a route on a map. To find the shortest path from City A to City Z, you don't recalculate the distance from A to every intermediate city each time you need it. You calculate it once, remember it, and look it up instantly. DP is exactly this — compute once, reuse forever.

**When to use DP:**
1. Problem has **optimal substructure** — optimal solution to the whole = combination of optimal solutions to subproblems
2. Problem has **overlapping subproblems** — same subproblems appear multiple times

---

## Part 1 — DP Approaches

### Top-Down (Memoization)

Start from the original problem, recurse down, cache results.

```cpp
// Fibonacci — naive recursion: O(2ⁿ)
int fib(int n) {
    if (n <= 1) return n;
    return fib(n-1) + fib(n-2);
}

// Fibonacci — memoization: O(n)
unordered_map<int,int> memo;
int fibMemo(int n) {
    if (n <= 1) return n;
    if (memo.count(n)) return memo[n];
    return memo[n] = fibMemo(n-1) + fibMemo(n-2);
}
```

### Bottom-Up (Tabulation)

Start from base cases, build up to original problem iteratively.

```cpp
// Fibonacci — tabulation: O(n) time, O(n) space
int fibTab(int n) {
    if (n <= 1) return n;
    vector<int> dp(n+1);
    dp[0] = 0; dp[1] = 1;
    for (int i = 2; i <= n; i++)
        dp[i] = dp[i-1] + dp[i-2];
    return dp[n];
}

// Fibonacci — space optimized: O(1) space
int fibOpt(int n) {
    if (n <= 1) return n;
    int a = 0, b = 1;
    for (int i = 2; i <= n; i++) {
        int c = a + b;
        a = b; b = c;
    }
    return b;
}
```

**Which to use?**
- Memoization: easier to think about, handles only needed subproblems
- Tabulation: usually faster in practice (no recursion overhead), required for space optimization

---

## Part 2 — Classic DP Problems

### 1D DP — Climbing Stairs

You can climb 1 or 2 steps at a time. How many distinct ways to reach step n?

```cpp
int climbStairs(int n) {
    if (n <= 2) return n;
    int a = 1, b = 2;
    for (int i = 3; i <= n; i++) {
        int c = a + b;
        a = b; b = c;
    }
    return b;
}
// Recurrence: ways(n) = ways(n-1) + ways(n-2)
// To reach step n, you either came from step n-1 (1 step) or n-2 (2 steps)
// This IS Fibonacci! ways(n) = fib(n+1)
```

### 1D DP — House Robber

Houses in a row with values. Can't rob adjacent houses. Maximize total.

```cpp
int rob(vector<int>& houses) {
    int n = houses.size();
    if (n == 1) return houses[0];

    // dp[i] = max money robbing from houses 0..i
    vector<int> dp(n);
    dp[0] = houses[0];
    dp[1] = max(houses[0], houses[1]);

    for (int i = 2; i < n; i++)
        dp[i] = max(dp[i-1], dp[i-2] + houses[i]);
        // either skip house i, or rob it + best from i-2

    return dp[n-1];
}
// {2,7,9,3,1} → 12 (rob houses 1, 3, 5: 2+9+1)
// Space optimized: just keep prev two values
```

### 2D DP — Unique Paths

Grid of m×n. Move only right or down. Count paths from (0,0) to (m-1,n-1).

```cpp
int uniquePaths(int m, int n) {
    vector<vector<int>> dp(m, vector<int>(n, 1));
    for (int i = 1; i < m; i++)
        for (int j = 1; j < n; j++)
            dp[i][j] = dp[i-1][j] + dp[i][j-1];
    return dp[m-1][n-1];
}
// Each cell = paths from above + paths from left
// Time: O(mn), Space: O(mn) — can optimize to O(n)
```

### Knapsack Problem — 0/1 Knapsack

N items, each with weight and value. Knapsack capacity W. Maximize value.

**Analogy:** Packing a hiking backpack with limited weight. Each item either goes in or doesn't (0/1). Maximize total value without exceeding weight limit.

```cpp
int knapsack(vector<int>& weights, vector<int>& values, int W) {
    int n = weights.size();
    // dp[i][w] = max value using items 0..i-1 with capacity w
    vector<vector<int>> dp(n+1, vector<int>(W+1, 0));

    for (int i = 1; i <= n; i++) {
        for (int w = 0; w <= W; w++) {
            dp[i][w] = dp[i-1][w];  // don't take item i
            if (weights[i-1] <= w)
                dp[i][w] = max(dp[i][w], dp[i-1][w-weights[i-1]] + values[i-1]);
        }
    }
    return dp[n][W];
}
// Time: O(nW), Space: O(nW)

// Space optimized to O(W):
int knapsackOpt(vector<int>& weights, vector<int>& values, int W) {
    int n = weights.size();
    vector<int> dp(W+1, 0);
    for (int i = 0; i < n; i++)
        for (int w = W; w >= weights[i]; w--)  // must go right-to-left!
            dp[w] = max(dp[w], dp[w-weights[i]] + values[i]);
    return dp[W];
}
```

### Longest Increasing Subsequence (LIS)

Find the length of the longest subsequence where elements are strictly increasing.

```cpp
// O(n²) DP
int LIS(vector<int>& nums) {
    int n = nums.size();
    vector<int> dp(n, 1);  // dp[i] = LIS ending at index i

    for (int i = 1; i < n; i++)
        for (int j = 0; j < i; j++)
            if (nums[j] < nums[i])
                dp[i] = max(dp[i], dp[j] + 1);

    return *max_element(dp.begin(), dp.end());
}

// O(n log n) using patience sorting
int LIS_nlogn(vector<int>& nums) {
    vector<int> tails;  // tails[i] = smallest tail of all IS of length i+1
    for (int x : nums) {
        auto it = lower_bound(tails.begin(), tails.end(), x);
        if (it == tails.end()) tails.push_back(x);
        else *it = x;
    }
    return tails.size();
}
// {10,9,2,5,3,7,101,18} → 4 ({2,3,7,101} or {2,5,7,101})
```

### Edit Distance (Levenshtein Distance)

Minimum operations (insert, delete, replace) to transform string a into string b.

**Analogy:** Spell checker. How many corrections needed to change "kitten" to "sitting"?

```cpp
int editDistance(string a, string b) {
    int m = a.size(), n = b.size();
    // dp[i][j] = edit distance between a[0..i-1] and b[0..j-1]
    vector<vector<int>> dp(m+1, vector<int>(n+1));

    for (int i = 0; i <= m; i++) dp[i][0] = i;  // delete all of a
    for (int j = 0; j <= n; j++) dp[0][j] = j;  // insert all of b

    for (int i = 1; i <= m; i++) {
        for (int j = 1; j <= n; j++) {
            if (a[i-1] == b[j-1])
                dp[i][j] = dp[i-1][j-1];           // no operation needed
            else
                dp[i][j] = 1 + min({
                    dp[i-1][j],    // delete from a
                    dp[i][j-1],    // insert into a
                    dp[i-1][j-1]   // replace in a
                });
        }
    }
    return dp[m][n];
}
// "kitten" → "sitting" = 3 operations
```

### Coin Change

Minimum number of coins to make amount n.

```cpp
int coinChange(vector<int>& coins, int amount) {
    vector<int> dp(amount+1, amount+1);  // "infinity"
    dp[0] = 0;

    for (int a = 1; a <= amount; a++)
        for (int coin : coins)
            if (coin <= a)
                dp[a] = min(dp[a], dp[a-coin] + 1);

    return dp[amount] > amount ? -1 : dp[amount];
}
// coins={1,5,6,9}, amount=11 → 2 (5+6)
// Time: O(amount × coins), Space: O(amount)
```

### Longest Common Subsequence

```cpp
int LCS(string a, string b) {
    int m = a.size(), n = b.size();
    vector<vector<int>> dp(m+1, vector<int>(n+1, 0));

    for (int i = 1; i <= m; i++)
        for (int j = 1; j <= n; j++)
            if (a[i-1] == b[j-1])
                dp[i][j] = dp[i-1][j-1] + 1;
            else
                dp[i][j] = max(dp[i-1][j], dp[i][j-1]);

    return dp[m][n];
}
// "ABCBDAB" and "BDCAB" → 4
```

---

## Part 3 — DP on Intervals

### Matrix Chain Multiplication

Minimize operations to multiply a chain of matrices.

```cpp
int matrixChain(vector<int>& dims) {
    int n = dims.size() - 1;
    vector<vector<int>> dp(n, vector<int>(n, 0));

    for (int len = 2; len <= n; len++) {
        for (int i = 0; i <= n-len; i++) {
            int j = i + len - 1;
            dp[i][j] = INT_MAX;
            for (int k = i; k < j; k++)
                dp[i][j] = min(dp[i][j],
                    dp[i][k] + dp[k+1][j] + dims[i]*dims[k+1]*dims[j+1]);
        }
    }
    return dp[0][n-1];
}
```

### Burst Balloons

Classic interval DP — optimal order to burst balloons to maximize coins.

```cpp
int maxCoins(vector<int>& nums) {
    nums.insert(nums.begin(), 1);
    nums.push_back(1);
    int n = nums.size();
    vector<vector<int>> dp(n, vector<int>(n, 0));

    for (int len = 2; len < n; len++) {
        for (int left = 0; left < n-len; left++) {
            int right = left + len;
            for (int k = left+1; k < right; k++) {
                dp[left][right] = max(dp[left][right],
                    dp[left][k] + nums[left]*nums[k]*nums[right] + dp[k][right]);
            }
        }
    }
    return dp[0][n-1];
}
```

---

## Practice Problems

**Easy:**
1. Find the nth Fibonacci number iteratively and with DP.
2. Count ways to climb n stairs taking 1, 2, or 3 steps at a time.

**Medium:**
3. Find the minimum cost path in a grid from top-left to bottom-right.
4. Find the maximum profit from buying and selling stocks with at most k transactions.
5. Find the number of ways to partition a set into two equal subsets.

**Hard:**
6. Find the minimum number of cuts to partition a string so each part is a palindrome.
7. Find the longest palindromic subsequence.
8. Wildcard pattern matching (? matches any single character, * matches any sequence).

---

## Answers to Selected Problems

**Problem 3 (Minimum cost path):**
```cpp
int minPathSum(vector<vector<int>>& grid) {
    int m = grid.size(), n = grid[0].size();
    vector<vector<int>> dp(m, vector<int>(n));
    dp[0][0] = grid[0][0];
    for (int i = 1; i < m; i++) dp[i][0] = dp[i-1][0] + grid[i][0];
    for (int j = 1; j < n; j++) dp[0][j] = dp[0][j-1] + grid[0][j];
    for (int i = 1; i < m; i++)
        for (int j = 1; j < n; j++)
            dp[i][j] = grid[i][j] + min(dp[i-1][j], dp[i][j-1]);
    return dp[m-1][n-1];
}
```

**Problem 5 (Equal partition):**
```cpp
bool canPartition(vector<int>& nums) {
    int sum = accumulate(nums.begin(), nums.end(), 0);
    if (sum % 2 != 0) return false;
    int target = sum / 2;
    vector<bool> dp(target+1, false);
    dp[0] = true;
    for (int x : nums)
        for (int j = target; j >= x; j--)
            dp[j] = dp[j] || dp[j-x];
    return dp[target];
}
// {1,5,11,5} → true (partition {1,5,5} and {11})
```

**Problem 7 (Longest palindromic subsequence):**
```cpp
int longestPalinSubseq(string s) {
    int n = s.size();
    string rev = s; reverse(rev.begin(), rev.end());
    // LPS(s) = LCS(s, reverse(s))
    vector<vector<int>> dp(n+1, vector<int>(n+1, 0));
    for (int i = 1; i <= n; i++)
        for (int j = 1; j <= n; j++)
            dp[i][j] = (s[i-1] == rev[j-1]) ? dp[i-1][j-1]+1
                                              : max(dp[i-1][j], dp[i][j-1]);
    return dp[n][n];
}
// "bbbab" → 4 ("bbbb")
```

---

## References

- Cormen et al. — *CLRS* — Chapter 15 (Dynamic Programming)
- Sedgewick & Wayne — *Algorithms* — Chapter 6
- MIT 6.006 — [DP lectures](https://ocw.mit.edu/courses/6-006-introduction-to-algorithms-fall-2011/)
- LeetCode — [DP problems](https://leetcode.com/tag/dynamic-programming/)
- Aditya Verma DP playlist — [YouTube](https://www.youtube.com/playlist?list=PL_z_8CaSLPWekqhdCPmFohncHwz8TY2Go)
