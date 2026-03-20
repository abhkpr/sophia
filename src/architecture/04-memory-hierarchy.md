# Memory Hierarchy

## Why We Need a Memory Hierarchy

There is a fundamental tension in computer design: **fast memory is expensive and small; cheap memory is large and slow**. A CPU running at 3 GHz needs data every nanosecond. DRAM (main RAM) takes 60-100 nanoseconds to respond — 60-100 cycles of the CPU sitting idle, waiting.

**Real-world analogy:** Think about how a chef organizes a kitchen.

- **Hands / cutting board** — tiny, instant access. Holds only a few ingredients (registers).
- **Counter top** — small, very fast to grab. Holds what you're actively cooking (L1 cache).
- **Refrigerator** — medium, takes a few seconds. Holds today's ingredients (L2/L3 cache).
- **Pantry** — large, takes longer. Holds weekly stock (RAM).
- **Grocery store** — huge, far away, takes 20 minutes to go and return (disk/SSD).

A smart chef keeps frequently used ingredients on the counter. They don't walk to the grocery store for every pinch of salt. Computers do the same — cache stores recently used data close to the CPU.

---

## Part 1 — The Memory Hierarchy

```
                    Size       Speed        Cost/GB
┌──────────┐
│Registers │  < 1 KB    0.25 ns     $$$$$$$
└────┬─────┘
     │
┌────┴─────┐
│  L1 Cache│  32-64 KB  0.5-1 ns    $$$$$
└────┬─────┘
     │
┌────┴─────┐
│  L2 Cache│  256KB-1MB  3-5 ns     $$$$
└────┬─────┘
     │
┌────┴─────┐
│  L3 Cache│  8-64 MB   10-30 ns    $$$
└────┬─────┘
     │
┌────┴─────┐
│   DRAM   │  4-128 GB  60-100 ns   $
└────┬─────┘
     │
┌────┴─────┐
│ SSD/NVMe │  0.5-4 TB  50-100 µs   ¢¢¢
└────┬─────┘
     │
┌────┴─────┐
│   HDD    │  1-20 TB   5-10 ms     ¢¢
└──────────┘
```

**Numbers to remember:**
```
L1 cache hit:   ~4 cycles     (1 ns)
L2 cache hit:   ~12 cycles    (3 ns)
L3 cache hit:   ~40 cycles    (10 ns)
RAM access:     ~200 cycles   (60 ns)
SSD read:       ~100,000 cycles (30 µs)
HDD read:       ~20,000,000 cycles (6 ms)

Relative to a 1-second L1 hit:
RAM ≈ 3 minutes
SSD ≈ 2.5 days
HDD ≈ 6 months
```

---

## Part 2 — Locality of Reference

Why does caching work? Because programs exhibit **locality** — they tend to reuse data.

### Temporal Locality

Data accessed recently is likely to be accessed again soon.

```cpp
// Loop variable i accessed millions of times
for (int i = 0; i < 1000000; i++) {
    sum += arr[i];   // i, sum accessed every iteration
}
// i and sum have extreme temporal locality
```

**Real-world analogy:** You check your phone repeatedly throughout the day. You don't throw it across the room after each use because you know you'll need it again soon.

### Spatial Locality

Data near recently accessed data is likely to be accessed soon.

```cpp
// arr[0], arr[1], arr[2]... accessed sequentially
for (int i = 0; i < n; i++) {
    sum += arr[i];   // arr[i+1] is adjacent in memory
}
// When arr[0] is loaded, arr[1]-arr[15] come with it (cache line)
```

**Real-world analogy:** When you open a book to page 47, you'll probably read page 48 next. A library that pre-loads the next few pages when you open one is exploiting spatial locality.

### Why Locality Makes Caching Effective

```
Without locality: cache miss on every access → cache useless
With locality:
  First access: cache miss (load from RAM)
  Next 15 accesses: cache hits (neighbors already loaded)
  Hit rate ≈ 15/16 = 93.75%

Real programs achieve 95-99% cache hit rates!
```

---

## Part 3 — Cache Organization

### Cache Lines

