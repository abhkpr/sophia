# Parallelism and Modern CPUs

## Beyond a Single Core

For decades, CPUs got faster by increasing clock speed. In 2004, this hit a wall — power consumption and heat made further increases impractical. The industry's response: put multiple cores on one chip. Now performance comes from parallelism, not speed.

**Real-world analogy:** Building a house. One extremely fast carpenter can only work so fast — eventually, no matter how skilled, physics limits how many nails per second they can drive. The solution: hire more carpenters. With 8 carpenters working on different rooms simultaneously, the house gets built much faster. But coordination becomes the new challenge — two carpenters trying to install the same door at the same time creates chaos.

---

## Part 1 — Types of Parallelism

### ILP — Instruction-Level Parallelism

Execute multiple instructions simultaneously from a single thread. Done automatically by the CPU (superscalar, OOO execution).

```cpp
// These two operations are independent:
int a = b + c;   // ADD
int d = e * f;   // MUL (independent of ADD)

// CPU executes both simultaneously
// Programmer doesn't need to do anything
```

**Limits of ILP:**
```
Average IPC on real programs: 2-4 (despite 6+ execution ports)
Why limited?
  - Data dependencies (true, WAR, WAW hazards)
  - Control dependencies (branches limit lookahead)
  - Memory latency (cache misses stall the pipeline)
  - Limited instruction window (~200-500 instructions visible)
```

### DLP — Data-Level Parallelism (SIMD)

Apply the same operation to multiple data elements simultaneously.

```cpp
// Scalar: process one element at a time
for (int i = 0; i < n; i++)
    c[i] = a[i] + b[i];  // 1 add per iteration

// SIMD (SSE2): process 4 integers at a time
#include <immintrin.h>

// Load 4 ints from a, 4 from b, add, store to c
for (int i = 0; i < n; i += 4) {
    __m128i va = _mm_load_si128((__m128i*)&a[i]);  // load 4 ints
    __m128i vb = _mm_load_si128((__m128i*)&b[i]);  // load 4 ints
    __m128i vc = _mm_add_epi32(va, vb);            // 4 adds at once
    _mm_store_si128((__m128i*)&c[i], vc);          // store 4 ints
}
// 4× throughput!

// AVX2: process 8 integers at a time (256-bit)
// AVX-512: process 16 integers at a time (512-bit)
```

**Real-world SIMD example — image processing:**
```cpp
// Brighten every pixel by 10 (all pixels are independent)
// Without SIMD: 1 addition per pixel, 1920×1080 = 2M additions
// With AVX2:    8 additions per instruction, 2M/8 = 250K instructions
// 8× speedup!

// Auto-vectorization: modern compilers often do this automatically
// with -O2 or -O3 flag
```

### TLP — Thread-Level Parallelism

Multiple threads executing simultaneously on multiple cores.

```cpp
#include <thread>

// Split work across multiple threads
void sumPart(int* arr, int start, int end, long long* result) {
    *result = 0;
    for (int i = start; i < end; i++)
        *result += arr[i];
}

int main() {
    const int N = 10000000;
    int arr[N];
    long long sum1 = 0, sum2 = 0;

    // Two threads process half each
    thread t1(sumPart, arr, 0, N/2, &sum1);
    thread t2(sumPart, arr, N/2, N, &sum2);
    t1.join();
    t2.join();

    long long total = sum1 + sum2;  // 2× speedup on 2 cores
}
```

---

## Part 2 — Multicore Architecture

### Cache Hierarchy in Multicore

```
Core 0              Core 1              Core 2              Core 3
┌──────────┐        ┌──────────┐        ┌──────────┐        ┌──────────┐
│ L1I (32K)│        │ L1I (32K)│        │ L1I (32K)│        │ L1I (32K)│
│ L1D (32K)│        │ L1D (32K)│        │ L1D (32K)│        │ L1D (32K)│
│ L2 (256K)│        │ L2 (256K)│        │ L2 (256K)│        │ L2 (256K)│
└────┬─────┘        └────┬─────┘        └────┬─────┘        └────┬─────┘
     └────────────────────┴────────────────────┴────────────────────┘
                                    │
                         ┌──────────────────────┐
                         │    L3 Cache (shared)  │
                         │        (e.g., 32MB)   │
                         └──────────────────────┘
                                    │
                         ┌──────────────────────┐
                         │        DRAM           │
                         └──────────────────────┘
```

