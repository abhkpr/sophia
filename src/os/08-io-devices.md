# I/O and Device Management

## Connecting the Infinite World of Devices

The OS must support an enormous variety of hardware: keyboards, mice, displays, disks, SSDs, USB drives, network cards, cameras, printers, GPUs, sensors. Each device works differently. Yet from your program's perspective, a file on an SSD and a file on a network share look identical. The OS makes this possible through abstraction layers.

**Real-world analogy:** A power strip with adapters. Different countries have different outlet shapes and voltages. An adapter converts the standard plug to whatever format the local wall (hardware) uses. The OS is the adapter — your program uses a standard interface (read/write), and the OS translates to whatever the hardware needs.

---

## Part 1 — I/O Hardware Basics

### How the CPU Communicates with Devices

**Port-mapped I/O (PMIO):**
```
Separate address space for I/O.
x86 has 65536 I/O ports, 16-bit addresses.

Special instructions:
  IN  AL, 0x60   ; read from port 0x60 (keyboard data)
  OUT 0x43, AL   ; write to port 0x43 (timer control)

Only accessible from kernel mode.
Historical: original IBM PC used PMIO for most devices.
```

**Memory-mapped I/O (MMIO):**
```
Device registers appear at specific physical memory addresses.
Read/write those addresses = communicate with device.

No special instructions needed — regular load/store.
volatile keyword essential:
  compiler must not cache or reorder these accesses.

Example (ARM: timer at physical address 0xFE003000):
  volatile uint32_t* timer = (volatile uint32_t*)0xFE003000;
  *timer = 0x00000001;     // start timer (write device register)
  uint32_t ticks = *timer; // read current value

Modern devices (PCIe cards, GPU, network cards): all MMIO
Addresses appear in physical memory map, access through page tables.
```

### Device Registers

Most devices have a small set of registers:

```
Typical device has 4 registers:
┌──────────────────────────────────────────────────┐
│  Status Register (read):                         │
│    Bit 0: BUSY  (device currently doing something)│
│    Bit 1: DONE  (last operation complete)        │
│    Bit 2: ERROR (last operation failed)          │
├──────────────────────────────────────────────────┤
│  Command Register (write):                       │
│    0x01: start operation                         │
│    0x02: reset device                            │
├──────────────────────────────────────────────────┤
│  Data Register (read/write):                     │
│    Write: data to send to device                 │
│    Read:  data received from device              │
├──────────────────────────────────────────────────┤
│  Control Register (write):                       │
│    Set operating mode, enable interrupts, etc.   │
└──────────────────────────────────────────────────┘
```

### DMA Controller

For high-bandwidth transfers (disk, network), the CPU shouldn't copy data byte by byte.

```
DMA (Direct Memory Access):

  CPU programs DMA:
    Source: device FIFO register at 0x40001000
    Dest:   kernel buffer at physical 0x00200000
    Length: 4096 bytes
    Direction: device → memory

  DMA transfers autonomously:
    Reads from device, writes to memory
    Uses memory bus during CPU idle cycles
    CPU continues other work

  DMA completion:
    Raises interrupt to CPU
    CPU handles interrupt: data is in buffer, process can use it

  Cache coherence issue:
    DMA writes to physical memory bypassing CPU cache.
    CPU must invalidate cache lines covering that buffer region
    (or ensure the buffer is marked uncacheable).
    Modern systems: IOMMU handles this.
```

---

## Part 2 — Device Drivers

A **device driver** is kernel code that knows how to operate a specific piece of hardware. It translates the generic OS I/O interface into device-specific operations.

