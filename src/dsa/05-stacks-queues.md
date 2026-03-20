# Stacks and Queues

## Linear Data Structures with Restricted Access

Arrays let you access any element at any time. Stacks and queues deliberately restrict this — you can only access the element at one specific end. This restriction, far from being a limitation, is exactly what makes them powerful for certain problems.

---

## Part 1 — Stack

### What is a Stack?

A stack follows **LIFO — Last In, First Out**. The last element pushed is the first one popped.

**Real-world analogy:** A stack of plates in a cafeteria. You place plates on top and take from the top. The first plate placed is the last one used.

**CS analogy:** Function call stack. When `main` calls `f` which calls `g`, you can't return from `f` before returning from `g` — they unwind in reverse order of calls.

```
Push: 1, 2, 3, 4

Stack state:
  TOP → [4]
        [3]
        [2]
        [1]

Pop sequence: 4, 3, 2, 1
```

### Stack Implementation

**Using STL:**
```cpp
#include <stack>
stack<int> st;
st.push(1);
st.push(2);
st.push(3);
cout << st.top();   // 3 — peek without removing
st.pop();           // removes 3
cout << st.top();   // 2
cout << st.size();  // 2
cout << st.empty(); // false
```

**Custom array-based implementation:**
```cpp
class Stack {
    vector<int> data;
public:
    void push(int val) { data.push_back(val); }
    void pop() {
        if (empty()) throw runtime_error("stack underflow");
        data.pop_back();
    }
    int top() {
        if (empty()) throw runtime_error("stack empty");
        return data.back();
    }
    bool empty() const { return data.empty(); }
    int size() const { return data.size(); }
};
// All operations O(1)
```

### Classic Stack Problems

**Balanced Brackets:**

```cpp
bool isBalanced(string s) {
    stack<char> st;
    for (char c : s) {
        if (c == '(' || c == '[' || c == '{') {
            st.push(c);
        } else {
            if (st.empty()) return false;
            char top = st.top(); st.pop();
            if (c == ')' && top != '(') return false;
            if (c == ']' && top != '[') return false;
            if (c == '}' && top != '{') return false;
        }
    }
    return st.empty();
}
// "([{}])" → true, "([)]" → false
```

**Next Greater Element:**

For each element, find the next element to its right that is greater.

```cpp
vector<int> nextGreater(vector<int>& arr) {
    int n = arr.size();
    vector<int> result(n, -1);
    stack<int> st;  // stores indices

    for (int i = 0; i < n; i++) {
        // pop all elements smaller than current
        while (!st.empty() && arr[st.top()] < arr[i]) {
            result[st.top()] = arr[i];
            st.pop();
        }
        st.push(i);
    }
    return result;
}
// {4, 5, 2, 10, 8} → {5, 10, 10, -1, -1}
// Time: O(n) — each element pushed/popped once
```

**Largest Rectangle in Histogram:**

**Analogy:** For each bar, find how far left and right you can extend while maintaining at least that height.

```cpp
int largestRectangle(vector<int>& heights) {
    stack<int> st;
    int maxArea = 0;
    heights.push_back(0);  // sentinel

    for (int i = 0; i < heights.size(); i++) {
        while (!st.empty() && heights[st.top()] > heights[i]) {
            int h = heights[st.top()]; st.pop();
            int w = st.empty() ? i : i - st.top() - 1;
            maxArea = max(maxArea, h * w);
        }
        st.push(i);
    }
    return maxArea;
}
// {2,1,5,6,2,3} → 10 (bars 5 and 6, width 2)
// Time: O(n)
```

**Evaluate Reverse Polish Notation:**

```cpp
int evalRPN(vector<string>& tokens) {
    stack<long long> st;
    for (string& t : tokens) {
        if (t == "+" || t == "-" || t == "*" || t == "/") {
            long long b = st.top(); st.pop();
            long long a = st.top(); st.pop();
            if (t == "+") st.push(a + b);
            else if (t == "-") st.push(a - b);
            else if (t == "*") st.push(a * b);
            else st.push(a / b);
        } else {
            st.push(stoll(t));
        }
    }
    return st.top();
}
// {"2","1","+","3","*"} → (2+1)*3 = 9
```