### Cache Coherence

Multiple cores can each have their own cached copy of the same data. If one core modifies its copy, the other copies become **stale** — an inconsistency.

**The Problem:**
```
Core 0 loads x=5 into L1 cache
Core 1 loads x=5 into L1 cache
Core 0 writes x=10 → updates its L1 cache
Core 1 reads x → gets 5 from its cache (STALE!)

Without coherence: cores see different values for the same variable
```

**MESI Protocol:** Each cache line in one of 4 states:

```
M (Modified):
  - Only in this cache, has been written
  - Different from memory (dirty)
  - Must write back before another core can access

E (Exclusive):
  - Only in this cache, not written
  - Same as memory (clean)
  - Can write without notifying others

S (Shared):
  - May be in multiple caches
  - Same as memory (clean)
  - Must notify others before writing (transition to M)

I (Invalid):
  - Data is stale or not present
  - Must fetch from another cache or memory

State transitions:
  CPU write to E line → M (silent, no bus traffic)
  CPU write to S line → M + broadcast Invalidate to other caches
  Another CPU writes our S line → we get Invalidate → I
  CPU reads I line → Fetch from memory or another cache's M line
```

**Visualization:**
```
Core 0 reads x:       Core 0 L1: x=5 (E)    Core 1 L1: I
Core 1 reads x:       Core 0 L1: x=5 (S)    Core 1 L1: x=5 (S)
Core 0 writes x=10:   Core 0 L1: x=10 (M)   Core 1 L1: I (invalidated!)
Core 1 reads x:       Core 0 L1: x=10 (S)   Core 1 L1: x=10 (S)
                      (Core 0 sent x=10 to Core 1)
```

**Performance implication: false sharing**
```cpp
// Two threads write to different variables in same cache line
int arr[16];  // arr[0] and arr[1] are in same 64-byte cache line

thread 1: arr[0]++   // modifies cache line → MESI state: M
thread 2: arr[1]++   // other core needs the line → cache line ping-pongs!
                     // Core1 gets Invalidate, fetches line, writes
                     // Core2 gets Invalidate, fetches line, writes
                     // Back and forth: massive overhead!

// Fix: pad to separate cache lines
alignas(64) int val1;
alignas(64) int val2;  // now on separate cache lines
```

---

## Part 3 — Memory Consistency Models

How strictly is the ordering of memory operations enforced across cores?

### Sequential Consistency (SC)

Strongest model. Result of any execution is as if all operations of all processors were in some sequential order, and each individual processor's operations appear in this order.

```
Thread 1:  x = 1;  a = y;
Thread 2:  y = 1;  b = x;

With SC, possible outcomes for (a, b): (0,1), (1,0), (1,1)
Impossible outcome: (0, 0)  — would mean neither write was visible

SC is intuitive but too expensive to implement efficiently.
```

### x86 TSO (Total Store Order)

Weaker than SC. Writes go into a store buffer before reaching memory.

```
Core 0:  x = 1;  a = y;   // write x, read y
Core 1:  y = 1;  b = x;   // write y, read x

Store buffer: each core has a buffer where writes wait before memory

Core 0 writes x=1 → store buffer (not yet visible to Core 1!)
Core 0 reads y    → gets 0 (Core 1's write not visible yet)
Core 1 writes y=1 → store buffer
Core 1 reads x    → gets 0 (Core 0's write not visible yet)
Both store buffers drain to memory

Result (a=0, b=0) IS POSSIBLE on x86!
This cannot happen under SC.

TSO allows: reads can bypass older writes in the store buffer
           (read your own uncommitted writes, but not other cores')
```

