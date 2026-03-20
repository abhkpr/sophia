# Graphs

## Modeling Relationships

A graph models pairwise relationships between objects. When you can phrase a problem as "things connected to other things," you have a graph problem.

**Real-world examples:**
- **Social network:** users are nodes, friendships are edges
- **Maps:** cities are nodes, roads are edges with weights (distances)
- **Web:** pages are nodes, hyperlinks are edges
- **Dependencies:** tasks are nodes, "must complete before" are directed edges
- **Network routing:** routers are nodes, connections are edges

---

## Part 1 — Graph Representations

### Adjacency List

```cpp
// Unweighted undirected
vector<vector<int>> adj(n);
adj[u].push_back(v);
adj[v].push_back(u);

// Weighted
vector<vector<pair<int,int>>> adj(n);  // adj[u] = {v, weight}
adj[u].push_back({v, w});

// Using map for non-integer vertices
unordered_map<string, vector<string>> adj;
adj["Alice"].push_back("Bob");
```

### Adjacency Matrix

```cpp
vector<vector<int>> matrix(n, vector<int>(n, 0));
matrix[u][v] = 1;  // unweighted
matrix[u][v] = w;  // weighted
// Space: O(V²) — use only for dense graphs
```

### Edge List

```cpp
vector<tuple<int,int,int>> edges;  // {u, v, weight}
edges.push_back({u, v, w});
// Useful for Kruskal's MST algorithm
```

---

## Part 2 — Graph Traversals

### BFS — Breadth-First Search

Explore all neighbors before going deeper. Uses a queue. Finds shortest path in unweighted graphs.

**Analogy:** Ripples in a pond — level by level outward from the source.

```cpp
vector<int> bfs(vector<vector<int>>& adj, int src) {
    int n = adj.size();
    vector<bool> visited(n, false);
    vector<int> order;
    queue<int> q;

    visited[src] = true;
    q.push(src);

    while (!q.empty()) {
        int u = q.front(); q.pop();
        order.push_back(u);
        for (int v : adj[u]) {
            if (!visited[v]) {
                visited[v] = true;
                q.push(v);
            }
        }
    }
    return order;
}
// Time: O(V + E), Space: O(V)
```

**BFS Shortest Path:**

```cpp
vector<int> shortestPath(vector<vector<int>>& adj, int src) {
    int n = adj.size();
    vector<int> dist(n, -1);
    queue<int> q;

    dist[src] = 0;
    q.push(src);

    while (!q.empty()) {
        int u = q.front(); q.pop();
        for (int v : adj[u]) {
            if (dist[v] == -1) {
                dist[v] = dist[u] + 1;
                q.push(v);
            }
        }
    }
    return dist;  // dist[v] = shortest path from src to v, -1 if unreachable
}
```

### DFS — Depth-First Search

Go as deep as possible before backtracking. Uses a stack (or recursion).

**Analogy:** Exploring a maze — follow one path to its end, then backtrack.

```cpp
void dfs(vector<vector<int>>& adj, int u, vector<bool>& visited) {
    visited[u] = true;
    cout << u << " ";
    for (int v : adj[u])
        if (!visited[v])
            dfs(adj, v, visited);
}
// Call: dfs(adj, 0, visited);
// Time: O(V + E), Space: O(V) — recursion stack

// Iterative DFS
void dfsIterative(vector<vector<int>>& adj, int src) {
    vector<bool> visited(adj.size(), false);
    stack<int> st;
    st.push(src);

    while (!st.empty()) {
        int u = st.top(); st.pop();
        if (visited[u]) continue;
        visited[u] = true;
        cout << u << " ";
        for (int v : adj[u])
            if (!visited[v]) st.push(v);
    }
}
```

---

## Part 3 — Key Graph Algorithms

### Topological Sort

Linear ordering of vertices in a DAG (Directed Acyclic Graph) such that for every edge u→v, u comes before v.

**Use cases:** Task scheduling, build systems (Makefile), course prerequisites, package dependencies.

**Kahn's Algorithm (BFS-based):**