Memory is transferred in fixed-size chunks called **cache lines** (typically 64 bytes = 16 integers).

```
Main memory:
Address: 0    4    8   12   16   20   24   28   32 ...
Value:   [10] [20] [30] [40] [50] [60] [70] [80] ...
         └────────────────────────────────────────┘
                      64-byte cache line

When CPU accesses address 8 (arr[2]):
  Entire 64-byte line loaded: addresses 0-63
  Now arr[0] through arr[15] are ALL in cache
  Next 15 accesses = 0 extra memory traffic
```

### Direct-Mapped Cache

Each memory block maps to exactly one cache line.

```
Cache with 8 lines, 64-byte lines:

Memory address bits: [Tag | Index | Offset]
                         ↑      ↑        ↑
                    upper bits  which   byte within
                               cache   cache line
                               line    (6 bits for 64B)

Index = (address / 64) % 8   (which cache slot to use)
Tag   = (address / 64) / 8   (which memory block is stored here)
Offset = address % 64         (which byte within the line)

Memory:   Cache line 0: addresses 0-63
          Cache line 8: addresses 512-575     both map to slot 0!
          Cache line 16: addresses 1024-1087  conflict!

Cache:
Slot 0: [Valid][Tag] [64 bytes of data]
Slot 1: [Valid][Tag] [64 bytes of data]
...
Slot 7: [Valid][Tag] [64 bytes of data]

Problem: if you alternate between two addresses that map to the same slot:
  arr1[0] at address 0    → loads into slot 0
  arr2[0] at address 512  → loads into slot 0 (evicts arr1!)
  arr1[0] again           → cache miss! (evicted)
  arr2[0] again           → cache miss! (evicted again)
  "Cache thrashing" — 0% hit rate despite small data!
```

### Set-Associative Cache

Each memory block can go in any of N ways within a set. Reduces thrashing.

```
4-way set-associative cache:

Address bits: [Tag | Set Index | Offset]

Each set has 4 "ways" — 4 possible slots
Memory block can go in ANY of the 4 ways in its set

Set 0: [Way0][Way1][Way2][Way3]
Set 1: [Way0][Way1][Way2][Way3]
...

Now 4 different memory blocks can coexist in set 0
(addresses 0, 512, 1024, 1536 can all be cached simultaneously)

Comparison:
  1-way (direct-mapped): fast lookup, high conflict misses
  N-way (fully assoc):   no conflict misses, slow lookup (check all N)
  4 or 8-way:            good balance (used in real CPUs)
```

### Cache Lookup Process

```
1. Extract index bits from address → find the set
2. Check all ways in that set for matching tag
3. If tag matches AND valid bit set → CACHE HIT, return data
4. Else → CACHE MISS

On miss:
  - Fetch line from next level (L2 or RAM)
  - Choose a way to evict (LRU policy)
  - Store new line in that way
  - Return data to CPU
```

### Cache Write Policies

**Write-through:** Write to both cache and memory simultaneously.
```
Pros: memory always up-to-date, simple
Cons: every write goes to slow memory
Used in: L1 cache in some designs
```

**Write-back:** Write only to cache; write to memory when line is evicted.
```
Pros: multiple writes to same line → only one memory write
Cons: memory may have stale data (need "dirty bit" per line)
Used in: L2, L3 caches; most L1 caches today

Dirty bit: set when line is modified, must write back on eviction

Timeline:
  Write arr[0] = 5:  update cache line, set dirty bit
  Write arr[0] = 7:  update cache line (no memory access!)
  Write arr[1] = 3:  update same cache line
  ... 14 more writes to same line ...
  Line evicted:      ONE write to memory (64 bytes)
  Savings: 16 individual writes → 1 memory write
```

**Write-allocate vs No-write-allocate:**
```
Write-allocate (with write-back):
  On write miss: load the line into cache, then write
  Rationale: likely to write again soon (temporal locality)

No-write-allocate (with write-through):
  On write miss: write directly to next level, don't load
  Used when: streaming writes (no reuse expected)
```

---

