# Graph Theory

## Why Graph Theory?

Almost every hard problem in computer science — from routing internet packets to social network analysis to compiler optimization — is a graph problem in disguise. When you model data as nodes and relationships as edges, you've entered the domain of graph theory.

**Real-world graphs everywhere:**
- **Internet:** web pages are nodes, hyperlinks are edges
- **Social networks:** people are nodes, friendships are edges
- **Maps:** cities are nodes, roads are edges with weights (distances)
- **Dependencies:** tasks are nodes, "must complete before" relationships are edges
- **Circuits:** components are nodes, wires are edges

---

## Part 1 — Fundamentals

### Defining a Graph

A **graph** G = (V, E) consists of:
- **V** — a set of vertices (nodes)
- **E** — a set of edges connecting pairs of vertices

```
V = {A, B, C, D}
E = {(A,B), (B,C), (C,D), (A,D)}

    A --- B
    |     |
    D --- C
```

### Types of Graphs

#### Undirected Graph
Edges have no direction — (u, v) and (v, u) are the same edge.

**Example:** Facebook friendships — if A is friends with B, then B is friends with A.

#### Directed Graph (Digraph)
Edges have direction — (u, v) means u → v.

**Example:** Twitter follows — A follows B does not mean B follows A.

```
A → B → C
↑       |
└───────┘
```

#### Weighted Graph
Each edge has a numerical weight.

**Example:** Road network where weights are distances or travel times.

```
A --5-- B
|       |
3       2
|       |
D --8-- C
```

#### Simple Graph
No self-loops (edge from a vertex to itself) and no multiple edges between same vertices.

#### Multigraph
Allows multiple edges between the same pair of vertices.

### Terminology

**Degree of a vertex:** Number of edges incident to it.

```
In the graph:  A-B, A-C, A-D, B-C
deg(A) = 3
deg(B) = 2
deg(C) = 2
deg(D) = 1
```

**Handshaking Theorem:**
```
Sum of all degrees = 2 × |E|
```

Every edge contributes 2 to the total degree count (one for each endpoint).

**Corollary:** The number of odd-degree vertices is always even.

**In directed graphs:**
- **In-degree:** number of edges pointing TO a vertex
- **Out-degree:** number of edges pointing FROM a vertex

### Special Graphs

**Complete graph Kₙ:** Every pair of vertices is connected.
```
K₄ has 4 vertices, each connected to all others.
|E| = n(n-1)/2 = 4(3)/2 = 6 edges
```

**Cycle graph Cₙ:** n vertices connected in a cycle.

**Path graph Pₙ:** n vertices in a line.

**Bipartite graph:** Vertices split into two groups; edges only go between groups, never within.

**Example:** Job assignment — workers on one side, jobs on the other. Edges = "worker can do job."

**Complete bipartite Kₘ,ₙ:** Every vertex in group 1 connected to every vertex in group 2.

---

## Part 2 — Graph Representations

How you represent a graph dramatically affects algorithm performance.

### Adjacency Matrix

An n×n matrix where entry [i][j] = 1 if edge (i,j) exists, else 0.

```
Graph: 1-2, 1-3, 2-3, 2-4

     1  2  3  4
1  [ 0  1  1  0 ]
2  [ 1  0  1  1 ]
3  [ 1  1  0  0 ]
4  [ 0  1  0  0 ]
```

**Pros:** O(1) edge lookup
**Cons:** O(V²) space — wasteful for sparse graphs

### Adjacency List

Each vertex stores a list of its neighbors.

```
1: [2, 3]
2: [1, 3, 4]
3: [1, 2]
4: [2]
```

**Pros:** O(V + E) space — efficient for sparse graphs
**Cons:** O(degree) edge lookup

**In code:**
```python
graph = {
    1: [2, 3],
    2: [1, 3, 4],
    3: [1, 2],
    4: [2]
}
```

**When to use which:**
- Dense graph (many edges): adjacency matrix
- Sparse graph (few edges): adjacency list
- Most real-world graphs are sparse — use adjacency list

---

## Part 3 — Graph Traversals

### Breadth-First Search (BFS)

Explore all neighbors before going deeper. Uses a queue.

**Analogy:** Ripples in a pond — explore level by level outward from the source.

```
Graph:      1
           / \
          2   3
         / \   \
        4   5   6

BFS from 1: 1, 2, 3, 4, 5, 6
```

**Algorithm:**
```python
from collections import deque

def bfs(graph, start):
    visited = set()
    queue = deque([start])
    visited.add(start)
    order = []

    while queue:
        vertex = queue.popleft()
        order.append(vertex)
        for neighbor in graph[vertex]:
            if neighbor not in visited:
                visited.add(neighbor)
                queue.append(neighbor)
    return order
```

**Time:** O(V + E)
**Space:** O(V)

**Applications:**
- Shortest path in unweighted graphs
- Level-order traversal of trees
- Web crawlers
- Finding connected components