```
Device driver responsibilities:
  1. Initialize device at boot
  2. Handle device interrupts
  3. Translate generic read/write requests into device commands
  4. Manage device-specific data structures
  5. Power management (suspend/resume)
  6. Error handling and recovery

Kernel I/O architecture (Linux):
┌───────────────────────────────────────────────────────┐
│                  User Programs                         │
├───────────────────────────────────────────────────────┤
│              System Call Interface                    │
│              (read, write, ioctl, ...)                │
├───────────────────────────────────────────────────────┤
│          Virtual File System (VFS)                    │
│     (unified interface to all file systems)           │
├───────────────────────────────────────────────────────┤
│          Generic Block/Char Layer                     │
│          (request queues, scheduling)                 │
├───────────────────────────────────────────────────────┤
│  ext4    ┌─────────┬────────┬──────────┐             │
│  driver  │  NVMe   │  SATA  │   USB    │ ← Device    │
│          │  driver │ driver │  driver  │   drivers   │
└──────────┴─────────┴────────┴──────────┴─────────────┘
                     HARDWARE
```

### Block Devices vs Character Devices

```
Block devices:
  Data transferred in fixed-size blocks (512B-4KB)
  Random access supported
  Examples: hard drives, SSDs, USB drives, DVD
  Access via: file path, /dev/sda1, /dev/nvme0n1
  
  Kernel maintains a buffer cache for block devices
  Reads/writes go through cache
  
Character devices:
  Data transferred byte by byte (stream)
  Usually sequential, no seek
  Examples: keyboards, serial ports, terminal, /dev/random
  Access via: /dev/tty, /dev/null, /dev/zero
  
  No buffer cache (data consumed immediately)
  read() may return fewer bytes than requested

Special device files:
  /dev/null   → discard all writes, return EOF on reads
  /dev/zero   → always returns zero bytes on reads
  /dev/random → returns random bytes (entropy pool)
  /dev/urandom → non-blocking random (ok for crypto)
  /dev/mem    → physical memory (requires root)
```

---

## Part 3 — I/O Scheduling

Multiple processes issuing disk requests simultaneously. In what order should the disk serve them?

**Goal:** minimize total head movement (seek time).

### FIFO / FCFS

```
Serve requests in arrival order.
Simple but potentially lots of unnecessary head movement.

Requests: cylinder 100, 10, 90, 30, 70, 50
Head at: 40

Order: 40→100→10→90→30→70→50
Movement: 60+90+80+60+40+20 = 350 cylinders
```

### SSTF (Shortest Seek Time First)

```
Always serve the request closest to current head position.

Head at 40, requests: 100, 10, 90, 30, 70, 50

Sorted by distance from 40:
  30 (dist 10), 50 (dist 10), 10 (dist 30),
  70 (dist 30), 90 (dist 50), 100 (dist 60)

Order: 40→30→50→70→90→100→10
Movement: 10+20+20+20+10+90 = 170 cylinders

Problem: inner/outer cylinders may starve.
If requests keep arriving near current position,
requests at far cylinders never get served.
```

### SCAN (Elevator Algorithm)

```
Head moves in one direction, serves all requests on the way,
then reverses. Like an elevator.

Head at 40, moving toward 100, requests: 100, 10, 90, 30, 70, 50

Moving up: 40→50→70→90→100→(reverse)→30→10
Movement: 10+20+20+10+70+20 = 150 cylinders

More uniform wait times than SSTF.
No starvation.
```

### C-SCAN (Circular SCAN)

```
Like SCAN but on return sweep, jumps immediately back to start
without servicing requests. More uniform wait times.

Head at 40, moving toward 200 (end), requests: 100, 10, 90, 30, 70, 50

40→50→70→90→100→200(end)→0(jump to start, no service)→10→30
```

### C-LOOK

```
Like C-SCAN but only goes to last request in each direction,
not the physical end of disk.

Saves unnecessary travel to disk edges.
Most practical improvement to SCAN family.
```

### NVMe and Modern Devices

