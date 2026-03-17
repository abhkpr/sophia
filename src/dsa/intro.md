# Data Structures & Algorithms

## What is a Data Structure?

A **data structure** is a way of organizing and storing data in memory so that it can be accessed and modified efficiently. The choice of data structure directly impacts the performance of an algorithm.

Every data structure makes a tradeoff — optimizing for some operations at the cost of others. An array gives O(1) random access but O(n) insertion. A linked list gives O(1) insertion at head but O(n) random access. Understanding these tradeoffs is the foundation of writing efficient software.

## What is an Algorithm?

An **algorithm** is a finite sequence of well-defined instructions to solve a problem or perform a computation. An algorithm takes input, processes it, and produces output.

Algorithms are evaluated on two dimensions:

- **Time complexity** — how the runtime grows as input size grows
- **Space complexity** — how much memory the algorithm uses

## Why This Matters

The difference between a naive algorithm and an optimized one isn't academic — it's the difference between a program that handles 10 users and one that handles 10 million.

A sorting algorithm that runs in O(n²) time works fine for 100 elements. At 1,000,000 elements it takes a trillion operations. A O(n log n) algorithm on the same input takes about 20 million operations — 50,000 times faster.

## Topics in This Section

- Arrays and Strings
- Linked Lists
- Stacks and Queues
- Trees and Binary Search Trees
- Heaps and Priority Queues
- Hash Tables
- Graphs
- Sorting Algorithms
- Searching Algorithms
- Dynamic Programming
- Greedy Algorithms
- Recursion and Backtracking
