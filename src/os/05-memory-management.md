# Memory Management

## Managing the Most Precious Resource

Memory (RAM) is finite. Multiple processes want to use it simultaneously. The OS must allocate memory fairly, protect processes from each other, and handle the illusion that each process has more memory than physically exists.

**Real-world analogy:** A city managing real estate.
- **Physical memory** = actual land parcels
- **Virtual memory** = postal addresses (can exceed actual land)
- **Page table** = city records mapping addresses to parcels
- **Paging to disk** = off-site storage
- **Memory allocator** = real estate office assigning land
- **Fragmentation** = scattered empty lots between buildings

---

## Part 1 — Address Space Layout

Every process gets its own virtual address space — a private, contiguous view of memory.

```
64-bit process address space (Linux x86-64):

0xFFFFFFFFFFFFFFFF ┌─────────────────────────────────┐
                   │        Kernel Space             │
                   │  (same for all processes,       │
                   │   mapped but not accessible     │
                   │   from user mode)               │
0xFFFF800000000000 ├─────────────────────────────────┤
                   │                                 │
                   │        (unmapped)               │
                   │                                 │
0x00007FFFFFFFFFFF ├─────────────────────────────────┤
                   │  Stack (grows ↓)                │
                   │  local variables, return addrs  │
                   │  function args                  │
                   ├ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┤
                   │  (unmapped: stack grows here)   │
                   │                                 │
                   ├ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┤
                   │  Memory-mapped files            │
                   │  shared libraries (libc.so...)  │
                   │  anonymous mmap regions         │
                   │  (grows ↓)                      │
                   ├─────────────────────────────────┤
                   │                                 │
                   │  Heap (grows ↑)                 │
                   │  malloc(), new                  │
                   │                                 │
                   ├─────────────────────────────────┤
                   │  BSS segment                    │
                   │  Uninitialized globals/statics  │
0x00000000600000   ├─────────────────────────────────┤
                   │  Data segment                   │
                   │  Initialized globals/statics    │
0x00000000400000   ├─────────────────────────────────┤
                   │  Text segment                   │
                   │  Program code (read-only)       │
0x0000000000000000 └─────────────────────────────────┘
```

**Practical C++ view:**
```cpp
int global_init = 42;          // Data segment
int global_uninit;             // BSS segment

int main() {
    int local = 10;            // Stack
    int* heap = new int(5);    // Heap
    
    // &local > heap address (stack grows down, heap grows up)
    // They grow toward each other; overlap = stack overflow
    
    printf("Stack: %p\n", &local);   // high address
    printf("Heap:  %p\n", heap);     // lower address
}
```

---

## Part 2 — Memory Allocation

### Kernel Memory Allocation

The OS needs to allocate memory for its own data structures (PCBs, page tables, etc.).

**Buddy Allocator:**
```
Memory divided into power-of-2 sized blocks.
When allocating n bytes: find smallest 2^k ≥ n.

Free list (example with 1MB total):
  2^20: [free block 0-1M]

Allocate 64KB (2^16):
  Split 1M → two 512K buddies
  Split 512K → two 256K buddies
  Split 256K → two 128K buddies
  Split 128K → two 64K buddies
  Allocate one 64K buddy

Free list after:
  2^16: [64K at 64K] (other half just allocated)
  2^17: [128K at 128K]
  2^18: [256K at 256K]
  2^19: [512K at 512K]

Freeing: find buddy, if buddy also free → merge (coalesce)
Buddy of block at address X with size S:
  buddy_addr = X XOR S

Pros: fast allocation/deallocation, easy coalescing
Cons: internal fragmentation (request 65KB → get 128KB, 63KB wasted)
Used in Linux for physical page allocation
```

**Slab Allocator:**
```
Problem: frequently allocating/freeing same-sized objects
(PCBs, inodes, dentry, etc.)

Solution: pre-allocate "slabs" of same-sized objects

   inode slab:    [inode][inode][inode][inode][inode]
   PCB slab:      [PCB  ][PCB  ][PCB  ][PCB  ][PCB  ]
   dentry slab:   [dent ][dent ][dent ][dent ][dent ]

Allocating an inode: grab from free list in inode slab
Freeing an inode: return to inode slab (don't really free)

Pros:
  - No fragmentation (objects same size)
  - Fast (no searching, just pop from list)
  - Caches frequently used objects
  - Constructor/destructor called once per slab, not per alloc

Used in Linux for all common kernel objects (kmem_cache)
```

