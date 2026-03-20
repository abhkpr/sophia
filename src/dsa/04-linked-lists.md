# Linked Lists

## Why Linked Lists?

Arrays are great for random access but terrible for insertion and deletion in the middle — shifting elements costs O(n). Linked lists flip this tradeoff: O(1) insertion/deletion anywhere, but O(n) access by index.

**Real-world analogy:** A train. Each carriage (node) is connected to the next. Adding or removing a carriage in the middle only requires disconnecting two links and reconnecting them — you don't move all the other carriages. But to reach carriage 47, you must walk through all 46 before it.

---

## Part 1 — Node Structure

```cpp
struct Node {
    int data;
    Node* next;
    Node(int val) : data(val), next(nullptr) {}
};

// Doubly linked list node
struct DNode {
    int data;
    DNode* prev;
    DNode* next;
    DNode(int val) : data(val), prev(nullptr), next(nullptr) {}
};
```

### Types of Linked Lists

```
Singly linked:    head → [1] → [2] → [3] → null
Doubly linked:    null ← [1] ↔ [2] ↔ [3] → null
Circular singly:  head → [1] → [2] → [3] ↩ (back to head)
Circular doubly:  [1] ↔ [2] ↔ [3] ↩ (wraps both ways)
```

---

## Part 2 — Basic Operations

### Linked List Class

```cpp
class LinkedList {
public:
    Node* head;
    LinkedList() : head(nullptr) {}

    // Insert at front — O(1)
    void pushFront(int val) {
        Node* node = new Node(val);
        node->next = head;
        head = node;
    }

    // Insert at back — O(n)
    void pushBack(int val) {
        Node* node = new Node(val);
        if (!head) { head = node; return; }
        Node* curr = head;
        while (curr->next) curr = curr->next;
        curr->next = node;
    }

    // Insert after a given node — O(1) given the node
    void insertAfter(Node* prev, int val) {
        if (!prev) return;
        Node* node = new Node(val);
        node->next = prev->next;
        prev->next = node;
    }

    // Delete by value — O(n)
    void deleteVal(int val) {
        if (!head) return;
        if (head->data == val) {
            Node* temp = head;
            head = head->next;
            delete temp;
            return;
        }
        Node* curr = head;
        while (curr->next && curr->next->data != val)
            curr = curr->next;
        if (curr->next) {
            Node* temp = curr->next;
            curr->next = temp->next;
            delete temp;
        }
    }

    // Search — O(n)
    Node* search(int val) {
        Node* curr = head;
        while (curr) {
            if (curr->data == val) return curr;
            curr = curr->next;
        }
        return nullptr;
    }

    // Print — O(n)
    void print() {
        Node* curr = head;
        while (curr) {
            cout << curr->data;
            if (curr->next) cout << " → ";
            curr = curr->next;
        }
        cout << " → null\n";
    }

    // Length — O(n)
    int length() {
        int count = 0;
        Node* curr = head;
        while (curr) { count++; curr = curr->next; }
        return count;
    }
};
```

---

## Part 3 — Classic Linked List Problems

### Reverse a Linked List

**Iterative:**

```cpp
Node* reverse(Node* head) {
    Node* prev = nullptr;
    Node* curr = head;
    while (curr) {
        Node* next = curr->next;  // save next
        curr->next = prev;        // reverse pointer
        prev = curr;              // advance prev
        curr = next;              // advance curr
    }
    return prev;  // new head
}
```

**Recursive:**

```cpp
Node* reverseRecursive(Node* head) {
    if (!head || !head->next) return head;
    Node* newHead = reverseRecursive(head->next);
    head->next->next = head;  // reverse pointer
    head->next = nullptr;
    return newHead;
}
```

**Visualizing the iterative approach:**
```
Initial:  null ← prev   curr → [1] → [2] → [3] → null

Step 1:   null ← [1]    curr → [2] → [3] → null
Step 2:   null ← [1] ← [2]    curr → [3] → null
Step 3:   null ← [1] ← [2] ← [3]    curr = null

Result:   [3] → [2] → [1] → null
```

