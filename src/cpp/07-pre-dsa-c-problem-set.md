# Pre-DSA C++ Problem Set

---

## Problem 1: Weird Algorithm (Collatz Sequence)

### Problem Statement
Given a positive integer `n`, generate a sequence as follows:
- If `n` is even, divide it by 2.
- If `n` is odd, multiply it by 3 and add 1.

Repeat the process until `n = 1`.

### Input
A single integer `n` (1 ≤ n ≤ 10^6)

### Output
Print the sequence starting from `n` until 1.

### Example
Input:
```
3
```
Output:
```
3 10 5 16 8 4 2 1
```

---

## Problem 2: Missing Number

### Problem Statement
You are given an integer `n` and an array containing `n-1` distinct numbers from 1 to `n`.
Find the missing number.

### Input
- First line: integer `n`
- Second line: `n-1` integers

### Output
Print the missing number.

### Example
Input:
```
5
2 3 1 5
```
Output:
```
4
```

---

## Problem 3: Increasing Array

### Problem Statement
Given an array, make it non-decreasing by increasing elements.
Find the minimum total increments required.

### Input
- First line: integer `n`
- Second line: `n` integers

### Output
Minimum number of moves.

### Example
Input:
```
5
3 2 5 1 7
```
Output:
```
5
```

---

## Problem 4: Two Sum

### Problem Statement
Given an array of integers and a target value, return indices of two numbers such that they add up to the target.

### Input
- Array `nums`
- Integer `target`

### Output
Indices of two numbers

### Example
Input:
```
nums = [2,7,11,15], target = 9
```
Output:
```
[0,1]
```

---

## Problem 5: Move Zeroes

### Problem Statement
Move all zeros in an array to the end while maintaining the relative order of non-zero elements.

### Input
Array of integers

### Output
Modified array

### Example
Input:
```
[0,1,0,3,12]
```
Output:
```
[1,3,12,0,0]
```

---

## Problem 6: Longest Substring Without Repeating Characters

### Problem Statement
Given a string, find the length of the longest substring without repeating characters.

### Input
String `s`

### Output
Integer (length)

### Example
Input:
```
abcabcbb
```
Output:
```
3
```

---

## Problem 7: Subarray Sum Equals K

### Problem Statement
Given an array of integers and an integer `k`, return the total number of subarrays whose sum equals `k`.

### Input
- Array `nums`
- Integer `k`

### Output
Count of subarrays

### Example
Input:
```
nums = [1,1,1], k = 2
```
Output:
```
2
```

---

## Problem 8: Binary Search

### Problem Statement
Given a sorted array and a target value, return its index or -1 if not found.

### Input
- Sorted array
- Target value

### Output
Index or -1

### Example
Input:
```
nums = [1,2,3,4,5], target = 4
```
Output:
```
3
```

---

## Problem 9: Generate Subsets

### Problem Statement
Given a set of distinct integers, return all possible subsets.

### Input
Array `nums`

### Output
All subsets

### Example
Input:
```
[1,2]
```
Output:
```
[[],[1],[2],[1,2]]
```

---

## Problem 10: Number of Islands

### Problem Statement
Given a 2D grid of '1's (land) and '0's (water), count the number of islands.

### Input
2D grid

### Output
Number of islands

### Example
Input:
```
[
 ["1","1","0"],
 ["1","0","0"],
 ["0","0","1"]
]
```
Output:
```
2
```

---

# Instructions

- Solve using C++
- Focus on clean code and efficiency
- Try brute force first, then optimize
- Track time taken per problem

---

