# Recursion and Backtracking

## Solving Problems by Reducing Them

Recursion is the technique of solving a problem by solving smaller versions of the same problem. Backtracking is recursion with the ability to undo choices when they lead to dead ends.

**Real-world analogy for recursion:** Russian nesting dolls (Matryoshka). To count the total dolls, you open the outer doll, count it, then count the dolls inside — which has the same structure as the original problem. The "base case" is when you open a doll with nothing inside.

**Real-world analogy for backtracking:** Solving a Sudoku puzzle. You place a number, try to continue, hit a contradiction, erase the number, and try another. You're exploring a decision tree and pruning branches that can't lead to solutions.

---

## Part 1 — Recursion Fundamentals

### The Three Laws

1. A recursive algorithm must have a **base case**
2. A recursive algorithm must **change its state** and move toward the base case
3. A recursive algorithm must **call itself** recursively

```cpp
// Classic example: factorial
int factorial(int n) {
    if (n == 0) return 1;          // base case
    return n * factorial(n-1);     // recursive case — n decreasing toward 0
}

// Visualizing the call stack:
// factorial(4)
//   = 4 * factorial(3)
//         = 3 * factorial(2)
//               = 2 * factorial(1)
//                     = 1 * factorial(0)
//                           = 1
//                     = 1 * 1 = 1
//               = 2 * 1 = 2
//         = 3 * 2 = 6
//   = 4 * 6 = 24
```

### Common Patterns

**Linear recursion:**
```cpp
int sum(vector<int>& arr, int n) {
    if (n == 0) return 0;
    return arr[n-1] + sum(arr, n-1);
}
```

**Binary recursion:**
```cpp
int fib(int n) {
    if (n <= 1) return n;
    return fib(n-1) + fib(n-2);  // two recursive calls
}
```

**Tail recursion (can be optimized to loop):**
```cpp
int factorial(int n, int acc = 1) {
    if (n == 0) return acc;
    return factorial(n-1, n * acc);  // last action is recursive call
}
```

---

## Part 2 — Backtracking Template

```cpp
void backtrack(state, choices) {
    if (isGoal(state)) {
        addToResult(state);
        return;
    }

    for (choice : choices) {
        if (isValid(state, choice)) {
            makeChoice(state, choice);
            backtrack(state, remainingChoices);
            undoChoice(state, choice);   // ← this is the "backtrack" step
        }
    }
}
```

---

## Part 3 — Classic Backtracking Problems

### Generate All Subsets (Power Set)

```cpp
vector<vector<int>> subsets(vector<int>& nums) {
    vector<vector<int>> result;
    vector<int> current;

    function<void(int)> backtrack = [&](int start) {
        result.push_back(current);  // add current subset

        for (int i = start; i < nums.size(); i++) {
            current.push_back(nums[i]);    // include nums[i]
            backtrack(i + 1);
            current.pop_back();            // exclude nums[i]
        }
    };

    backtrack(0);
    return result;
}
// {1,2,3} → {{},{1},{1,2},{1,2,3},{1,3},{2},{2,3},{3}}
// 2^n subsets total
```

### Generate All Permutations

```cpp
vector<vector<int>> permutations(vector<int>& nums) {
    vector<vector<int>> result;
    vector<bool> used(nums.size(), false);
    vector<int> current;

    function<void()> backtrack = [&]() {
        if (current.size() == nums.size()) {
            result.push_back(current);
            return;
        }

        for (int i = 0; i < nums.size(); i++) {
            if (used[i]) continue;
            used[i] = true;
            current.push_back(nums[i]);
            backtrack();
            current.pop_back();
            used[i] = false;
        }
    };

    backtrack();
    return result;
}
// {1,2,3} → 6 permutations: {1,2,3},{1,3,2},{2,1,3},...
```

### Combination Sum

Find all combinations that sum to target (can reuse elements).

```cpp
vector<vector<int>> combinationSum(vector<int>& candidates, int target) {
    sort(candidates.begin(), candidates.end());
    vector<vector<int>> result;
    vector<int> current;

    function<void(int, int)> backtrack = [&](int start, int remaining) {
        if (remaining == 0) { result.push_back(current); return; }

        for (int i = start; i < candidates.size(); i++) {
            if (candidates[i] > remaining) break;  // pruning!
            current.push_back(candidates[i]);
            backtrack(i, remaining - candidates[i]);  // i (not i+1) = can reuse
            current.pop_back();
        }
    };

    backtrack(0, target);
    return result;
}
// candidates={2,3,6,7}, target=7 → {{2,2,3},{7}}
```

### N-Queens Problem

Place N queens on N×N board so no two threaten each other.

