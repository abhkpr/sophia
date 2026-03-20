# I/O Systems and Storage

## Connecting the CPU to the World

A CPU that could only compute but never receive input or produce output would be useless. I/O (Input/Output) systems connect the CPU to everything else: keyboards, displays, storage, networks. Understanding I/O reveals why database performance depends on storage layout, why network code looks the way it does, and why SSDs changed system design.

**Real-world analogy:** The CPU is the manager of a company. Registers and cache are the manager's desk — tiny but instant access. RAM is the filing cabinet — bigger, a short walk away. Storage (disk/SSD) is the off-site archive — huge, but you need to send a request and wait. Network is the postal service — can reach anywhere, but latency is significant. A good manager (OS) orchestrates all these resources efficiently.

---

## Part 1 — I/O System Overview

### The Bus System

```
CPU ←──────────────── CPU Bus (fastest) ──────────────────→ Memory
     ←──────────────── PCIe Bus ─────────────────────────→ GPU, NVMe SSD
     ←──────────────── SATA/USB Bus ────────────────────→ HDD, USB devices
     ←──────────────── USB Bus ──────────────────────────→ Keyboard, Mouse

Modern system (simplified):
┌─────────┐   ┌───────────┐   ┌─────────────────────┐
│   CPU   │←──│ Memory    │←──│      DRAM           │
│         │   │ Controller│   └─────────────────────┘
│         │   └───────────┘
│         │   ┌───────────┐   ┌─────────────────────┐
│         │←──│  PCIe     │←──│ GPU / NVMe SSD      │
│         │   │ Root Hub  │   └─────────────────────┘
│         │   └───────────┘
│         │   ┌───────────┐   ┌─────────────────────┐
│         │←──│   PCH     │←──│ SATA / USB / Audio  │
│         │   │(Platform  │   └─────────────────────┘
└─────────┘   │Controller │
              │    Hub)   │
              └───────────┘
```

### PCIe (Peripheral Component Interconnect Express)

The dominant high-speed I/O bus today.

```
PCIe x1:    ~1 GB/s   (one lane)
PCIe x4:    ~4 GB/s   (four lanes)
PCIe x16:  ~16 GB/s   (sixteen lanes — GPU slot)

PCIe 4.0 x4:  ~8 GB/s  (NVMe SSDs)
PCIe 5.0 x16: ~64 GB/s (next-gen GPUs)

Key: PCIe is a point-to-point, serial link (one bit at a time, very fast)
vs. old PCI: parallel bus, shared among all devices, much slower
```

---

## Part 2 — I/O Methods

### Programmed I/O (Polling)

CPU directly reads/writes device registers in a loop.

```cpp
// Pseudocode: send byte to UART (serial port)
void uartSendByte(uint8_t byte) {
    // Wait until transmit buffer empty
    while (!(UART_STATUS & TX_EMPTY)) {
        // busy-wait — CPU doing nothing useful
    }
    UART_DATA = byte;  // write to device register
}

Pros: simple, low latency for fast devices
Cons: CPU wastes 100% of its time waiting (busy-wait)
      Unacceptable for slow devices (keyboard, disk)
```

**Analogy:** You order food at a restaurant, then stand at the kitchen window staring at the chef until your food is ready. You can't do anything else.

### Interrupt-Driven I/O

Device notifies CPU when ready via interrupt. CPU can do other work meanwhile.

```
1. CPU issues I/O request to device (e.g., "read sector 42")
2. CPU continues executing other processes
3. Device finishes → raises interrupt signal on interrupt line
4. CPU finishes current instruction
5. CPU saves state (PC, registers) onto stack
6. CPU jumps to Interrupt Service Routine (ISR) / interrupt handler
7. ISR reads data from device, copies to kernel buffer
8. ISR acknowledges interrupt (clears it)
9. CPU restores saved state, continues previous process

Timeline:
CPU: [other work...][other work...][ISR: 2µs][other work...]
Disk:                [seek + rotate + read: 5ms]────────►[interrupt]
                                                         ↑
                                                CPU notified here

CPU was productive the entire 5ms! (not wasted in busy-wait)
```

**Interrupt Handling in Hardware:**
```
Interrupt Controller (e.g., APIC):
  - Receives interrupt signals from all devices
  - Prioritizes them (higher priority preempts lower)
  - Sends IRQ (interrupt request) to CPU
  - CPU has interrupt enable/disable flag (IF flag in x86)

Interrupt vector table:
  - Array of function pointers, indexed by interrupt number
  - IRQ 0:  Timer
  - IRQ 1:  Keyboard
  - IRQ 14: IDE disk
  - IRQ NN: user-defined
```