**Min Stack — O(1) getMin:**

```cpp
class MinStack {
    stack<int> st, minSt;
public:
    void push(int val) {
        st.push(val);
        if (minSt.empty() || val <= minSt.top())
            minSt.push(val);
    }
    void pop() {
        if (st.top() == minSt.top()) minSt.pop();
        st.pop();
    }
    int top() { return st.top(); }
    int getMin() { return minSt.top(); }
};
```

---

## Part 2 — Queue

### What is a Queue?

A queue follows **FIFO — First In, First Out**. The first element enqueued is the first one dequeued.

**Real-world analogy:** A checkout line at a supermarket. First person to join is first to be served. Fair and orderly.

**CS use cases:** BFS traversal, task scheduling, print queues, request handling.

### Queue Implementation

```cpp
#include <queue>
queue<int> q;
q.push(1);
q.push(2);
q.push(3);
cout << q.front();  // 1 — oldest element
cout << q.back();   // 3 — newest element
q.pop();            // removes 1
cout << q.front();  // 2
cout << q.size();   // 2
```

**Custom implementation using circular array:**

```cpp
class Queue {
    vector<int> data;
    int front, back, size, capacity;
public:
    Queue(int cap) : capacity(cap), front(0), back(0), size(0) {
        data.resize(cap);
    }
    void enqueue(int val) {
        if (size == capacity) throw runtime_error("queue full");
        data[back] = val;
        back = (back + 1) % capacity;
        size++;
    }
    int dequeue() {
        if (empty()) throw runtime_error("queue empty");
        int val = data[front];
        front = (front + 1) % capacity;
        size--;
        return val;
    }
    int peek() { return data[front]; }
    bool empty() { return size == 0; }
};
// Circular array avoids wasted space
```

---

## Part 3 — Deque (Double-Ended Queue)

Insert and remove from both ends in O(1).

```cpp
#include <deque>
deque<int> dq;
dq.push_back(3);   // back
dq.push_front(1);  // front
dq.push_back(4);
// dq: [1, 3, 4]
dq.pop_front();    // removes 1
dq.pop_back();     // removes 4
cout << dq.front(); // 3
cout << dq.back();  // 3
```

**Sliding Window Maximum — using deque:**

Find the maximum in every window of size k.

```cpp
vector<int> slidingWindowMax(vector<int>& arr, int k) {
    deque<int> dq;  // stores indices, decreasing values
    vector<int> result;

    for (int i = 0; i < arr.size(); i++) {
        // remove elements outside window
        while (!dq.empty() && dq.front() < i - k + 1)
            dq.pop_front();

        // remove smaller elements from back (they'll never be maximum)
        while (!dq.empty() && arr[dq.back()] < arr[i])
            dq.pop_back();

        dq.push_back(i);

        if (i >= k - 1)
            result.push_back(arr[dq.front()]);
    }
    return result;
}
// {1,3,-1,-3,5,3,6,7}, k=3 → {3,3,5,5,6,7}
// Time: O(n), Space: O(k)
```

---

## Part 4 — Priority Queue (Heap)

Not strictly FIFO — elements are dequeued in priority order (largest or smallest first).

```cpp
#include <queue>

// Max-heap (default)
priority_queue<int> maxPQ;
maxPQ.push(3); maxPQ.push(1); maxPQ.push(4); maxPQ.push(1); maxPQ.push(5);
cout << maxPQ.top(); // 5
maxPQ.pop();
cout << maxPQ.top(); // 4

// Min-heap
priority_queue<int, vector<int>, greater<int>> minPQ;
minPQ.push(3); minPQ.push(1); minPQ.push(4);
cout << minPQ.top(); // 1

// Custom comparator — sort by second element
auto cmp = [](pair<int,int>& a, pair<int,int>& b) {
    return a.second > b.second; // min heap on second element
};
priority_queue<pair<int,int>, vector<pair<int,int>>, decltype(cmp)> pq(cmp);
```