## Part 4 — Cache Misses: The 3 Cs

**Compulsory Miss (Cold miss):** First access to any data always misses.
```
int arr[1000];
arr[0] = 1;   // compulsory miss — first access ever
arr[1] = 2;   // hit! (loaded with arr[0]'s cache line)
```

**Capacity Miss:** Cache too small to hold all needed data.
```
// L1 cache = 32KB, array = 1MB
for (int i = 0; i < n; i++)   // n = 250,000 ints = 1MB
    sum += arr[i];
// When arr[8000] is accessed, arr[0..7999] evicted (not enough room)
// Second pass: all misses again
```

**Conflict Miss:** Two addresses compete for same cache slot (direct-mapped only).
```
// Power-of-2 stride with direct-mapped cache
for (int i = 0; i < n; i += 512)  // stride = 512 = cache size
    sum += arr[i];
// Every access maps to same cache slot → all misses
// Solution: use set-associative cache, or pad arrays
```

---

## Part 5 — Writing Cache-Friendly Code

Understanding the hardware lets you write dramatically faster code.

### Row-Major vs Column-Major Traversal

```cpp
// Matrix stored row-major in C++:
// matrix[0][0], matrix[0][1], ..., matrix[0][n-1],
// matrix[1][0], matrix[1][1], ...
// Adjacent elements in same row are adjacent in memory

const int N = 1024;
int matrix[N][N];

// Cache-FRIENDLY: row-major traversal
// Accesses adjacent memory → spatial locality
for (int i = 0; i < N; i++)
    for (int j = 0; j < N; j++)
        sum += matrix[i][j];  // matrix[i][j+1] already in cache line

// Cache-UNFRIENDLY: column-major traversal
// Jumps N*4 = 4096 bytes between accesses → every access is a cache miss!
for (int j = 0; j < N; j++)
    for (int i = 0; i < N; i++)
        sum += matrix[i][j];  // matrix[i+1][j] is 4096 bytes away

// Performance difference: 5-10x on large matrices!
```

**Visualization:**
```
Row-major (good):
  [0,0][0,1][0,2][0,3]  ← all in one cache line, accessed left-to-right
  ────────────────────
  Cache line

Column-major (bad):
  [0,0]          ← cache miss, loads row 0
        [1,0]    ← cache miss, loads row 1 (4096 bytes away!)
             [2,0] ← cache miss, loads row 2
```

### Cache Blocking (Tiling)

Process data in blocks that fit in cache.

```cpp
// Matrix multiplication — naive (cache-unfriendly for B access)
for (int i = 0; i < N; i++)
    for (int j = 0; j < N; j++)
        for (int k = 0; k < N; k++)
            C[i][j] += A[i][k] * B[k][j];  // B accessed column-wise: BAD

// Cache-blocked version (tile size B=64 fits in L1 cache)
const int B = 64;
for (int ii = 0; ii < N; ii += B)
    for (int jj = 0; jj < N; jj += B)
        for (int kk = 0; kk < N; kk += B)
            // process B×B tile — fits in cache!
            for (int i = ii; i < min(ii+B, N); i++)
                for (int j = jj; j < min(jj+B, N); j++)
                    for (int k = kk; k < min(kk+B, N); k++)
                        C[i][j] += A[i][k] * B[k][j];

// Speedup: 2-10x for large matrices
// Why: entire B×B tile stays in cache during inner loops
```

### False Sharing (Multicore)

```cpp
// Bad: two threads write to adjacent variables on SAME cache line
struct Data {
    int counter1;  // offset 0
    int counter2;  // offset 4 — same 64-byte cache line!
};

// Thread 1 increments counter1
// Thread 2 increments counter2
// They're on the SAME cache line!
// Every write by one thread invalidates the other's cache copy
// Cache line ping-pongs between cores → severe slowdown

// Fix: pad to separate cache lines
struct Data {
    int counter1;
    char padding[60];  // force counter2 to next cache line
    int counter2;
};
// Or use alignas(64):
struct alignas(64) Counter { int value; };
Counter c1, c2;  // guaranteed separate cache lines
```

