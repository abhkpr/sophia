# Trees

## Hierarchical Data

A tree is a connected acyclic graph where one node is designated as the root. It models hierarchical relationships — things that have parents and children.

**Real-world analogies:**
- **File system:** folders containing files and subfolders — a tree
- **Company org chart:** CEO at root, departments as children, employees as leaves
- **HTML DOM:** `<html>` at root, `<head>` and `<body>` as children
- **Decision making:** each node is a question, each edge is an answer

---

## Part 1 — Binary Tree

### Node Structure

```cpp
struct TreeNode {
    int val;
    TreeNode* left;
    TreeNode* right;
    TreeNode(int x) : val(x), left(nullptr), right(nullptr) {}
};
```

### Tree Terminology

```
          1          ← root
        /   \
       2     3       ← internal nodes
      / \     \
     4   5     6     ← 4,5,6 are leaves

Height: 3 (longest path from root to leaf)
Depth of node 5: 2 (distance from root)
Level: root is level 1 (or 0, depending on convention)
Degree: number of children (node 1 has degree 2)
```

---

## Part 2 — Tree Traversals

Traversals are how you visit every node. The order matters for different applications.

### Depth-First Traversals

**Inorder (Left → Root → Right):**
```cpp
void inorder(TreeNode* root) {
    if (!root) return;
    inorder(root->left);
    cout << root->val << " ";
    inorder(root->right);
}
// Output for BST: sorted order!
// Tree above: 4 2 5 1 3 6
```

**Preorder (Root → Left → Right):**
```cpp
void preorder(TreeNode* root) {
    if (!root) return;
    cout << root->val << " ";
    preorder(root->left);
    preorder(root->right);
}
// Used to: serialize tree, create copy
// Tree above: 1 2 4 5 3 6
```

**Postorder (Left → Right → Root):**
```cpp
void postorder(TreeNode* root) {
    if (!root) return;
    postorder(root->left);
    postorder(root->right);
    cout << root->val << " ";
}
// Used to: delete tree, evaluate expression trees
// Tree above: 4 5 2 6 3 1
```

**Iterative Inorder (using stack):**
```cpp
vector<int> inorderIterative(TreeNode* root) {
    vector<int> result;
    stack<TreeNode*> st;
    TreeNode* curr = root;

    while (curr || !st.empty()) {
        while (curr) {
            st.push(curr);
            curr = curr->left;
        }
        curr = st.top(); st.pop();
        result.push_back(curr->val);
        curr = curr->right;
    }
    return result;
}
```

### Breadth-First / Level Order Traversal

```cpp
vector<vector<int>> levelOrder(TreeNode* root) {
    if (!root) return {};
    vector<vector<int>> result;
    queue<TreeNode*> q;
    q.push(root);

    while (!q.empty()) {
        int levelSize = q.size();
        vector<int> level;
        for (int i = 0; i < levelSize; i++) {
            TreeNode* node = q.front(); q.pop();
            level.push_back(node->val);
            if (node->left) q.push(node->left);
            if (node->right) q.push(node->right);
        }
        result.push_back(level);
    }
    return result;
}
// [[1], [2,3], [4,5,6]]
```

---

## Part 3 — Binary Search Tree (BST)

A BST maintains the **BST property:** for every node, all values in the left subtree are smaller, all values in the right subtree are larger.

**Analogy:** A sorted filing system. To find a file, look at the current drawer label — too high, go left; too low, go right. You never need to check most drawers.

```
       8
      / \
     3   10
    / \    \
   1   6    14
      / \   /
     4   7 13
```

### BST Operations

```cpp
class BST {
    TreeNode* root = nullptr;

    TreeNode* insert(TreeNode* node, int val) {
        if (!node) return new TreeNode(val);
        if (val < node->val) node->left = insert(node->left, val);
        else if (val > node->val) node->right = insert(node->right, val);
        return node;
    }

    TreeNode* search(TreeNode* node, int val) {
        if (!node || node->val == val) return node;
        if (val < node->val) return search(node->left, val);
        return search(node->right, val);
    }

    TreeNode* findMin(TreeNode* node) {
        while (node->left) node = node->left;
        return node;
    }

    TreeNode* deleteNode(TreeNode* node, int val) {
        if (!node) return nullptr;
        if (val < node->val) node->left = deleteNode(node->left, val);
        else if (val > node->val) node->right = deleteNode(node->right, val);
        else {
            // Case 1: leaf node
            if (!node->left && !node->right) { delete node; return nullptr; }
            // Case 2: one child
            if (!node->left) { TreeNode* t = node->right; delete node; return t; }
            if (!node->right) { TreeNode* t = node->left; delete node; return t; }
            // Case 3: two children — replace with inorder successor
            TreeNode* successor = findMin(node->right);
            node->val = successor->val;
            node->right = deleteNode(node->right, successor->val);
        }
        return node;
    }

public:
    void insert(int val) { root = insert(root, val); }
    bool search(int val) { return search(root, val) != nullptr; }
    void remove(int val) { root = deleteNode(root, val); }
};
// All operations: O(h) where h = height
// Balanced BST: O(log n), Degenerate (linked list): O(n)
```

### BST Validation

```cpp
bool isValidBST(TreeNode* root, long min = LLONG_MIN, long max = LLONG_MAX) {
    if (!root) return true;
    if (root->val <= min || root->val >= max) return false;
    return isValidBST(root->left, min, root->val) &&
           isValidBST(root->right, root->val, max);
}
```

---

## Part 4 — Common Tree Problems

### Height of Tree