### DMA (Direct Memory Access)

For bulk transfers, let a dedicated DMA controller move data directly to/from memory without CPU involvement.

```
Without DMA (CPU copies):
CPU: [read 1 byte from disk][write to RAM][read][write][read][write]...
     × 512 times for one sector = CPU tied up for entire transfer

With DMA:
1. CPU programs DMA controller:
   "Copy 512 bytes from disk controller to address 0x8000"
2. CPU continues other work
3. DMA controller executes the copy autonomously
   - Reads from device, writes to RAM, uses memory bus
   - CPU bus is free (DMA uses it during CPU idle cycles — "cycle stealing")
4. DMA complete → DMA controller interrupts CPU
5. CPU reads 512 bytes from 0x8000 (already in RAM)

Modern: PCIe devices do DMA directly (GPU, NVMe SSD)
  GPU computes → writes result directly to CPU-accessible memory
  NVMe SSD → DMAs data directly to kernel buffer, interrupts CPU
```

**Comparison:**
```
Method          CPU Usage    Latency    Use Case
Polling         100%         Lowest     Fast devices, real-time
Interrupt       ~0%          Medium     Keyboard, mouse, network
DMA             ~0%          Medium     Disk, network bulk transfer
```

---

## Part 3 — Storage Devices

### HDD (Hard Disk Drive)

```
Physical structure:
  ┌────────────────────────────────────────┐
  │  Spindle motor spins platters          │
  │  at 5400 or 7200 RPM                   │
  │                                        │
  │  ┌──────────────────────────────────┐  │
  │  │  Platter (magnetic disk)         │  │
  │  │  ┌─────────────────────────────┐│  │
  │  │  │  Tracks (concentric circles)││  │
  │  │  │  ┌──────────────────────┐   ││  │
  │  │  │  │ Sectors (512B-4KB)   │   ││  │
  │  │  │  └──────────────────────┘   ││  │
  │  │  └─────────────────────────────┘│  │
  │  └──────────────────────────────────┘  │
  │  Read/Write heads on actuator arm      │
  └────────────────────────────────────────┘

Access time = Seek time + Rotational latency + Transfer time
  Seek time:        1-10ms  (arm moves to correct track)
  Rotational latency: 0-8ms  (wait for sector to rotate under head)
                     avg = 4ms at 7200 RPM (60/7200/2 = 4.17ms)
  Transfer time:    0.1ms   (read the sector)
  
Total average: ~10ms per random read
Sequential reads: much faster (no seeking between reads)

Throughput:
  Sequential: 100-200 MB/s
  Random 4KB reads: ~0.5-1 MB/s  (100-200 IOPS)
  
Key insight: HDDs HATE random access. Sequential is 100-400× faster.
This is why databases use B-trees (sequential-friendly) not linked lists.
```

### SSD (Solid State Drive)

```
Storage: NAND flash memory cells
  SLC (Single Level Cell): 1 bit/cell  — fast, durable, expensive
  MLC (Multi Level Cell):  2 bits/cell — balanced
  TLC (Triple Level Cell): 3 bits/cell — slow, less durable, cheap
  QLC (Quad Level Cell):   4 bits/cell — very slow, cheap

No moving parts → no seek time, no rotational latency

Access:
  Random read:    10-100 µs    (100-10,000× faster than HDD)
  Sequential:     500-7000 MB/s

IOPS (I/O Operations Per Second):
  HDD:    100-200 IOPS
  SATA SSD: 50,000-100,000 IOPS
  NVMe SSD: 500,000-1,000,000+ IOPS

NVMe (Non-Volatile Memory Express):
  Protocol designed specifically for SSDs (unlike SATA, designed for HDDs)
  Connects via PCIe directly — no legacy overhead
  Supports 64,000 command queues (vs SATA's 1!)
```

**SSD Internals:**
```
Pages: smallest unit of read/write (4KB-16KB)
Blocks: smallest unit of ERASE (256KB-1MB)

Critical constraint: must erase entire block before rewriting!
  Write: can write to any empty page  O(1)
  Overwrite: must read entire block, erase block, write modified block
             "Write amplification" — writing 4KB causes 256KB of flash I/O

FTL (Flash Translation Layer):
  Maps logical block addresses (what OS sees) to physical flash locations
  Implements wear leveling: spreads writes across all cells
    (Flash cells wear out after 1,000-100,000 program/erase cycles)
  Implements garbage collection: reclaims freed space
  Hides all complexity from OS
```