```
For SSDs and NVMe: physical seek time negligible.
Scheduling less important for latency, but still matters for:
  - Request merging (combine adjacent I/Os into one larger one)
  - Fairness between processes
  - Queue depth optimization

Linux I/O schedulers for NVMe:
  none:     no scheduling (NVMe fast enough)
  mq-deadline: soft real-time deadlines per request
  bfq:      Budget Fair Queueing (per-process fairness)
  
Check current scheduler:
  cat /sys/block/nvme0n1/queue/scheduler
```

---

## Part 4 — Interrupts in Depth

### Interrupt Vector Table

```
x86 Interrupt Descriptor Table (IDT):
  256 entries, indexed by interrupt number
  Each entry: [segment selector | offset | type | DPL]
  
  Entry 0:   Divide by zero
  Entry 1:   Debug
  Entry 2:   NMI (Non-Maskable Interrupt)
  Entry 6:   Invalid opcode
  Entry 13:  General Protection Fault
  Entry 14:  Page Fault
  Entry 32-255: User-defined (hardware IRQs, syscalls)
  Entry 0x80: Linux system call interrupt (legacy mode)
```

### Top Half vs Bottom Half

Interrupt handlers must be fast (can't be interrupted themselves in x86).
Long processing split into two parts:

```
TOP HALF (interrupt handler):
  Runs with interrupts disabled
  Must complete quickly (microseconds)
  Does: save minimal state, acknowledge interrupt,
        schedule bottom half work, return
  
BOTTOM HALF (deferred work):
  Runs with interrupts enabled
  Can be preempted
  Does: actual data processing, calling kernel subsystems
  
  Mechanisms:
    Softirqs:    compile-time, high priority, SMP-safe
    Tasklets:    dynamic, built on softirqs
    Work queues: run in process context (can sleep)

Example: network packet arrival
  IRQ fires: NIC has received data
  
  Top half (IRQ handler, ~10µs):
    Read packet from NIC ring buffer into kernel memory
    Acknowledge interrupt (NIC can receive more)
    Schedule softirq for bottom half
    Return from interrupt
    
  Bottom half (network softirq, later):
    Parse packet headers (IP, TCP/UDP)
    Find matching socket
    Copy data to socket receive buffer
    Wake up process waiting in recv()
    
This approach keeps interrupt latency low
while doing the heavy work asynchronously.
```

---

## Part 5 — Everything is a File (Unix Philosophy)

Unix exposes almost everything through the file abstraction.

```
Regular files:    /home/user/file.txt
Directories:      /home/user/
Block devices:    /dev/sda1
Char devices:     /dev/tty0, /dev/null
Named pipes:      /tmp/mypipe (mkfifo)
Sockets:          /tmp/myapp.sock (Unix domain socket)
Symbolic links:   /usr/bin/python → python3.10
/proc entries:    /proc/1/status (process info)
/sys entries:     /sys/class/net/eth0/speed (device attributes)

The same read/write/open/close interface works for ALL of these!

Examples:
  cat /proc/cpuinfo          # read CPU info like a file
  echo "1" > /proc/sys/net/ipv4/ip_forward  # enable IP forwarding
  cat /dev/random | head -c 10 | xxd        # read random bytes
  echo hello > /dev/pts/1    # write to another terminal
```

**Virtual file systems:**
```
procfs (/proc):
  Process information: /proc/PID/maps, status, fd
  System info: /proc/cpuinfo, /proc/meminfo, /proc/net/
  Tunable parameters: /proc/sys/

sysfs (/sys):
  Hardware topology and driver parameters
  /sys/class/block/sda/queue/scheduler
  /sys/devices/pci0000:00/.../...

debugfs (/sys/kernel/debug):
  Debugging information
  Often mounted at: mount -t debugfs none /sys/kernel/debug

tmpfs:
  File system backed by RAM
  /tmp often uses tmpfs
  Files disappear on reboot
  Fast: no disk I/O
```

---

## Practice Problems

1. A disk has 200 cylinders (0-199). Head is at 50. Requests: 78, 23, 65, 15, 120, 45, 35.
   Calculate total head movement for FCFS, SSTF, and SCAN (moving toward 0 initially).

2. What is the difference between a block device and a character device? Give an example of each.

3. Why must interrupt handlers be fast and not call sleep()?

4. Why does `cat /proc/meminfo` show different output every time you run it, even though /proc is a file?

---

## Answers

**Problem 1:**
```
Requests: 78, 23, 65, 15, 120, 45, 35
Head at 50, sorted: 15, 23, 35, 45, 50, 65, 78, 120

FCFS (order of arrival):
50→78→23→65→15→120→45→35
Movement: 28+55+42+50+105+75+10 = 365

SSTF (always closest):
From 50: 45(5), then 35(10), then 23(12), then 15(8),
         then 65(50), then 78(13), then 120(42)
50→45→35→23→15→65→78→120
Movement: 5+10+12+8+50+13+42 = 140

SCAN (moving toward 0 first):
Go to 0 side: 50→45→35→23→15→0(reverse)→65→78→120
Movement: 5+10+12+8+15+65+13+42 = 170
(But typically we say stop at last request, not go to 0)
LOOK: 50→45→35→23→15(reverse)→65→78→120
Movement: 5+10+12+8+50+13+42 = 140
```

**Problem 2:**
```
Block device:
  Data accessed in fixed-size blocks
  Random access supported (can seek to any block)
  Kernel maintains buffer cache
  Examples: /dev/sda (hard drive), /dev/nvme0n1 (NVMe SSD)
  
  Accessing /dev/sda: reads/writes sectors of 512 bytes
  dd if=/dev/sda of=backup.img  # raw disk backup

Character device:
  Data as byte stream
  Usually sequential, no seeking
  No kernel buffer cache
  Examples: /dev/tty (terminal), /dev/null, /dev/random, /dev/uart0
  
  /dev/null: all writes discarded, reads return EOF
  cat /dev/zero | head -c 100 | xxd  # 100 zero bytes
```

**Problem 3:**
```
Interrupt handlers run with interrupts disabled (at least the same IRQ).
sleep() would require:
  1. Context switch (save current state)
  2. Schedule another process
  3. Set timer to wake up later

Problems:
  1. No process context: interrupt fires in context of whatever
     process was running. Can't "sleep" that process for our sake.
  2. Deadlock: if sleeping in interrupt handler, and the process
     we interrupted holds a lock we need, we'd deadlock.
  3. Priority inversion: critical hardware interrupt delayed.
  4. Interrupt nesting: if we sleep in handler, other interrupts
     of same priority would be indefinitely delayed.

Solution: interrupt handler just saves data and schedules bottom half.
Bottom half runs in process context (can sleep, call any kernel function).
```

**Problem 4:**
```
/proc is a virtual filesystem (procfs) backed by kernel data structures,
not actual disk files.

When you run cat /proc/meminfo:
  1. VFS open() on /proc/meminfo
  2. VFS calls procfs read handler for this file
  3. Handler calls into kernel memory subsystem
  4. Kernel reads CURRENT values of memory counters
  5. Formats them as text and returns to cat
  
The "file" is generated ON DEMAND from live kernel data.
Every read() call goes through the handler and reads fresh data.
No disk involved at all.

This is why:
  cat /proc/meminfo shows current free memory
  cat /proc/$$/status shows current process state
  cat /proc/net/tcp shows current TCP connections
  
  All are real-time snapshots of kernel data,
  not stored files.
```

---

## References

- Arpaci-Dusseau — *OSTEP* — Chapters 36-38 (I/O)
- Silberschatz — *OS Concepts* — Chapter 12 (I/O)
- Linux Device Drivers — [free online book](https://lwn.net/Kernel/LDD3/)
- Robert Love — *Linux Kernel Development* — Chapters 6-7
- Linux I/O schedulers — [kernel docs](https://www.kernel.org/doc/html/latest/block/index.html)