### User Space Memory: malloc/free

```
malloc() asks the OS for memory (via brk() or mmap()),
then manages that memory for the user program.

Heap visualized:
┌──────────────────────────────────────────────────────┐
│ [Header|  allocated block  ][Header| free |Header|...]│
└──────────────────────────────────────────────────────┘

Each block has a header storing: size, allocated/free flag
Free blocks linked together in free list.

Common algorithms:
  First Fit: allocate first free block large enough
    Fast, but leaves small fragments at start of heap

  Best Fit: allocate smallest free block that fits
    Less waste, but slow (scan all free blocks)

  Worst Fit: allocate largest free block
    Leaves large leftovers, usually poor

  Next Fit: like first fit but remember where we left off
    Better locality than first fit

Modern: tcmalloc, jemalloc use size classes
  Separate free lists for 8, 16, 32, 64, 128, ... byte objects
  Each CPU gets own set of lists (thread-local storage)
  No locking needed for common case → very fast
```

### Fragmentation

**Internal fragmentation:** Allocated block larger than requested.
```
Request: 65 bytes
Buddy allocator gives: 128 bytes (next power of 2)
Wasted: 63 bytes internally
```

**External fragmentation:** Enough total free memory, but not contiguous.
```
Memory state:
[FREE 50KB][USED 20KB][FREE 50KB][USED 30KB][FREE 50KB]

Total free: 150KB
Request for 100KB contiguous → FAILS!
None of the free regions are large enough.

Solution: compaction (move allocated blocks together)
  Expensive: must update all pointers
  Not feasible in C/C++ (pointers would become invalid)
  Feasible in Java/Python (garbage collector can update references)
```

---

## Part 3 — Virtual Memory Implementation

### Page Tables

Already covered in Architecture notes, but OS perspective:

```c
// Linux: each process has a mm_struct
struct mm_struct {
    pgd_t* pgd;            // Physical address of PGD (page global directory)
    unsigned long start_code, end_code;   // text segment bounds
    unsigned long start_data, end_data;   // data segment bounds
    unsigned long start_brk, brk;         // heap start and current end
    unsigned long start_stack;            // stack start
    struct vm_area_struct* mmap;          // linked list of VMAs
};

// Each mapped region is a VMA (Virtual Memory Area)
struct vm_area_struct {
    unsigned long vm_start;  // VMA start address
    unsigned long vm_end;    // VMA end address
    unsigned long vm_flags;  // READ, WRITE, EXEC, PRIVATE, SHARED
    struct file* vm_file;    // file this is mapped from (if any)
    // ...
};
```

**Viewing a process's memory map:**
```bash
cat /proc/self/maps
# Output:
# address           perms offset  dev   inode  pathname
# 00400000-00452000 r-xp 00000000 08:01 123456 /bin/cat (text)
# 00651000-00652000 r--p 00051000 08:01 123456 /bin/cat (rodata)
# 00652000-00653000 rw-p 00052000 08:01 123456 /bin/cat (data)
# 01234000-01255000 rw-p 00000000 00:00 0      [heap]
# 7ffe12000-7fff34000 rw-p 00000000 00:00 0    [stack]
# 7ffff7a0d000-... r-xp ... libc.so.6
```

### Page Fault Handling

```
CPU generates page fault → exception → OS handler

void page_fault_handler(virtual_address, error_code) {
    // Find VMA containing virtual_address
    vma = find_vma(current->mm, virtual_address);
    
    if (!vma || vma->vm_start > virtual_address) {
        // Address not in any valid VMA
        send_signal(SIGSEGV);   // segfault!
        return;
    }
    
    // Check permissions
    if (error_code & WRITE && !(vma->vm_flags & VM_WRITE)) {
        send_signal(SIGSEGV);   // write to read-only memory
        return;
    }
    
    // Valid fault: handle it
    if (page_not_present) {
        if (is_anonymous_memory(vma)) {
            // Allocate new zeroed page
            page = alloc_zeroed_page();
            map_page(virtual_address, page);
        } else {
            // Demand paging from file
            page = alloc_page();
            read_from_file(vma->vm_file, page, offset);
            map_page(virtual_address, page);
        }
    } else if (copy_on_write_fault) {
        // Fork'd pages: both processes had read-only copy
        new_page = alloc_page();
        copy_page(old_page, new_page);
        map_page(virtual_address, new_page, WRITE);
    }
}
```

