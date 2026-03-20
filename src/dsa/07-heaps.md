# Heaps and Priority Queues

## The Data Structure That Gives You the Best Instantly

A heap is a specialized tree where the parent is always better than (greater than or less than) its children. This single property gives you the ability to always retrieve the minimum or maximum element in O(1) time.

**Real-world analogy:** An emergency room triage system. New patients arrive, each with a severity score. The doctor always treats the most critical patient first. You don't need a fully sorted list — you just need to know who's worst-off right now. That's a heap.

---

## Part 1 — Heap Properties

### Binary Heap

A **binary heap** is a complete binary tree satisfying the heap property:

**Max-heap:** Every node ≥ both its children (root = maximum)
**Min-heap:** Every node ≤ both its children (root = minimum)

```
Max-heap:        Min-heap:
     90               1
    /  \             / \
   80   70          3   2
  / \  / \         / \  \
 40 60 50 65      7   5   4
```

**Complete binary tree** — all levels are full except possibly the last, filled left to right. This allows array storage without wasting space.

### Array Representation

The key insight: a complete binary tree maps perfectly to an array.

```
Array index:  0   1   2   3   4   5   6
Value:       90  80  70  40  60  50  65

For node at index i:
  Parent:       (i-1)/2
  Left child:   2*i + 1
  Right child:  2*i + 2
```

No pointers needed — parent/child relationships are implicit from the index math.

---

## Part 2 — Heap Operations

### Building a Heap

```cpp
class MaxHeap {
    vector<int> heap;

    void heapifyUp(int i) {
        while (i > 0) {
            int parent = (i-1)/2;
            if (heap[parent] < heap[i]) {
                swap(heap[parent], heap[i]);
                i = parent;
            } else break;
        }
    }

    void heapifyDown(int i) {
        int n = heap.size();
        while (true) {
            int largest = i;
            int left = 2*i+1, right = 2*i+2;
            if (left < n && heap[left] > heap[largest]) largest = left;
            if (right < n && heap[right] > heap[largest]) largest = right;
            if (largest != i) {
                swap(heap[i], heap[largest]);
                i = largest;
            } else break;
        }
    }

public:
    // Insert — O(log n)
    void push(int val) {
        heap.push_back(val);
        heapifyUp(heap.size()-1);
    }

    // Get max — O(1)
    int top() { return heap[0]; }

    // Remove max — O(log n)
    void pop() {
        heap[0] = heap.back();
        heap.pop_back();
        if (!heap.empty()) heapifyDown(0);
    }

    bool empty() { return heap.empty(); }
    int size() { return heap.size(); }
};
```

### Build Heap from Array — O(n)

Surprisingly, building a heap from an existing array is O(n), not O(n log n).

```cpp
vector<int> arr = {3,1,4,1,5,9,2,6,5,3};

// Start from last non-leaf, heapify down each node
int n = arr.size();
for (int i = n/2 - 1; i >= 0; i--)
    heapifyDown(arr, i, n);
// Why O(n)? Most nodes are near the bottom and travel less distance.
// Mathematical proof: sum of heights = O(n)
```

---

## Part 3 — Heap Sort

Sort using a max-heap: build heap, repeatedly extract max.

```cpp
void heapSort(vector<int>& arr) {
    int n = arr.size();

    // Build max-heap — O(n)
    for (int i = n/2-1; i >= 0; i--)
        heapifyDown(arr, i, n);

    // Extract elements one by one — O(n log n)
    for (int i = n-1; i > 0; i--) {
        swap(arr[0], arr[i]);   // move current max to end
        heapifyDown(arr, 0, i); // restore heap property (excluding sorted portion)
    }
}

void heapifyDown(vector<int>& arr, int i, int n) {
    while (true) {
        int largest = i;
        int left = 2*i+1, right = 2*i+2;
        if (left < n && arr[left] > arr[largest]) largest = left;
        if (right < n && arr[right] > arr[largest]) largest = right;
        if (largest != i) { swap(arr[i], arr[largest]); i = largest; }
        else break;
    }
}
// Time: O(n log n) | Space: O(1) — in-place!
```

---

## Part 4 — Heap Applications

### K Largest Elements

```cpp
vector<int> kLargest(vector<int>& arr, int k) {
    // Min-heap of size k — maintains k largest seen so far
    priority_queue<int, vector<int>, greater<int>> minPQ;

    for (int x : arr) {
        minPQ.push(x);
        if (minPQ.size() > k) minPQ.pop(); // remove smallest
    }

    vector<int> result;
    while (!minPQ.empty()) { result.push_back(minPQ.top()); minPQ.pop(); }
    return result;
}
// Time: O(n log k), Space: O(k)
// Better than sorting entire array O(n log n) when k << n
```

