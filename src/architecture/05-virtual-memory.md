# Virtual Memory

## The Illusion of Infinite, Private Memory

Every process on your computer believes it has the entire address space to itself. Your browser thinks it owns addresses 0 to 2^64. Your code editor thinks the same. They're both wrong — but the illusion is perfect, and it's one of the most elegant ideas in systems design.

**Real-world analogy:** Hotel room numbers. Your room is "204" — that's your virtual address. But physically, room 204 might be anywhere in the building. The hotel (OS + MMU) maps your room number to a physical location. Two hotels can both have a "Room 204" — no conflict, because they're in different physical locations. Processes work the same way.

---

## Part 1 — Why Virtual Memory?

### Problem 1 — Not Enough RAM

```
System has 8 GB RAM
Photoshop needs:     2 GB
Chrome needs:        3 GB
VS Code needs:       1 GB
Other processes:     1 GB
Total needed:        7 GB  (just fits)

But what about running more programs?
Virtual memory allows programs to use more memory than physically available
by storing some pages on disk (swap space).
```

### Problem 2 — Memory Protection

```
Without virtual memory:
  Process A stores password at address 0x1000
  Process B reads address 0x1000 → steals password!

With virtual memory:
  Process A's virtual address 0x1000 → Physical frame 42
  Process B's virtual address 0x1000 → Physical frame 99 (different!)
  
  Each process has its own completely separate virtual address space.
  Process B literally cannot access Process A's memory.
```

### Problem 3 — Fragmentation

```
Without virtual memory:
  RAM has 1GB free but in 1MB chunks scattered across memory
  A program needing 512MB contiguous memory can't run!

With virtual memory:
  Program sees 512MB of contiguous virtual addresses
  Physically, those pages are scattered throughout RAM
  The page table handles the non-contiguous mapping transparently
```

---

## Part 2 — Address Translation

### Pages and Frames

Memory is divided into fixed-size chunks:

```
Virtual memory → divided into pages (typically 4KB)
Physical memory → divided into frames (same size as pages)

Virtual Address Space (per process):     Physical Memory (shared):
┌─────────────┐                          ┌─────────────┐
│ Page 0      │ ────────────────────────►│ Frame 7     │
│ (4KB)       │                          │ (4KB)       │
├─────────────┤                          ├─────────────┤
│ Page 1      │ ──────────┐              │ Frame 0     │
│             │            │             ├─────────────┤
├─────────────┤            └────────────►│ Frame 12    │
│ Page 2      │  (on disk)               ├─────────────┤
│             │──  - - - - - - - - - -   │ Frame 3     │
├─────────────┤                          ├─────────────┤
│   ...       │                          │   ...       │
```

**Why 4KB pages?**
- Large enough: amortizes translation overhead
- Small enough: doesn't waste memory for small allocations
- Power of 2: efficient bit-manipulation for address splitting

### Virtual Address Structure

```
64-bit virtual address (x86-64 uses 48 bits effectively):

┌─────────┬─────────┬─────────┬─────────┬──────────────┐
│ PML4    │  PDPT   │   PD    │   PT    │    Offset    │
│ [47:39] │ [38:30] │ [29:21] │ [20:12] │   [11:0]     │
│  9 bits │  9 bits │  9 bits │  9 bits │   12 bits    │
└─────────┴─────────┴─────────┴─────────┴──────────────┘
  512      512       512       512        4096 bytes
  entries  entries   entries   entries    per page

4-level page table hierarchy!
Each level has 512 entries (2^9)
Total: 512^4 = 2^36 pages × 4KB = 256 TB addressable

12-bit offset: covers 2^12 = 4096 bytes within a page ✓
```

### Page Table Walk