---

## Part 4 — Paging and Swapping

### When RAM is Full

```
Physical memory management:

┌────────────────────────────────────────────────────┐
│              Physical Memory                       │
│  ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐   │
│  │P1-pg0│ │P2-pg5│ │P3-pg2│ │P2-pg1│ │P1-pg3│   │
│  └──────┘ └──────┘ └──────┘ └──────┘ └──────┘   │
└────────────────────────────────────────────────────┘

When new page needed but RAM full:
  1. Select victim page (using replacement policy: LRU, Clock)
  2. If dirty: write victim to swap space on disk
  3. Update victim's PTE: present=0, swap_location=X
  4. Load new page into freed frame
  5. Update new page's PTE: present=1, frame=freed_frame
```

**Swap space:**
```
Dedicated disk partition (or file) for swapped-out pages.
Linux:
  mkswap /dev/sda5
  swapon /dev/sda5
  
  Or swap file:
  dd if=/dev/zero of=/swapfile bs=1M count=4096
  mkswap /swapfile
  swapon /swapfile

When to use swap:
  Total virtual memory = RAM + swap
  Programs can use more memory than RAM
  But: swap is 1000× slower than RAM → thrashing is catastrophic

Thrashing:
  Process needs more memory than available
  Constantly swapping in and out
  Spends more time swapping than doing useful work
  System appears frozen
  Solution: kill processes, add RAM, or limit memory per process
```

### Working Set Model

```
Working set W(t, Δ): set of pages referenced in interval [t-Δ, t]
  Δ = working set window (how far back to look)

If |working set| > available frames: process will thrash
  Must swap out some processes entirely (suspend)
  
  allocate_frames(process) = min(|working_set|, max_frames)

PFF (Page Fault Frequency) algorithm:
  If page fault rate too HIGH: give process more frames
  If page fault rate too LOW:  take away some frames
  Simple adaptive allocation
```

---

## Part 5 — malloc Implementation

Understanding malloc helps write better C/C++ code.

```c
// Minimal malloc using mmap + free list
#include <sys/mman.h>

typedef struct Block {
    size_t size;      // bytes available after header
    int free;         // is this block free?
    struct Block* next; // next block in free list
} Block;

Block* freeList = NULL;

void* malloc(size_t size) {
    // Align to 8 bytes
    size = (size + 7) & ~7;
    
    // Search free list
    Block** current = &freeList;
    while (*current) {
        if ((*current)->free && (*current)->size >= size) {
            // Found a suitable free block
            Block* block = *current;
            
            // Split if much larger than needed
            if (block->size > size + sizeof(Block) + 8) {
                Block* newBlock = (Block*)((char*)(block+1) + size);
                newBlock->size = block->size - size - sizeof(Block);
                newBlock->free = 1;
                newBlock->next = block->next;
                block->next = newBlock;
                block->size = size;
            }
            
            block->free = 0;
            return (void*)(block + 1);  // return data area
        }
        current = &(*current)->next;
    }
    
    // No suitable block: ask OS for more memory
    size_t total = sizeof(Block) + size;
    Block* block = mmap(NULL, total, PROT_READ|PROT_WRITE,
                        MAP_PRIVATE|MAP_ANONYMOUS, -1, 0);
    block->size = size;
    block->free = 0;
    block->next = NULL;
    return (void*)(block + 1);
}

void free(void* ptr) {
    if (!ptr) return;
    Block* block = (Block*)ptr - 1;
    block->free = 1;
    // Add to front of free list
    block->next = freeList;
    freeList = block;
    // In real malloc: coalesce adjacent free blocks
}
```