### Detect Cycle — Floyd's Algorithm

**Real-world analogy:** Two runners on a circular track. The faster one will eventually lap the slower one — they'll meet. If the track is straight (no cycle), the faster one just reaches the end.

```cpp
bool hasCycle(Node* head) {
    Node* slow = head, *fast = head;
    while (fast && fast->next) {
        slow = slow->next;
        fast = fast->next->next;
        if (slow == fast) return true;
    }
    return false;
}
```

**Find the start of the cycle:**

```cpp
Node* detectCycleStart(Node* head) {
    Node* slow = head, *fast = head;
    bool hasCycle = false;

    while (fast && fast->next) {
        slow = slow->next;
        fast = fast->next->next;
        if (slow == fast) { hasCycle = true; break; }
    }

    if (!hasCycle) return nullptr;

    // Move slow to head, keep fast at meeting point
    // They'll meet at cycle start
    slow = head;
    while (slow != fast) {
        slow = slow->next;
        fast = fast->next;
    }
    return slow;
}
```

**Why does this work?** Mathematical proof: if the cycle starts at distance k from head, and the cycle has length c, the meeting point is at distance k from the cycle start. Moving one pointer to head and advancing both at same speed results in meeting exactly at the cycle start.

### Find Middle Node

```cpp
Node* findMiddle(Node* head) {
    Node* slow = head, *fast = head;
    while (fast && fast->next) {
        slow = slow->next;
        fast = fast->next->next;
    }
    return slow;  // slow is at middle
}
// 1→2→3→4→5 → returns node 3
// 1→2→3→4   → returns node 2 (first middle)
```

### Merge Two Sorted Lists

```cpp
Node* mergeSorted(Node* l1, Node* l2) {
    Node dummy(0);
    Node* curr = &dummy;

    while (l1 && l2) {
        if (l1->data <= l2->data) {
            curr->next = l1;
            l1 = l1->next;
        } else {
            curr->next = l2;
            l2 = l2->next;
        }
        curr = curr->next;
    }
    curr->next = l1 ? l1 : l2;
    return dummy.next;
}
// Time: O(m+n), Space: O(1)
```

### Remove Nth Node From End

**Two pointer trick:** Advance fast pointer n steps, then move both until fast reaches end.

```cpp
Node* removeNthFromEnd(Node* head, int n) {
    Node dummy(0);
    dummy.next = head;
    Node* fast = &dummy, *slow = &dummy;

    // advance fast n+1 steps
    for (int i = 0; i <= n; i++) fast = fast->next;

    // move both until fast is null
    while (fast) {
        slow = slow->next;
        fast = fast->next;
    }

    // slow is now at the node before the one to delete
    Node* toDelete = slow->next;
    slow->next = slow->next->next;
    delete toDelete;
    return dummy.next;
}
```

### Intersection of Two Linked Lists

```cpp
Node* getIntersection(Node* headA, Node* headB) {
    Node* a = headA, *b = headB;
    // When a reaches end, redirect to headB
    // When b reaches end, redirect to headA
    // They'll meet at intersection (or both reach null if no intersection)
    while (a != b) {
        a = a ? a->next : headB;
        b = b ? b->next : headA;
    }
    return a;
}
// Key insight: both pointers travel the same total distance
// a travels: lenA + lenB, b travels: lenB + lenA
```

### Reverse in Groups of K

```cpp
Node* reverseKGroup(Node* head, int k) {
    Node* curr = head;
    int count = 0;
    while (curr && count < k) { curr = curr->next; count++; }
    if (count < k) return head;  // fewer than k remaining

    // reverse k nodes
    Node* prev = nullptr;
    curr = head;
    for (int i = 0; i < k; i++) {
        Node* next = curr->next;
        curr->next = prev;
        prev = curr;
        curr = next;
    }
    // head is now tail of reversed group
    head->next = reverseKGroup(curr, k);
    return prev;
}
```