```
Virtual address: 0x00007FF1A3B4C5D6

Break into parts:
  PML4 index:   bits [47:39] = 0x00F  (15)
  PDPT index:   bits [38:30] = 0x068  (104)
  PD index:     bits [29:21] = 0x11D  (285)
  PT index:     bits [20:12] = 0x1B4  (436)
  Page offset:  bits [11:0]  = 0x5D6  (1494)

Translation:
1. CR3 register → physical address of PML4 table
2. PML4[15]     → physical address of PDPT table
3. PDPT[104]    → physical address of PD table
4. PD[285]      → physical address of PT table
5. PT[436]      → physical frame number (PFN)
6. Physical address = PFN × 4096 + 0x5D6
```

### Page Table Entry (PTE)

```
64-bit PTE structure:
┌─────────────────────────────┬─────────────────────────────┐
│      Physical Frame Number  │          Flags               │
│         [51:12]             │          [11:0]              │
└─────────────────────────────┴─────────────────────────────┘

Key flags:
  P (Present):    1 = page in RAM, 0 = on disk (page fault on access)
  R/W:            0 = read-only, 1 = read-write
  U/S:            0 = kernel only, 1 = user accessible
  A (Accessed):   set by hardware when page is read
  D (Dirty):      set by hardware when page is written
  NX:             1 = no-execute (prevents code injection)
  G (Global):     don't flush from TLB on context switch (kernel pages)
```

---

## Part 3 — TLB (Translation Lookaside Buffer)

### The Problem: Translation is Slow

Without a TLB, every memory access requires 4 additional memory accesses (the page table walk). A 4-cycle operation becomes 5 × 60 ns = 300 ns. Unusable.

**Solution:** Cache recent translations in a tiny, fast hardware structure — the TLB.

### TLB Structure

```
TLB (fully associative, 64-1024 entries):
┌──────────┬─────────────────┬────────┐
│  VPN     │    PFN          │ Flags  │
│(virtual  │  (physical      │ PRWAD  │
│page num) │   frame num)    │       │
├──────────┼─────────────────┼────────┤
│ 0x7F1A3  │    0x0042F      │ 11110  │
│ 0x00001  │    0x00001      │ 11010  │
│ ...      │    ...          │ ...   │
└──────────┴─────────────────┴────────┘

Lookup: hash VPN, check for match (fully associative = check all entries)
Hit time: 1-2 cycles (same level as L1 cache)
```

### TLB Hit vs Miss

```
TLB Hit (>99% of accesses):
  Virtual address → TLB lookup (1-2 cycles) → Physical address → memory
  Fast! Like cache hit.

TLB Miss (<1% of accesses):
  Virtual address → TLB lookup MISS → Page table walk (4 memory accesses)
  Hardware page table walker (x86) or software handler (RISC-V)
  → Load PTE into TLB → retry memory access
  Cost: 200+ cycles

TLB Reach = TLB entries × page size
  64 entries × 4KB = 256KB
  If working set > 256KB: frequent TLB misses

Huge Pages (2MB or 1GB pages):
  64 entries × 2MB = 128MB reach
  Huge pages dramatically reduce TLB misses for large datasets
```

### Context Switch and TLB

```
When OS switches between processes:
  Old process: VPN 0x1000 → PFN 0x500
  New process: VPN 0x1000 → PFN 0x200  (completely different mapping!)

Options:
1. Flush entire TLB on context switch
   Cost: next process starts with 0 TLB entries → many misses
   
2. ASID (Address Space ID) tag each TLB entry
   TLB entry: [ASID | VPN | PFN | flags]
   Process A uses ASID=1, Process B uses ASID=2
   No flush needed — entries from different ASIDs coexist
   x86 calls this PCID (Process Context ID)
```

---

## Part 4 — Page Faults

When a page is not in RAM (P bit = 0 in PTE), a **page fault** occurs.

### Page Fault Handler