```cpp
vector<vector<string>> solveNQueens(int n) {
    vector<vector<string>> result;
    vector<string> board(n, string(n, '.'));
    vector<bool> col(n,false), diag1(2*n-1,false), diag2(2*n-1,false);

    function<void(int)> backtrack = [&](int row) {
        if (row == n) { result.push_back(board); return; }

        for (int c = 0; c < n; c++) {
            if (col[c] || diag1[row-c+n-1] || diag2[row+c]) continue;

            col[c] = diag1[row-c+n-1] = diag2[row+c] = true;
            board[row][c] = 'Q';
            backtrack(row + 1);
            board[row][c] = '.';
            col[c] = diag1[row-c+n-1] = diag2[row+c] = false;
        }
    };

    backtrack(0);
    return result;
}
// n=4 → 2 solutions
```

### Sudoku Solver

```cpp
bool solveSudoku(vector<vector<char>>& board) {
    for (int r = 0; r < 9; r++) {
        for (int c = 0; c < 9; c++) {
            if (board[r][c] != '.') continue;

            for (char num = '1'; num <= '9'; num++) {
                if (isValid(board, r, c, num)) {
                    board[r][c] = num;
                    if (solveSudoku(board)) return true;
                    board[r][c] = '.';  // backtrack
                }
            }
            return false;  // no valid number → backtrack
        }
    }
    return true;  // all cells filled
}

bool isValid(vector<vector<char>>& board, int row, int col, char num) {
    for (int i = 0; i < 9; i++) {
        if (board[row][i] == num) return false;  // row check
        if (board[i][col] == num) return false;  // col check
        // 3x3 box check
        int r = 3*(row/3) + i/3, c = 3*(col/3) + i%3;
        if (board[r][c] == num) return false;
    }
    return true;
}
```

### Word Search in Grid

```cpp
bool wordSearch(vector<vector<char>>& board, string word) {
    int rows = board.size(), cols = board[0].size();

    function<bool(int,int,int)> dfs = [&](int r, int c, int idx) -> bool {
        if (idx == word.size()) return true;
        if (r < 0 || r >= rows || c < 0 || c >= cols) return false;
        if (board[r][c] != word[idx]) return false;

        char temp = board[r][c];
        board[r][c] = '#';  // mark visited

        bool found = dfs(r+1,c,idx+1) || dfs(r-1,c,idx+1) ||
                     dfs(r,c+1,idx+1) || dfs(r,c-1,idx+1);

        board[r][c] = temp;  // restore
        return found;
    };

    for (int r = 0; r < rows; r++)
        for (int c = 0; c < cols; c++)
            if (dfs(r, c, 0)) return true;
    return false;
}
```

---

## Part 4 — Pruning Strategies

Pruning eliminates branches early to dramatically speed up backtracking.

```cpp
// Example: combinations with pruning
function<void(int, int)> backtrack = [&](int start, int remaining) {
    if (remaining == 0) { result.push_back(current); return; }

    for (int i = start; i < candidates.size(); i++) {
        if (candidates[i] > remaining) break;  // PRUNING: sorted, can't do better

        // PRUNING: skip duplicates at same level
        if (i > start && candidates[i] == candidates[i-1]) continue;

        current.push_back(candidates[i]);
        backtrack(i+1, remaining - candidates[i]);
        current.pop_back();
    }
};
```

**Types of pruning:**
- **Constraint propagation:** if a choice violates a constraint, skip it immediately
- **Bound checking:** if remaining can't possibly reach a goal, prune
- **Symmetry breaking:** skip symmetric cases (done in N-Queens with sorted input)

---

## Practice Problems

1. Generate all valid combinations of n pairs of parentheses.
2. Given n, generate all combinations of k numbers from 1 to n.
3. Find all possible paths from top-left to bottom-right in a grid with obstacles.
4. Solve the rat in a maze problem.
5. Find all subsets of an array that sum to a target.

---

## Answers to Selected Problems

**Problem 1 (Generate parentheses):**
```cpp
vector<string> generateParentheses(int n) {
    vector<string> result;
    function<void(string, int, int)> backtrack = [&](string s, int open, int close) {
        if (s.size() == 2*n) { result.push_back(s); return; }
        if (open < n) backtrack(s+"(", open+1, close);
        if (close < open) backtrack(s+")", open, close+1);
    };
    backtrack("", 0, 0);
    return result;
}
// n=3 → {"((()))","(()())","(())()","()(())","()()()"}
```

**Problem 2 (Combinations):**
```cpp
vector<vector<int>> combine(int n, int k) {
    vector<vector<int>> result;
    vector<int> current;
    function<void(int)> backtrack = [&](int start) {
        if (current.size() == k) { result.push_back(current); return; }
        for (int i = start; i <= n-(k-current.size())+1; i++) {  // pruning
            current.push_back(i);
            backtrack(i+1);
            current.pop_back();
        }
    };
    backtrack(1);
    return result;
}
```

---

## References

- Cormen et al. — *CLRS* — Chapter 15 (for recursion in DP)
- LeetCode — [Backtracking problems](https://leetcode.com/tag/backtracking/)
- Visualgo — [Recursion tree visualization](https://visualgo.net/en/recursion)