### Depth-First Search (DFS)

Go as deep as possible before backtracking. Uses a stack (or recursion).

**Analogy:** Exploring a maze — follow one path until dead end, then backtrack and try another.

```
Graph:      1
           / \
          2   3
         / \   \
        4   5   6

DFS from 1: 1, 2, 4, 5, 3, 6
```

**Algorithm (recursive):**
```python
def dfs(graph, vertex, visited=None):
    if visited is None:
        visited = set()
    visited.add(vertex)
    print(vertex)
    for neighbor in graph[vertex]:
        if neighbor not in visited:
            dfs(graph, neighbor, visited)
    return visited
```

**Time:** O(V + E)
**Space:** O(V) — recursion stack

**Applications:**
- Cycle detection
- Topological sorting
- Finding strongly connected components
- Solving mazes and puzzles

---

## Part 4 — Paths and Connectivity

### Paths and Cycles

**Walk:** A sequence of vertices where consecutive vertices are connected by edges. Can repeat vertices and edges.

**Path:** A walk with no repeated vertices.

**Cycle:** A path that starts and ends at the same vertex.

**Simple path:** No repeated vertices or edges.

**Length:** Number of edges in the path.

### Connectivity

A graph is **connected** if there is a path between every pair of vertices.

**Connected components:** Maximal connected subgraphs.

```
Graph: {1-2, 2-3, 4-5}
Components: {1,2,3} and {4,5}
```

**Strongly connected (directed graphs):** There is a directed path from every vertex to every other vertex.

### Shortest Paths

**Unweighted graphs:** BFS finds shortest path (fewest edges).

**Weighted graphs:** Dijkstra's algorithm finds shortest path (minimum total weight).

**Dijkstra's Algorithm:**
```python
import heapq

def dijkstra(graph, start):
    # graph[u] = [(weight, v), ...]
    distances = {v: float('inf') for v in graph}
    distances[start] = 0
    pq = [(0, start)]

    while pq:
        dist, u = heapq.heappop(pq)
        if dist > distances[u]:
            continue
        for weight, v in graph[u]:
            new_dist = dist + weight
            if new_dist < distances[v]:
                distances[v] = new_dist
                heapq.heappush(pq, (new_dist, v))

    return distances
```

**Time:** O((V + E) log V) with a priority queue.

**Limitation:** Dijkstra doesn't work with negative edge weights. Use Bellman-Ford instead.

---

## Part 5 — Special Topics

### Trees

A **tree** is a connected acyclic graph.

**Properties of a tree with n vertices:**
- Exactly n-1 edges
- There is exactly one path between any two vertices
- Removing any edge disconnects it
- Adding any edge creates a cycle

**Rooted tree:** One vertex designated as the root; defines parent-child relationships.

**Application:** File systems, HTML DOM, binary search trees, decision trees, parse trees in compilers — all trees.

### Spanning Trees

A **spanning tree** of a connected graph G is a subgraph that:
- Is a tree
- Includes all vertices of G

**Minimum spanning tree (MST):** Spanning tree with minimum total edge weight.

**Applications:** Network design (connect all cities with minimum cable), clustering, approximation algorithms.

**Kruskal's Algorithm:**
```
1. Sort all edges by weight
2. For each edge (in order):
   - If adding it doesn't create a cycle, add it to MST
   - Use Union-Find to detect cycles efficiently
3. Stop when n-1 edges added
```

**Time:** O(E log E)

**Prim's Algorithm:**
```
1. Start with any vertex
2. Repeatedly add the minimum weight edge
   that connects the current tree to a new vertex
3. Stop when all vertices included
```

### Euler Paths and Circuits

**Euler path:** A path that uses every edge exactly once.
**Euler circuit:** An Euler path that starts and ends at the same vertex.

**Königsberg Bridge Problem** — the original graph theory problem (Euler, 1736):
Seven bridges connecting parts of Königsberg — can you walk across each bridge exactly once?

**Euler's Answer:**
- Euler circuit exists ↔ graph is connected AND every vertex has even degree
- Euler path exists ↔ graph is connected AND exactly 0 or 2 vertices have odd degree

**Application:** Route optimization (garbage collection, snowplowing), DNA fragment assembly.

### Hamiltonian Paths and Circuits

**Hamiltonian path:** Visits every **vertex** exactly once.
**Hamiltonian circuit:** A Hamiltonian path that returns to start.

Unlike Euler paths, no simple characterization exists. Finding one is NP-complete — this is the Traveling Salesman Problem (TSP).

**TSP:** Given a weighted complete graph, find the minimum weight Hamiltonian circuit.

### Graph Coloring

Assign colors to vertices so no two adjacent vertices share a color.

**Chromatic number χ(G):** Minimum colors needed.