### ARM / RISC-V Relaxed Memory

Even weaker. Reads and writes can be reordered arbitrarily.

```cpp
// In relaxed models, all four outcomes possible:
// (a=0,b=0), (a=0,b=1), (a=1,b=0), (a=1,b=1)

// Must use memory fences/barriers to enforce ordering:
// RISC-V: FENCE instruction
// ARM:    DMB (Data Memory Barrier)
// x86:    MFENCE, SFENCE, LFENCE
```

### C++ Memory Order

```cpp
#include <atomic>

atomic<int> x(0), y(0);
int a, b;

// Sequential consistency (default, safest):
x.store(1, memory_order_seq_cst);
a = y.load(memory_order_seq_cst);

// Relaxed (fastest, no ordering guarantees):
x.store(1, memory_order_relaxed);   // only atomicity guaranteed
a = y.load(memory_order_relaxed);   // might see stale values

// Acquire-release (common synchronization pattern):
// Store with release: all previous writes visible before this store
x.store(1, memory_order_release);
// Load with acquire: all subsequent reads happen after this load
a = y.load(memory_order_acquire);
// Together: ensures happens-before relationship
```

---

## Part 4 — Synchronization Primitives

### Mutex (Mutual Exclusion)

```cpp
#include <mutex>
mutex mtx;
int shared_counter = 0;

void increment() {
    for (int i = 0; i < 100000; i++) {
        mtx.lock();
        shared_counter++;   // critical section
        mtx.unlock();
    }
}

// Or RAII style:
void increment_safe() {
    lock_guard<mutex> lock(mtx);  // auto-unlocks on scope exit
    shared_counter++;
}
```

**How mutex works in hardware:**
```
Test-and-Set (atomic):
  atomically: read old value, write 1, return old value

Lock:
  while (test_and_set(&lock) == 1) {}   // spin until 0 (unlocked)
  // critical section
  lock = 0;                              // release

Problem: spinning wastes CPU cycles
Better: put thread to sleep if lock unavailable (OS scheduler)
```

### Spinlock vs Mutex

```
Spinlock: thread loops (spins) until lock available
  Pros: no context switch overhead, fast for short critical sections
  Cons: wastes CPU, bad if lock held for long
  Use: kernel code, interrupt handlers, very short critical sections

Mutex: thread put to sleep by OS if lock unavailable
  Pros: no wasted CPU while waiting
  Cons: context switch overhead (~1000 cycles)
  Use: application code, longer critical sections
```

### Condition Variables

```cpp
mutex mtx;
condition_variable cv;
queue<int> work_queue;

// Producer:
void produce(int item) {
    lock_guard<mutex> lock(mtx);
    work_queue.push(item);
    cv.notify_one();  // wake up a waiting consumer
}

// Consumer:
void consume() {
    unique_lock<mutex> lock(mtx);
    cv.wait(lock, []{ return !work_queue.empty(); });
    // wakes up when notified AND condition is true
    int item = work_queue.front();
    work_queue.pop();
    process(item);
}
```

---

## Part 5 — GPU Architecture

GPUs are massively parallel processors designed for data-parallel computation.

```
CPU:                          GPU:
  4-16 large cores               Thousands of small cores
  Optimized for low latency      Optimized for high throughput
  Complex branch prediction      Simple in-order execution
  Large caches per core          Small caches, large register file
  Fast for serial code           Fast for parallel code

GPU (NVIDIA A100):
  6912 CUDA cores
  Peak: 19.5 TFLOPS (single precision)
  Memory: 80GB HBM2e at 2TB/s bandwidth

CPU (Intel i9):
  16 cores
  Peak: ~1 TFLOPS (with AVX-512)
  Memory: 64GB DDR5 at 100GB/s
```

### GPU Execution Model (CUDA)