```
1. CPU detects P=0 in PTE → triggers page fault exception
2. Hardware saves CPU state (registers, PC, etc.)
3. OS page fault handler runs:
   a. Is this a valid virtual address? (In process's VMA)
      NO → Segmentation fault (SIGSEGV) → process killed
      YES → continue
   b. Find the page on disk (swap space or file)
   c. If RAM is full: evict a page (write dirty page to disk if needed)
   d. Load the needed page from disk into a free frame
   e. Update PTE: set P=1, set frame number
   f. Update TLB
   g. Resume faulting instruction (re-executes, now succeeds)

Total time: ~1-10 ms (disk access dominates)
vs. normal memory access: 60-100 ns
Page fault = 10,000-100,000× slower!
```

### Types of Page Faults

```
Minor (soft) fault: page exists in physical memory, just not mapped
  - Stack growth: just allocate a new frame, no disk I/O
  - Copy-on-write: just copy the frame, no disk I/O
  - Cost: ~1-10 µs

Major (hard) fault: page must be loaded from disk
  - First access to mmap'd file
  - Swapped-out page being accessed again
  - Cost: 1-10 ms
```

---

## Part 5 — Page Replacement Algorithms

When RAM is full and a page must be evicted, which page to choose?

### OPT (Optimal) — Theoretical Best

Evict the page that will be used furthest in the future.

```
Pages: A B C D A B E A B C D E
Frames: 3

Load A: [A _ _]  miss
Load B: [A B _]  miss
Load C: [A B C]  miss
Load D: [D B C]  miss  evict A (used furthest: position 4)
Load A: [D A C]  miss  evict B (used furthest: position 5)
Load B: [D A B]  miss  evict C (never used again!)
Load E: [E A B]  miss  evict D (never used again!)
Load A: [E A B]  HIT
...

OPT is optimal but requires knowing the future → impossible in practice
Used as a benchmark to compare other algorithms
```

### LRU (Least Recently Used)

Evict the page used longest ago. Approximates OPT well.

```
Pages: A B C D A B E A B C D E
Frames: 3

Load A: [A _ _]  miss
Load B: [A B _]  miss
Load C: [A B C]  miss
Load D: [D B C]  miss  evict A (LRU: longest ago)
Load A: [D A C]  miss  evict B
Load B: [D A B]  miss  evict C
Load E: [E A B]  miss  evict D (LRU)
Load A: [E A B]  HIT
Load B: [E A B]  HIT
Load C: [E C B]  miss  evict A
Load D: [E C D]  miss  evict B
Load E: [E C D]  HIT
Misses: 8

LRU is near-optimal but expensive to implement exactly in hardware.
```

**Approximate LRU — Clock Algorithm:**

```
Pages arranged in circle. "Clock hand" sweeps around.
Each page has a reference bit (R), set by hardware on access.

On page fault:
  While current page's R=1:
    Set R=0 (give second chance)
    Advance hand
  Evict current page (R=0, not used since last sweep)

This is the algorithm Linux actually uses!
```

### FIFO (First In, First Out)

Evict the oldest loaded page. Simple but poor performance.

```
Belady's Anomaly: adding more frames can cause MORE misses with FIFO!
(This anomaly does NOT occur with LRU or OPT)
```

### Comparison

```
Algorithm    Misses (example above)  Implementation
OPT          6                       Impossible (needs future)
LRU          8                       Expensive (stack or counter)
Clock        ~8-10                   O(1), used in practice
FIFO         12                      O(1) but poor performance
```

---

## Part 6 — Memory-Mapped Files

Files can be mapped directly into virtual address space — no explicit read/write calls needed.

```cpp
#include <sys/mman.h>

// Map a file into virtual memory
int fd = open("data.bin", O_RDONLY);
size_t fileSize = getFileSize(fd);

void* ptr = mmap(nullptr, fileSize, PROT_READ, MAP_PRIVATE, fd, 0);
// ptr now points to the file contents in virtual memory

// Access file like a regular array
int* data = (int*)ptr;
printf("%d\n", data[0]);    // reads first 4 bytes of file
printf("%d\n", data[1000]); // reads bytes 4000-4003

// OS uses demand paging: pages loaded only when accessed
// Perfect for large files — only accessed parts use RAM

// Unmap when done
munmap(ptr, fileSize);
close(fd);
```