```cpp
int height(TreeNode* root) {
    if (!root) return 0;
    return 1 + max(height(root->left), height(root->right));
}
```

### Diameter of Binary Tree

Longest path between any two nodes (may not pass through root).

```cpp
int diameter(TreeNode* root) {
    int maxDiam = 0;
    function<int(TreeNode*)> height = [&](TreeNode* node) -> int {
        if (!node) return 0;
        int left = height(node->left);
        int right = height(node->right);
        maxDiam = max(maxDiam, left + right);
        return 1 + max(left, right);
    };
    height(root);
    return maxDiam;
}
```

### Lowest Common Ancestor (LCA)

The deepest node that is an ancestor of both p and q.

```cpp
TreeNode* LCA(TreeNode* root, TreeNode* p, TreeNode* q) {
    if (!root || root == p || root == q) return root;
    TreeNode* left = LCA(root->left, p, q);
    TreeNode* right = LCA(root->right, p, q);
    if (left && right) return root;  // p and q in different subtrees
    return left ? left : right;
}
```

### Path Sum

Check if any root-to-leaf path has a given sum.

```cpp
bool hasPathSum(TreeNode* root, int target) {
    if (!root) return false;
    if (!root->left && !root->right) return root->val == target;
    return hasPathSum(root->left, target - root->val) ||
           hasPathSum(root->right, target - root->val);
}
```

### Maximum Path Sum

Path between any two nodes.

```cpp
int maxPathSum(TreeNode* root) {
    int maxSum = INT_MIN;
    function<int(TreeNode*)> dfs = [&](TreeNode* node) -> int {
        if (!node) return 0;
        int left = max(0, dfs(node->left));   // ignore negative paths
        int right = max(0, dfs(node->right));
        maxSum = max(maxSum, node->val + left + right);
        return node->val + max(left, right);  // can only extend in one direction
    };
    dfs(root);
    return maxSum;
}
```

### Serialize and Deserialize

Convert tree to/from string representation.

```cpp
string serialize(TreeNode* root) {
    if (!root) return "null,";
    return to_string(root->val) + "," +
           serialize(root->left) + serialize(root->right);
}

TreeNode* deserialize(string data) {
    queue<string> tokens;
    stringstream ss(data);
    string token;
    while (getline(ss, token, ',')) tokens.push(token);

    function<TreeNode*()> build = [&]() -> TreeNode* {
        string val = tokens.front(); tokens.pop();
        if (val == "null") return nullptr;
        TreeNode* node = new TreeNode(stoi(val));
        node->left = build();
        node->right = build();
        return node;
    };
    return build();
}
```

---

## Part 5 — Balanced Trees

### AVL Tree (Self-Balancing BST)

Maintains height balance: for every node, |height(left) - height(right)| ≤ 1.

**Balance factor = height(left) - height(right)**

When balance factor becomes ±2 after an insert/delete, rotations restore balance.

```
LL Rotation (single right rotate):
    z                 y
   /                 / \
  y         →       x   z
 /
x

LR Rotation (left-right double rotate):
    z                 x
   /                 / \
  y         →       y   z
   \
    x
```

```cpp
int getHeight(TreeNode* node) { return node ? node->height : 0; }
int getBalance(TreeNode* node) {
    return node ? getHeight(node->left) - getHeight(node->right) : 0;
}

TreeNode* rightRotate(TreeNode* z) {
    TreeNode* y = z->left;
    TreeNode* T3 = y->right;
    y->right = z;
    z->left = T3;
    z->height = 1 + max(getHeight(z->left), getHeight(z->right));
    y->height = 1 + max(getHeight(y->left), getHeight(y->right));
    return y;
}
```

**All BST operations remain O(log n)** because height is always O(log n).

---

## Practice Problems

**Easy:**
1. Find the maximum element in a binary tree.
2. Count the number of nodes in a binary tree.
3. Check if two binary trees are identical.

**Medium:**
4. Find all root-to-leaf paths in a binary tree.
5. Convert a sorted array to a height-balanced BST.
6. Zigzag level order traversal.
7. Right side view of a binary tree.

**Hard:**
8. Recover a BST where two nodes are swapped.
9. Flatten a binary tree to linked list in-place.
10. Binary tree maximum path sum.

---

## Answers to Selected Problems

**Problem 5 (Sorted array to BST):**
```cpp
TreeNode* sortedArrayToBST(vector<int>& nums, int left, int right) {
    if (left > right) return nullptr;
    int mid = left + (right - left) / 2;
    TreeNode* node = new TreeNode(nums[mid]);
    node->left = sortedArrayToBST(nums, left, mid - 1);
    node->right = sortedArrayToBST(nums, mid + 1, right);
    return node;
}
// Pick middle as root → guarantees height balance
```

**Problem 7 (Right side view):**
```cpp
vector<int> rightSideView(TreeNode* root) {
    vector<int> result;
    queue<TreeNode*> q;
    if (root) q.push(root);

    while (!q.empty()) {
        int size = q.size();
        for (int i = 0; i < size; i++) {
            TreeNode* node = q.front(); q.pop();
            if (i == size - 1) result.push_back(node->val);  // last node in level
            if (node->left) q.push(node->left);
            if (node->right) q.push(node->right);
        }
    }
    return result;
}
```

---

## References

- Cormen et al. — *CLRS* — Chapters 12, 13 (BST and Red-Black Trees)
- Sedgewick & Wayne — *Algorithms* — Chapter 3 (Symbol Tables)
- Visualgo — [BST visualization](https://visualgo.net/en/bst)
- LeetCode — [Tree problems](https://leetcode.com/tag/tree/)