### NVM (Non-Volatile Memory) / Persistent Memory

```
Intel Optane (3D XPoint):
  Byte-addressable (unlike flash which has page/block structure)
  Speed: ~300ns latency (between DRAM and NAND)
  Endurance: much better than NAND
  
  Used as: fast storage tier, or as DRAM extension
  Status: Intel discontinued Optane in 2022
```

---

## Part 4 — I/O in the OS

### Device Drivers

```
Software architecture:
┌────────────────────────────────┐
│    Application (printf, etc.)  │
├────────────────────────────────┤
│    System Call Interface       │  (read, write, ioctl)
├────────────────────────────────┤
│    Virtual File System (VFS)   │  (unified interface)
├────────────────────────────────┤
│    File System (ext4, NTFS...) │  (directories, files)
├────────────────────────────────┤
│    Block I/O Layer             │  (scheduling, caching)
├────────────────────────────────┤
│    Device Driver (kernel code) │  (hardware-specific)
├────────────────────────────────┤
│    Hardware (disk controller)  │
└────────────────────────────────┘
```

### I/O Scheduling

Multiple processes competing for the disk. In what order to serve them?

**FIFO (First Come First Served):**
```
Requests: cylinder 98, 183, 37, 122, 14, 124, 65, 67
Starting head position: 53

Order: 53→98→183→37→122→14→124→65→67
Movement: 45+85+146+85+108+110+59+2 = 640 cylinders
```

**SCAN (Elevator Algorithm):**
```
Head moves in one direction, serves all requests on the way,
then reverses.

53→65→67→98→122→124→183→37→14
Movement: much less total movement

Like an elevator: doesn't go back to floor 1 just because
someone pressed it — continues up first, then comes back down.
```

**C-SCAN (Circular SCAN):**
```
Like SCAN but on return sweep, jumps back to start without serving
Provides more uniform wait times
Used in many OS schedulers
```

**Modern SSDs: scheduling less important**
```
NVMe SSDs have near-uniform access time for all locations
No physical head to move
OS uses simpler scheduling (often none for NVMe)
Focus: merge small I/Os, maintain ordering where needed
```

---

## Part 5 — The I/O Stack in Practice

### Buffered vs Direct I/O

```cpp
// Buffered I/O (default in OS):
FILE* f = fopen("data.bin", "rb");
fread(buffer, 4096, 1, f);
// OS caches the page in the page cache
// Second fread of same data → served from RAM (page cache hit)

// Direct I/O (O_DIRECT):
int fd = open("data.bin", O_RDONLY | O_DIRECT);
read(fd, buffer, 4096);
// Bypasses page cache, goes directly to hardware
// Used by: databases (manage their own buffer cache)
//          video streaming (huge sequential data, caching useless)
```

### Synchronous vs Asynchronous I/O

```cpp
// Synchronous (blocking):
ssize_t bytes = read(fd, buffer, 4096);
// Thread blocks here until data is ready
// Simple but wastes CPU time

// Asynchronous (non-blocking):
struct aiocb cb = { .aio_fildes = fd,
                    .aio_buf = buffer,
                    .aio_nbytes = 4096 };
aio_read(&cb);
// Returns immediately!
// Do other work...
while (aio_error(&cb) == EINPROGRESS) { /* poll or wait */ }
ssize_t bytes = aio_return(&cb);
// Data is now in buffer

// io_uring (modern Linux, extremely fast):
// Zero-copy, no syscall per operation, batch submissions
// Used by: Nginx, databases for high-performance I/O
```

### Memory-Mapped I/O (MMIO)

Device registers accessible via memory addresses.

```cpp
// Device registers appear at specific physical addresses
// After mapping: read/write to pointer = read/write device register

// Example: control a hardware timer
volatile uint32_t* timer_control = (volatile uint32_t*)0xFE003000;
volatile uint32_t* timer_value   = (volatile uint32_t*)0xFE003004;

*timer_control = 0x00000001;  // start timer (write device register)
uint32_t elapsed = *timer_value; // read elapsed time

// volatile: tells compiler NOT to cache this in a register
// (hardware can change the value at any time)
```