**Advantages:**
```
1. Demand paging: only read parts actually accessed
2. OS caches pages — multiple processes can share the same physical pages
3. Simpler code: no read() loops, no buffer management
4. Can be faster than read() for random access patterns
```

---

## Part 7 — The Memory of a Process

```
Virtual address space layout (Linux x86-64):

0xFFFFFFFFFFFFFFFF ┌─────────────────┐
                   │   Kernel Space  │  Not accessible to user processes
0xFFFF800000000000 ├─────────────────┤
                   │                 │
                   │   (unmapped)    │
                   │                 │
0x00007FFFFFFFFFFF ├─────────────────┤
                   │     Stack       │  Grows downward
                   │       ↓        │
                   ├─────────────────┤
                   │       ↑        │
                   │  Memory Maps   │  mmap(), shared libs
                   ├─────────────────┤
                   │       ↑        │
                   │      Heap      │  malloc() grows upward
                   ├─────────────────┤
                   │   BSS segment  │  Uninitialized global variables
                   ├─────────────────┤
                   │  Data segment  │  Initialized global/static variables
                   ├─────────────────┤
                   │  Text segment  │  Executable code (read-only)
0x0000000000400000 └─────────────────┘
```

---

## Practice Problems

1. A system has 4KB pages and 32-bit virtual addresses. How many pages in the virtual address space?

2. A TLB has 64 entries with 4KB pages. What is the TLB reach? What percentage of a 1MB working set is covered?

3. Given reference string: 1 2 3 4 1 2 5 1 2 3 4 5 with 3 frames, calculate misses for FIFO and LRU.

4. Why does stack overflow cause a segfault (not just a page fault)?

---

## Answers

**Problem 1:**
```
Virtual address space = 2^32 = 4 GB
Page size = 4 KB = 2^12
Number of pages = 2^32 / 2^12 = 2^20 = 1,048,576 pages (1M pages)
```

**Problem 2:**
```
TLB reach = 64 entries × 4KB = 256 KB
1MB working set coverage = 256KB / 1024KB = 25%
Only 25% covered → many TLB misses for a 1MB working set.
Solution: use huge pages (2MB) → 64 × 2MB = 128MB reach
```

**Problem 3:**
```
Reference: 1 2 3 4 1 2 5 1 2 3 4 5  (3 frames)

FIFO:
1:[1_ _] M  2:[12 _] M  3:[123] M  4:[423] M  1:[413] M  2:[412] M
5:[512] M  1:[512] H  2:[512] H  3:[312] M  4:[314] M  5:[514] M
FIFO misses: 9

LRU:
1:[1_ _] M  2:[12 _] M  3:[123] M  4:[124] M  1:[124] H  2:[124] H
5:[524] M  1:[512] H  2:[512] H  3:[512] M  → 3:[312] H wait...
Actually:
After 5→[524]: 1=[524]H, 2=[524]H, 3=[523]M(evict 4), 4=[423]M(evict 5), 5=[423]H
LRU misses: 8
```

**Problem 4:**
```
The stack has a maximum size (typically 8MB on Linux, ulimit -s).
Above the stack is unmapped virtual address space.
When the stack grows beyond its limit, it accesses an unmapped VMA.
The OS sees the fault is for an invalid VMA → sends SIGSEGV.
There's a small "guard page" at the stack boundary with no permissions
specifically to catch stack overflow and generate SIGSEGV immediately.
```

---

## References

- Patterson & Hennessy — *Computer Organization and Design* — Chapter 5.7
- Bryant & O'Hallaron — *Computer Systems: A Programmer's Perspective* — Chapter 9
- Linux kernel — [virtual memory documentation](https://www.kernel.org/doc/html/latest/mm/)
- MIT 6.004 — [Virtual Memory lecture](https://ocw.mit.edu/courses/6-004-computation-structures-spring-2017/)