**Application:**
- **Register allocation:** Variables are vertices; edges between variables used at same time; colors = CPU registers. Minimize registers used.
- **Map coloring:** Regions are vertices; shared borders are edges. Famous result: 4 colors always suffice for any map (Four Color Theorem).
- **Scheduling:** Tasks are vertices; conflicts are edges; colors = time slots.

---

## Part 6 — Directed Graphs and DAGs

### Topological Sort

A **topological ordering** of a DAG (directed acyclic graph) is a linear ordering of vertices such that for every edge u → v, u comes before v.

**Application:** Task scheduling, build systems (Makefile), course prerequisites, package dependency resolution.

**Algorithm (Kahn's algorithm):**
```python
from collections import deque

def topological_sort(graph, in_degree):
    queue = deque([v for v in graph if in_degree[v] == 0])
    result = []

    while queue:
        u = queue.popleft()
        result.append(u)
        for v in graph[u]:
            in_degree[v] -= 1
            if in_degree[v] == 0:
                queue.append(v)

    return result if len(result) == len(graph) else []  # [] = cycle detected
```

**Time:** O(V + E)

### Cycle Detection

**Undirected graph:** DFS — if we visit an already-visited node that isn't the parent, there's a cycle.

**Directed graph:** DFS with coloring — WHITE (unvisited), GRAY (in progress), BLACK (done). A GRAY node being visited again means a cycle.

---

## Practice Problems

**Basic Graph Theory:**

1. A graph has 7 vertices with degrees 1, 2, 2, 3, 3, 4, 5. Is this possible? How many edges does it have?

2. Prove that in any graph, the number of vertices with odd degree is even.

3. Draw K₄ and K₃,₃. How many edges does each have?

4. Is the Petersen graph bipartite? (Look it up — it's a famous graph.)

**Traversals:**

5. Given the graph: edges {(1,2),(1,3),(2,4),(2,5),(3,5),(4,6),(5,6)}, find:
   a) BFS order starting from vertex 1
   b) DFS order starting from vertex 1

6. What is the shortest path from vertex 1 to vertex 6 in the above graph?

**Paths and Connectivity:**

7. Determine if an Euler circuit exists in each graph:
   a) K₄
   b) K₅
   c) A cycle graph C₆

8. The floor plan of a museum: rooms connected by doorways. Is it possible to design a tour that passes through every doorway exactly once and returns to start? What must be true?

**Trees and Spanning Trees:**

9. Find the MST of the graph:
   A-B: 4, A-C: 2, B-C: 5, B-D: 10, C-D: 3, C-E: 8, D-E: 7

10. How many spanning trees does K₃ have?

**Algorithms:**

11. Find the shortest distances from vertex A using Dijkstra's:
    A-B: 4, A-C: 1, C-B: 2, B-D: 5, C-D: 8

12. Is this DAG valid for topological sort?
    Edges: {A→B, A→C, B→D, C→D, D→E}
    Give a valid topological ordering.

---

## Answers to Selected Problems

**Problem 1:**
```
Sum of degrees = 1+2+2+3+3+4+5 = 20
|E| = 20/2 = 10 edges
Maximum degree is 5 with 7 vertices (can connect to 6 others) — OK.
This graph is possible.
```

**Problem 7:**
```
a) K₄: all degrees = 3 (odd). 4 odd-degree vertices → NO Euler circuit, NO Euler path (need exactly 2 odd).
b) K₅: all degrees = 4 (even). All even → Euler circuit EXISTS ✓
c) C₆: all degrees = 2 (even). All even → Euler circuit EXISTS ✓
```

**Problem 9 (Kruskal's):**
```
Sort edges: A-C:2, C-D:3, A-B:4, B-C:5, D-E:7, C-E:8, B-D:10
Add A-C (2) ✓
Add C-D (3) ✓
Add A-B (4) ✓
Add B-C (5) ✗ (creates cycle A-B-C-A)
Add D-E (7) ✓
MST: {A-C, C-D, A-B, D-E} weight = 2+3+4+7 = 16
```

**Problem 11 (Dijkstra):**
```
Start: A=0, B=∞, C=∞, D=∞
Process A: B=4, C=1
Process C (dist=1): B=min(4,1+2)=3, D=min(∞,1+8)=9
Process B (dist=3): D=min(9,3+5)=8
Process D (dist=8): done
Distances: A=0, B=3, C=1, D=8
```

**Problem 12:**
```
Valid topological orderings include:
A, B, C, D, E  or  A, C, B, D, E
```

---

## References

- Rosen, K.H. — *Discrete Mathematics and Its Applications* — Chapter 10
- Cormen et al. — *Introduction to Algorithms* — Chapters 22-25
- MIT 6.042J — [Graph Theory lectures](https://ocw.mit.edu/courses/6-042j-mathematics-for-computer-science-fall-2010/)
- Visualgo.net — [Interactive graph algorithm visualizations](https://visualgo.net/en/graphds)