---

## Part 6 — Memory Types

### SRAM (Static RAM) — Used for Caches

```
Structure: 6 transistors per bit (bistable flip-flop)
Speed: 0.5-5 ns
Size: small (expensive per bit)
Power: low static power, high dynamic
Retention: holds data as long as powered (no refresh needed)
Usage: CPU caches (L1, L2, L3)
```

### DRAM (Dynamic RAM) — Used for Main Memory

```
Structure: 1 transistor + 1 capacitor per bit
Speed: 50-100 ns
Size: large (cheap per bit, 6-10x denser than SRAM)
Power: needs periodic refresh (capacitor leaks every 64ms)
Usage: main memory (DDR4, DDR5, LPDDR)

DDR4 specs:
  Bandwidth: 25-50 GB/s
  Latency: 13-17 ns (CL = 16-20 cycles at 1600 MHz)
  Capacity: 8-64 GB per module

Why "Dynamic"? The capacitor slowly discharges (leaks).
Must be refreshed (re-charged) every 64 milliseconds.
During refresh: memory is unavailable (few cycles penalty).
```

### Modern Memory: DDR4 vs DDR5

```
          DDR4          DDR5
Speed:    2133-3200MHz  4800-8400MHz
Bandwidth: 25-51 GB/s   38-67 GB/s
Voltage:  1.2V          1.1V
ECC:      optional      optional (on-die ECC standard)
Channels: 1 per module  2 per module
```

---

## Practice Problems

1. A cache has 16KB capacity, 64-byte lines, 4-way set-associative. How many sets are there?

2. For the following code, identify the cache behavior:
   ```cpp
   for (int i = 0; i < 100; i++)
       for (int j = 0; j < 100; j++)
           total += grid[j][i];
   ```

3. A program has 10^8 memory accesses with 95% L1 hit rate, 80% of misses hit L2. L1 hit = 1 cycle, L2 hit = 10 cycles, RAM = 100 cycles. Calculate average memory access time (AMAT).

4. Why is a 2-way set-associative cache better than direct-mapped for this access pattern?
   ```cpp
   for (int i = 0; i < n; i++)
       result += A[i] + B[i];  // A and B both 8KB, cache = 8KB direct-mapped
   ```

---

## Answers

**Problem 1:**
```
Total lines = 16384 / 64 = 256 lines
Sets = 256 / 4 = 64 sets
Index bits = log2(64) = 6 bits
Offset bits = log2(64) = 6 bits
Tag bits = 32 - 6 - 6 = 20 bits
```

**Problem 2:**
```
Column-major traversal on row-major stored array.
grid[j][i] accesses elements in column order.
Between grid[0][i] and grid[1][i]: stride = 100*4 = 400 bytes.
Since 400 > 64 (cache line size), every access is a cache miss.
This code has very poor spatial locality.
Fix: swap i and j loop order.
```

**Problem 3:**
```
AMAT = L1 hit time + L1 miss rate × (L2 hit time + L2 miss rate × RAM time)
     = 1 + 0.05 × (10 + 0.20 × 100)
     = 1 + 0.05 × (10 + 20)
     = 1 + 0.05 × 30
     = 1 + 1.5
     = 2.5 cycles average
```

**Problem 4:**
```
A[0] and B[0] both map to same direct-mapped slot (both at relative offset 0 in 8KB cache).
Every access to A evicts B's line, every access to B evicts A's line.
Result: 0% hit rate despite total data = cache size.

With 2-way set-associative:
A[0] → way 0, slot 0
B[0] → way 1, slot 0 (different way, same set)
Both coexist! Hit rate ≈ 93.75% (after warmup).
```

---

## References

- Patterson & Hennessy — *Computer Organization and Design* — Chapter 5
- Ulrich Drepper — *What Every Programmer Should Know About Memory* (free PDF)
- CMU 15-213 — [Cache Lab](https://csapp.cs.cmu.edu/3e/labs.html)
- CPU cache simulator — [cs.usfca.edu/~galles/visualization](https://www.cs.usfca.edu/~galles/visualization/)