---

## Part 4 — Doubly Linked List

```cpp
class DoublyLinkedList {
public:
    DNode* head, *tail;
    DoublyLinkedList() : head(nullptr), tail(nullptr) {}

    void pushBack(int val) {
        DNode* node = new DNode(val);
        if (!tail) { head = tail = node; return; }
        node->prev = tail;
        tail->next = node;
        tail = node;
    }

    void pushFront(int val) {
        DNode* node = new DNode(val);
        if (!head) { head = tail = node; return; }
        node->next = head;
        head->prev = node;
        head = node;
    }

    // O(1) delete given node pointer
    void deleteNode(DNode* node) {
        if (node->prev) node->prev->next = node->next;
        else head = node->next;
        if (node->next) node->next->prev = node->prev;
        else tail = node->prev;
        delete node;
    }
};
```

**Use case:** LRU Cache — doubly linked list allows O(1) deletion from any position.

---

## Part 5 — LRU Cache Implementation

A classic interview problem combining doubly linked list + hash map.

```cpp
class LRUCache {
    int capacity;
    list<pair<int,int>> cache;  // {key, value}, front = most recent
    unordered_map<int, list<pair<int,int>>::iterator> map;

public:
    LRUCache(int cap) : capacity(cap) {}

    int get(int key) {
        if (!map.count(key)) return -1;
        // Move to front (most recently used)
        cache.splice(cache.begin(), cache, map[key]);
        return map[key]->second;
    }

    void put(int key, int value) {
        if (map.count(key)) {
            map[key]->second = value;
            cache.splice(cache.begin(), cache, map[key]);
            return;
        }
        if (cache.size() == capacity) {
            map.erase(cache.back().first);
            cache.pop_back();
        }
        cache.push_front({key, value});
        map[key] = cache.begin();
    }
};
// All operations O(1)
```

---

## Practice Problems

**Easy:**
1. Find the length of a linked list.
2. Delete all occurrences of a given value from a linked list.
3. Check if a linked list is a palindrome.

**Medium:**
4. Sort a linked list using merge sort.
5. Add two numbers represented as linked lists (digits in reverse order).
6. Flatten a multilevel doubly linked list.

**Hard:**
7. Copy a linked list with random pointers.
8. Find the starting node of a cycle in a linked list.

---

## Answers to Selected Problems

**Problem 3 (Palindrome check):**
```cpp
bool isPalindrome(Node* head) {
    // 1. Find middle
    Node* slow = head, *fast = head;
    while (fast && fast->next) {
        slow = slow->next;
        fast = fast->next->next;
    }
    // 2. Reverse second half
    Node* prev = nullptr, *curr = slow;
    while (curr) {
        Node* next = curr->next;
        curr->next = prev;
        prev = curr;
        curr = next;
    }
    // 3. Compare
    Node* left = head, *right = prev;
    while (right) {
        if (left->data != right->data) return false;
        left = left->next;
        right = right->next;
    }
    return true;
}
```

**Problem 5 (Add two numbers):**
```cpp
Node* addTwoNumbers(Node* l1, Node* l2) {
    Node dummy(0);
    Node* curr = &dummy;
    int carry = 0;

    while (l1 || l2 || carry) {
        int sum = carry;
        if (l1) { sum += l1->data; l1 = l1->next; }
        if (l2) { sum += l2->data; l2 = l2->next; }
        carry = sum / 10;
        curr->next = new Node(sum % 10);
        curr = curr->next;
    }
    return dummy.next;
}
// l1: 2→4→3 (342), l2: 5→6→4 (465) → 7→0→8 (807)
```

---

## References

- Cormen et al. — *CLRS* — Chapter 10 (Elementary Data Structures)
- LeetCode — [Linked List problems](https://leetcode.com/tag/linked-list/)
- Visualgo — [Linked List visualization](https://visualgo.net/en/list)