**K Largest Elements:**

```cpp
vector<int> kLargest(vector<int>& arr, int k) {
    priority_queue<int, vector<int>, greater<int>> minPQ; // min heap of size k
    for (int x : arr) {
        minPQ.push(x);
        if (minPQ.size() > k) minPQ.pop();  // remove smallest
    }
    vector<int> result;
    while (!minPQ.empty()) {
        result.push_back(minPQ.top());
        minPQ.pop();
    }
    return result;
}
// Time: O(n log k), Space: O(k)
```

---

## Part 5 — Monotonic Stack/Queue Patterns

A stack/queue that maintains elements in monotonically increasing or decreasing order. Core pattern for many interview problems.

### Monotonic Stack

```cpp
// Template: Next Greater Element (monotonic decreasing stack)
vector<int> nextGreaterElement(vector<int>& arr) {
    int n = arr.size();
    vector<int> result(n, -1);
    stack<int> st; // stores indices

    for (int i = 0; i < n; i++) {
        while (!st.empty() && arr[st.top()] < arr[i]) {
            result[st.top()] = arr[i];
            st.pop();
        }
        st.push(i);
    }
    return result;
}

// Template: Previous Smaller Element
vector<int> prevSmaller(vector<int>& arr) {
    int n = arr.size();
    vector<int> result(n, -1);
    stack<int> st;

    for (int i = 0; i < n; i++) {
        while (!st.empty() && arr[st.top()] >= arr[i])
            st.pop();
        if (!st.empty()) result[i] = arr[st.top()];
        st.push(i);
    }
    return result;
}
```

**Trapping Rain Water — classic problem:**

**Analogy:** Water fills between elevation bars. Each unit of water at position i is bounded by the minimum of the maximum heights to its left and right, minus the height at i.

```cpp
int trap(vector<int>& height) {
    int n = height.size();
    int left = 0, right = n-1;
    int leftMax = 0, rightMax = 0, water = 0;

    while (left < right) {
        if (height[left] < height[right]) {
            if (height[left] >= leftMax) leftMax = height[left];
            else water += leftMax - height[left];
            left++;
        } else {
            if (height[right] >= rightMax) rightMax = height[right];
            else water += rightMax - height[right];
            right--;
        }
    }
    return water;
}
// {0,1,0,2,1,0,1,3,2,1,2,1} → 6
// Time: O(n), Space: O(1)
```

---

## Practice Problems

**Stack:**
1. Implement a stack using two queues.
2. Sort a stack using only stack operations.
3. Evaluate an arithmetic expression with +, -, *, / and parentheses.

**Queue:**
4. Implement a queue using two stacks.
5. Given a stream of integers, find the first non-repeating integer at each step.

**Combined:**
6. Design a stack that supports push, pop, top, and retrieving the minimum element, all in O(1).
7. Implement a circular queue.

---

## Answers to Selected Problems

**Problem 1 (Stack from two queues):**
```cpp
class StackFromQueues {
    queue<int> q1, q2;
public:
    void push(int val) {
        q2.push(val);
        while (!q1.empty()) { q2.push(q1.front()); q1.pop(); }
        swap(q1, q2);
    }
    int pop() { int val = q1.front(); q1.pop(); return val; }
    int top() { return q1.front(); }
    bool empty() { return q1.empty(); }
};
// push O(n), pop O(1)
```

**Problem 4 (Queue from two stacks):**
```cpp
class QueueFromStacks {
    stack<int> inbox, outbox;
public:
    void enqueue(int val) { inbox.push(val); }
    int dequeue() {
        if (outbox.empty())
            while (!inbox.empty()) { outbox.push(inbox.top()); inbox.pop(); }
        int val = outbox.top(); outbox.pop();
        return val;
    }
};
// enqueue O(1), dequeue amortized O(1)
```

---

## References

- Cormen et al. — *CLRS* — Chapter 10
- LeetCode — [Stack](https://leetcode.com/tag/stack/), [Queue](https://leetcode.com/tag/queue/)
- Visualgo — [Stack/Queue](https://visualgo.net/en/list)