---

## Part 6 — RAID (Redundant Array of Independent Disks)

Combine multiple disks for performance, capacity, or reliability.

```
RAID 0 — Striping:
  [Disk 1] [Disk 2] [Disk 3]
   Block0   Block1   Block2
   Block3   Block4   Block5
  
  Performance: 3× read and write speed (parallel)
  Capacity:    3× single disk
  Fault tolerance: NONE — one disk fails → all data lost
  Use case: video editing scratch disk, temp data

RAID 1 — Mirroring:
  [Disk 1] [Disk 2]    (identical copies)
   Block0   Block0
   Block1   Block1
  
  Performance: 2× read speed (read from either disk)
               same write speed (write both simultaneously)
  Capacity:    same as one disk (50% efficiency)
  Fault tolerance: survives 1 disk failure
  Use case: OS drives, critical data

RAID 5 — Striping with Parity:
  [Disk 1] [Disk 2] [Disk 3] [Disk 4]
  Block0   Block1   Block2   Parity012
  Block4   Block5   Parity45  Block6
  Block8   Parity89 Block9   Block10
  
  Parity = XOR of all data blocks in stripe
  Can reconstruct any missing block from parity
  
  Performance: 3× read, ~1× write (parity computation)
  Capacity:    N-1 disks (3/4 efficiency for 4 disks)
  Fault tolerance: survives 1 disk failure
  Use case: most common for servers

RAID 6 — Double Parity:
  Like RAID 5 but with 2 parity blocks
  Survives 2 simultaneous disk failures
  N-2 disks capacity

RAID 10 — Stripe of Mirrors:
  Mirror pairs, then stripe across pairs
  Survives 1 failure per mirror pair
  50% capacity, fastest writes with redundancy
```

---

## Practice Problems

1. A 7200 RPM HDD has average seek time of 8ms. What is the average rotational latency? What is total average random access time?

2. Calculate NVMe SSD vs HDD throughput for random 4KB reads:
   - HDD: 150 IOPS
   - NVMe SSD: 700,000 IOPS
   How many times faster is the SSD?

3. You have 4 x 4TB disks. Compare total usable storage for RAID 0, 1, 5, and 10.

4. Why does a database (like PostgreSQL) use O_DIRECT I/O instead of buffered I/O?

---

## Answers

**Problem 1:**
```
7200 RPM = 7200 rotations per minute = 120 rotations per second
One full rotation = 1/120 seconds = 8.33 ms
Average rotational latency = half rotation = 4.17 ms
Total avg random access = seek + rotation + transfer
                        = 8ms + 4.17ms + 0.1ms ≈ 12.3ms
```

**Problem 2:**
```
HDD:   150 IOPS × 4KB = 600 KB/s
NVMe:  700,000 IOPS × 4KB = 2,800,000 KB/s = 2.8 GB/s
SSD is 700,000/150 ≈ 4,667× faster in IOPS
```

**Problem 3:**
```
4 × 4TB disks:

RAID 0:  4 × 4TB = 16TB  (no fault tolerance)
RAID 1:  2TB (mirrors, only 2 disks worth used)
         Wait — RAID 1 needs pairs: 2 mirror pairs = 2×4TB = 8TB
RAID 5:  (4-1) × 4TB = 12TB  (one disk for parity)
RAID 10: 2 mirror pairs, striped = 2 × 4TB = 8TB
```

**Problem 4:**
```
PostgreSQL manages its own buffer cache (shared_buffers).
If it used buffered I/O, data would be cached TWICE:
  - Once in PostgreSQL's buffer pool
  - Once in the OS page cache
This wastes RAM and adds overhead.

With O_DIRECT:
  - PostgreSQL controls exactly what's cached and when
  - No redundant copies
  - Can implement database-specific eviction policies
  - Avoids double-copy: disk → OS cache → userspace buffer
    With O_DIRECT: disk → userspace buffer (one copy)
```

---

## References

- Patterson & Hennessy — *Computer Organization and Design* — Chapter 5
- Bryant & O'Hallaron — *CS:APP* — Chapter 10 (System-Level I/O)
- Linux I/O — [Brendan Gregg's Linux Performance](https://brendangregg.com/linuxperf.html)
- NVMe Spec — [nvmexpress.org](https://nvmexpress.org/developers/nvme-specification/)
- Storage Performance — [USENIX FAST conference](https://www.usenix.org/conferences/byname/146)