```
// CUDA kernel — runs on GPU
__global__ void addVectors(float* a, float* b, float* c, int n) {
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i < n) c[i] = a[i] + b[i];
}

// CPU launches 1M threads:
int blockSize = 256;
int numBlocks = (n + blockSize - 1) / blockSize;
addVectors<<<numBlocks, blockSize>>>(d_a, d_b, d_c, n);
// 1 million elements processed in parallel!

GPU hardware grouping:
  Warp: 32 threads executed in SIMD lockstep
  Block: group of warps (max 1024 threads)
  Grid: group of blocks

  All threads in a warp execute same instruction simultaneously
  Branch divergence: if threads in a warp take different branches,
  both paths execute (some threads masked) → wastes execution units
```

---

## Part 6 — Amdahl's Law and Parallel Speedup

```
Amdahl's Law:
Speedup = 1 / (S + P/N)

S = serial fraction (can't be parallelized)
P = parallel fraction (S + P = 1)
N = number of processors

Example: 95% parallelizable code, 10 cores:
Speedup = 1 / (0.05 + 0.95/10) = 1 / (0.05 + 0.095) = 1/0.145 ≈ 6.9×

With 100 cores:
Speedup = 1 / (0.05 + 0.95/100) = 1 / (0.05 + 0.0095) ≈ 16.8×

With infinite cores:
Speedup = 1 / 0.05 = 20× (maximum possible!)

Implication: even 5% serial code limits max speedup to 20×
The serial portion is the bottleneck — optimize it first!
```

**Gustafson's Law (counter-argument):**
```
As more cores available, programmers solve BIGGER problems.
With N cores, run a problem N times larger in same time.
"Scaled speedup" = N - S(N-1)

If S=0.05: Scaled speedup = 10 - 0.05(9) = 9.55 with 10 cores
More optimistic: problem size scales with resources
```

---

## Practice Problems

1. A program has 20% serial code. What is the maximum speedup with unlimited cores?

2. Two threads share a 64-byte cache line. Thread 1 modifies the first 4 bytes and Thread 2 modifies bytes 32-35. Why is this slow? How do you fix it?

3. In MESI protocol, if Core 0 has a line in M state and Core 1 tries to read it, what happens?

4. Why can't you simply add more and more cores to get linear speedup in practice?

---

## Answers

**Problem 1:**
```
Amdahl's Law with S=0.20, N=∞:
Speedup = 1 / (0.20 + 0/∞) = 1/0.20 = 5×
Maximum speedup is 5×, regardless of how many cores.
```

**Problem 2:**
```
False sharing: both writes modify the same cache line.
MESI protocol invalidates the other core's copy on every write.
The cache line "ping-pongs" between cores → massive overhead.

Fix: pad data to separate cache lines:
struct { int val; char pad[60]; } thread1_data;
struct { int val; char pad[60]; } thread2_data;
// Now each is on its own 64-byte cache line, no sharing.
```

**Problem 3:**
```
1. Core 1 sends a Read request on the bus
2. Core 0 sees the request, transitions M → S
3. Core 0 writes its dirty data to memory (write-back)
   OR directly forwards to Core 1 (faster: "cache-to-cache transfer")
4. Core 1 receives the data, transitions I → S
5. Both cores now have the line in S state
6. Memory is now up-to-date (M → S transition requires write-back)
```

**Problem 4:**
```
Several fundamental limits:
1. Amdahl's Law: serial portions limit speedup regardless of cores
2. Memory bandwidth: more cores → more pressure on shared memory bus
3. Cache coherence overhead: more cores → more MESI messages
4. Synchronization: locks become contention points
5. OS scheduling: hard to keep all cores busy with useful work
6. Power: more active cores = more heat, throttling kicks in
```

---

## References

- Hennessy & Patterson — *Computer Architecture: A Quantitative Approach* — Chapters 4-5
- Patterson & Hennessy — *Computer Organization and Design* — Chapter 6
- Herlihy & Shavit — *The Art of Multiprocessor Programming*
- CUDA Programming Guide — [docs.nvidia.com/cuda](https://docs.nvidia.com/cuda/cuda-c-programming-guide/)
- Memory Models — [preshing.com](https://preshing.com/20120625/memory-ordering-at-compile-time/)