```cpp
vector<int> topoSort(int n, vector<vector<int>>& adj) {
    vector<int> inDegree(n, 0);
    for (int u = 0; u < n; u++)
        for (int v : adj[u]) inDegree[v]++;

    queue<int> q;
    for (int i = 0; i < n; i++)
        if (inDegree[i] == 0) q.push(i);

    vector<int> order;
    while (!q.empty()) {
        int u = q.front(); q.pop();
        order.push_back(u);
        for (int v : adj[u]) {
            inDegree[v]--;
            if (inDegree[v] == 0) q.push(v);
        }
    }
    // if order.size() != n → cycle exists
    return order;
}
// Time: O(V + E)
```

### Cycle Detection

**Undirected graph — DFS:**
```cpp
bool hasCycle(vector<vector<int>>& adj, int u, int parent, vector<bool>& visited) {
    visited[u] = true;
    for (int v : adj[u]) {
        if (!visited[v]) {
            if (hasCycle(adj, v, u, visited)) return true;
        } else if (v != parent) {  // found visited non-parent neighbor → cycle
            return true;
        }
    }
    return false;
}
```

**Directed graph — DFS with coloring:**
```cpp
// 0=white(unvisited), 1=gray(in stack), 2=black(done)
bool hasCycleDFS(vector<vector<int>>& adj, int u, vector<int>& color) {
    color[u] = 1;
    for (int v : adj[u]) {
        if (color[v] == 1) return true;   // back edge → cycle
        if (color[v] == 0 && hasCycleDFS(adj, v, color)) return true;
    }
    color[u] = 2;
    return false;
}
```

### Connected Components

```cpp
int countComponents(int n, vector<vector<int>>& adj) {
    vector<bool> visited(n, false);
    int count = 0;
    for (int i = 0; i < n; i++) {
        if (!visited[i]) {
            dfs(adj, i, visited);
            count++;
        }
    }
    return count;
}
```

---

## Part 4 — Shortest Path Algorithms

### Dijkstra's Algorithm

Single-source shortest path for non-negative weights.

**Analogy:** Spreading water from a source. Water flows to closest points first, gradually filling further areas.

```cpp
vector<int> dijkstra(int n, vector<vector<pair<int,int>>>& adj, int src) {
    vector<int> dist(n, INT_MAX);
    priority_queue<pair<int,int>, vector<pair<int,int>>, greater<>> pq;

    dist[src] = 0;
    pq.push({0, src});  // {distance, node}

    while (!pq.empty()) {
        auto [d, u] = pq.top(); pq.pop();
        if (d > dist[u]) continue;  // outdated entry

        for (auto [v, w] : adj[u]) {
            if (dist[u] + w < dist[v]) {
                dist[v] = dist[u] + w;
                pq.push({dist[v], v});
            }
        }
    }
    return dist;
}
// Time: O((V + E) log V), Space: O(V)
// Does NOT work with negative weights
```

### Bellman-Ford Algorithm

Handles negative weights. Detects negative cycles.

```cpp
vector<int> bellmanFord(int n, vector<tuple<int,int,int>>& edges, int src) {
    vector<int> dist(n, INT_MAX);
    dist[src] = 0;

    // Relax all edges V-1 times
    for (int i = 0; i < n-1; i++) {
        for (auto [u, v, w] : edges) {
            if (dist[u] != INT_MAX && dist[u] + w < dist[v])
                dist[v] = dist[u] + w;
        }
    }

    // Check for negative cycles (one more relaxation)
    for (auto [u, v, w] : edges)
        if (dist[u] != INT_MAX && dist[u] + w < dist[v])
            return {};  // negative cycle detected

    return dist;
}
// Time: O(VE), Space: O(V)
```

### Floyd-Warshall — All Pairs Shortest Path