### K-th Largest Element

```cpp
int kthLargest(vector<int>& arr, int k) {
    priority_queue<int, vector<int>, greater<int>> minPQ;
    for (int x : arr) {
        minPQ.push(x);
        if (minPQ.size() > k) minPQ.pop();
    }
    return minPQ.top();
}
// Time: O(n log k)
```

### Merge K Sorted Lists

```cpp
ListNode* mergeKLists(vector<ListNode*>& lists) {
    auto cmp = [](ListNode* a, ListNode* b) { return a->val > b->val; };
    priority_queue<ListNode*, vector<ListNode*>, decltype(cmp)> minPQ(cmp);

    for (ListNode* list : lists)
        if (list) minPQ.push(list);

    ListNode dummy(0);
    ListNode* curr = &dummy;
    while (!minPQ.empty()) {
        curr->next = minPQ.top(); minPQ.pop();
        curr = curr->next;
        if (curr->next) minPQ.push(curr->next);
    }
    return dummy.next;
}
// Time: O(N log k) where N = total nodes, k = number of lists
```

### Median from Data Stream

**Analogy:** You're receiving numbers one by one and someone keeps asking "what's the median so far?" You need a structure that efficiently splits the data into the lower and upper half.

```cpp
class MedianFinder {
    priority_queue<int> lower;               // max-heap for lower half
    priority_queue<int, vector<int>, greater<int>> upper; // min-heap for upper half

public:
    void addNum(int num) {
        lower.push(num);  // always add to lower first

        // balance: lower max must be ≤ upper min
        if (!upper.empty() && lower.top() > upper.top()) {
            upper.push(lower.top()); lower.pop();
        }

        // balance sizes: lower can have at most 1 more than upper
        if (lower.size() > upper.size() + 1) {
            upper.push(lower.top()); lower.pop();
        } else if (upper.size() > lower.size()) {
            lower.push(upper.top()); upper.pop();
        }
    }

    double findMedian() {
        if (lower.size() == upper.size())
            return (lower.top() + upper.top()) / 2.0;
        return lower.top();
    }
};
// addNum: O(log n), findMedian: O(1)
```

### Dijkstra's Shortest Path

Heap is used to efficiently get the next closest unvisited node.

```cpp
vector<int> dijkstra(vector<vector<pair<int,int>>>& graph, int src) {
    int n = graph.size();
    vector<int> dist(n, INT_MAX);
    priority_queue<pair<int,int>, vector<pair<int,int>>, greater<>> pq;

    dist[src] = 0;
    pq.push({0, src});  // {distance, node}

    while (!pq.empty()) {
        auto [d, u] = pq.top(); pq.pop();
        if (d > dist[u]) continue;  // stale entry

        for (auto [weight, v] : graph[u]) {
            if (dist[u] + weight < dist[v]) {
                dist[v] = dist[u] + weight;
                pq.push({dist[v], v});
            }
        }
    }
    return dist;
}
// Time: O((V + E) log V)
```

---

## Practice Problems

1. Find the k-th smallest element in a sorted matrix.
2. Given a list of tasks with deadlines and profits, maximize profit (greedy + heap).
3. Find the smallest range covering elements from k sorted lists.
4. Implement a double-ended priority queue (supports both min and max).

---

## Answers to Selected Problems

**Problem 1 (K-th smallest in sorted matrix):**
```cpp
int kthSmallest(vector<vector<int>>& matrix, int k) {
    int n = matrix.size();
    // Min-heap: {value, row, col}
    priority_queue<tuple<int,int,int>, vector<tuple<int,int,int>>, greater<>> pq;
    for (int i = 0; i < min(n, k); i++) pq.push({matrix[i][0], i, 0});

    for (int i = 0; i < k-1; i++) {
        auto [val, r, c] = pq.top(); pq.pop();
        if (c+1 < n) pq.push({matrix[r][c+1], r, c+1});
    }
    return get<0>(pq.top());
}
```

---

## References

- Cormen et al. — *CLRS* — Chapter 6 (Heapsort)
- Sedgewick & Wayne — *Algorithms* — Chapter 2.4 (Priority Queues)
- Visualgo — [Heap visualization](https://visualgo.net/en/heap)
- LeetCode — [Heap problems](https://leetcode.com/tag/heap-priority-queue/)