**Common malloc bugs in C/C++:**
```c
// 1. Use after free
int* p = malloc(sizeof(int));
free(p);
*p = 5;   // UNDEFINED BEHAVIOR: memory might be reused

// 2. Double free
free(p);
free(p);  // UNDEFINED BEHAVIOR: corrupts allocator's data

// 3. Buffer overflow
char* buf = malloc(10);
strcpy(buf, "hello world");  // writes 12 bytes into 10-byte buffer
                             // overwrites adjacent heap metadata

// 4. Memory leak
while (true) {
    char* p = malloc(1024);  // allocated
    // forgot to free(p)!    // never freed
}   // process runs out of memory

// Detection tools:
// valgrind --leak-check=full ./program
// AddressSanitizer: gcc -fsanitize=address
// Valgrind massif: heap profiling
```

---

## Practice Problems

1. A buddy allocator manages 16MB of memory. What size block is allocated for a request of 1.5MB? How much is wasted?

2. Process A uses 100MB but only 20MB is actively used. Explain how the OS handles this with demand paging.

3. What is thrashing? What are two ways to prevent it?

4. Why does `free()` not return memory to the OS immediately?

5. Two processes both call `malloc(1000)`. Do they get the same physical memory? Same virtual address?

---

## Answers

**Problem 1:**
```
Request: 1.5MB
Buddy allocator uses powers of 2:
  1MB < 1.5MB → too small
  2MB ≥ 1.5MB → allocate 2MB block

Waste: 2MB - 1.5MB = 0.5MB = 512KB wasted (internal fragmentation)
Fragmentation ratio: 0.5/2 = 25%
```

**Problem 2:**
```
With demand paging:
  At startup: NO pages loaded in RAM. All PTEs have P=0.
  As process runs, it accesses code pages → page fault → load page
  
  After warmup:
    Active 20MB: in RAM (frequently used, not evicted)
    Inactive 80MB: may be:
      - Never loaded (not yet accessed = demand paging)
      - Swapped out (loaded once, then evicted by replacement policy)
      
  PTEs for unloaded pages: P=0
  When accessed: page fault → OS loads from executable/swap
  
  Memory footprint ≈ working set size (20MB), not total (100MB)
  This is why you can run more programs than RAM would suggest
```

**Problem 3:**
```
Thrashing: process page fault rate so high that it spends more
time handling page faults than executing.

Cause: process working set > available RAM.
Every page load evicts another page that's also needed.
System appears frozen.

Prevention:
1. Working Set algorithm:
   Track each process's working set size.
   Only run processes whose working sets fit in RAM.
   Suspend (swap out entirely) processes when memory pressure high.

2. PFF (Page Fault Frequency):
   If PFF > high threshold: give process more frames
   If PFF < low threshold: reduce frames (give to needier process)
   If can't reduce without thrashing: suspend a process
   
3. Simply: buy more RAM.
   Or: use a system with less concurrent memory pressure.
```

**Problem 4:**
```
free() typically returns memory to malloc's internal free list,
NOT back to the OS.

Reasons:
1. Fragmentation: small freed blocks scattered throughout heap.
   OS can only reclaim whole pages (4KB). If any byte in a page
   is still allocated, that page can't be returned to OS.

2. Performance: mmap()/munmap() syscalls are expensive.
   Better to keep freed memory for quick reuse.

3. Reuse: freed memory likely to be needed again soon.

When memory IS returned to OS:
  - munmap() when large blocks freed (freed block was mmap'd)
  - malloc_trim() call to shrink brk pointer
  - Process exits (all memory returned automatically)

This is why long-running servers can have high "resident set size"
even after freeing lots of data: pages not returned to OS.
```

**Problem 5:**
```
Physical memory: NO (different physical pages)
  OS allocates different physical frames to each process

Virtual address: MAYBE (often yes, could be different)
  Each process has independent virtual address space
  malloc often returns same virtual address (e.g., 0x604420)
  in both processes, but they map to different physical pages
  
  Process A: virtual 0x604420 → physical frame 1234
  Process B: virtual 0x604420 → physical frame 5678
  
  This is the point of virtual memory: isolation!
  Same virtual address, completely separate physical storage.
```

---

## References

- Arpaci-Dusseau — *OSTEP* — Chapters 13-23 (Virtual Memory)
- Silberschatz — *OS Concepts* — Chapter 9-10
- GNU libc — [malloc internals](https://www.gnu.org/software/libc/manual/html_node/The-GNU-Allocator.html)
- Ulrich Drepper — *What Every Programmer Should Know About Memory*
- Linux — `man 3 malloc`, `man 2 mmap`