```cpp
vector<vector<int>> floydWarshall(vector<vector<int>>& dist) {
    int n = dist.size();
    // dist[i][j] = direct edge weight (INF if no edge)

    for (int k = 0; k < n; k++)
        for (int i = 0; i < n; i++)
            for (int j = 0; j < n; j++)
                if (dist[i][k] != INT_MAX && dist[k][j] != INT_MAX)
                    dist[i][j] = min(dist[i][j], dist[i][k] + dist[k][j]);

    return dist;
}
// Time: O(V³), Space: O(V²)
// Intuition: "Is going through vertex k a shortcut?"
```

---

## Part 5 — Minimum Spanning Tree

### Union-Find (Disjoint Set Union)

Foundation for Kruskal's algorithm.

```cpp
class UnionFind {
    vector<int> parent, rank;
public:
    UnionFind(int n) : parent(n), rank(n, 0) {
        iota(parent.begin(), parent.end(), 0);
    }

    int find(int x) {
        if (parent[x] != x)
            parent[x] = find(parent[x]);  // path compression
        return parent[x];
    }

    bool unite(int x, int y) {
        int px = find(x), py = find(y);
        if (px == py) return false;  // already connected
        // union by rank
        if (rank[px] < rank[py]) swap(px, py);
        parent[py] = px;
        if (rank[px] == rank[py]) rank[px]++;
        return true;
    }

    bool connected(int x, int y) { return find(x) == find(y); }
};
// find: O(α(n)) ≈ O(1) amortized
```

### Kruskal's MST

```cpp
int kruskal(int n, vector<tuple<int,int,int>>& edges) {
    // Sort edges by weight
    sort(edges.begin(), edges.end());
    UnionFind uf(n);
    int mstWeight = 0, edgesUsed = 0;

    for (auto [w, u, v] : edges) {
        if (uf.unite(u, v)) {
            mstWeight += w;
            edgesUsed++;
            if (edgesUsed == n-1) break;
        }
    }
    return mstWeight;  // returns -1 if graph not connected
}
// Time: O(E log E)
```

---

## Part 6 — Common Graph Problems

### Number of Islands

```cpp
int numIslands(vector<vector<char>>& grid) {
    int rows = grid.size(), cols = grid[0].size(), count = 0;

    function<void(int,int)> dfs = [&](int r, int c) {
        if (r < 0 || r >= rows || c < 0 || c >= cols || grid[r][c] != '1') return;
        grid[r][c] = '0';  // mark visited
        dfs(r+1,c); dfs(r-1,c); dfs(r,c+1); dfs(r,c-1);
    };

    for (int r = 0; r < rows; r++)
        for (int c = 0; c < cols; c++)
            if (grid[r][c] == '1') { dfs(r, c); count++; }

    return count;
}
```

### Course Schedule (Cycle Detection in Directed Graph)

```cpp
bool canFinish(int n, vector<vector<int>>& prerequisites) {
    vector<vector<int>> adj(n);
    for (auto& p : prerequisites) adj[p[1]].push_back(p[0]);

    vector<int> state(n, 0);  // 0=unvisited, 1=processing, 2=done
    function<bool(int)> dfs = [&](int u) -> bool {
        state[u] = 1;
        for (int v : adj[u]) {
            if (state[v] == 1) return false;  // cycle
            if (state[v] == 0 && !dfs(v)) return false;
        }
        state[u] = 2;
        return true;
    };

    for (int i = 0; i < n; i++)
        if (state[i] == 0 && !dfs(i)) return false;
    return true;
}
```

---

## Practice Problems

1. Find if a path exists between two nodes in an undirected graph.
2. Find the shortest path in a maze (0=open, 1=wall) from top-left to bottom-right.
3. Clone a graph (deep copy).
4. Find all strongly connected components (Tarjan's algorithm).
5. Find the critical connections (bridges) in a network.

---

## References

- Cormen et al. — *CLRS* — Chapters 22-25
- Sedgewick & Wayne — *Algorithms* — Chapter 4
- Visualgo — [Graph visualization](https://visualgo.net/en/graphds)
- LeetCode — [Graph problems](https://leetcode.com/tag/graph/)
- CP-algorithms — [Graph algorithms](https://cp-algorithms.com/graph/)
