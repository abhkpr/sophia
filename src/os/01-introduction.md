# Introduction to Operating Systems

## What is an Operating System?

An operating system is the software layer between your programs and the hardware. It manages hardware resources and provides a clean, consistent interface for programs to use them — without needing to know the messy details of the hardware underneath.

**Real-world analogy:** Think of an OS as the manager of a large office building.
- The **building** is the hardware (CPU, RAM, disk, network)
- The **tenants** are the programs (Chrome, VS Code, your game)
- The **manager (OS)** allocates office space (memory), controls access to shared equipment (CPU, printer/disk), prevents tenants from walking into each other's offices (isolation), and handles emergencies (crashes, errors)

Without a manager, tenants would fight over resources, steal from each other, and the building would fall into chaos. The OS prevents exactly that.

---

## Part 1 — What the OS Does

### Three Core Roles

**1. Resource Manager**
```
Hardware Resources:
  CPU     → who runs right now?
  Memory  → who owns which addresses?
  Disk    → who reads/writes which files?
  Network → who sends/receives packets?
  Devices → who controls the keyboard, GPU, camera?

OS allocates and arbitrates all of these.
Without OS: programs fight over hardware → chaos, crashes, security holes.
```

**2. Abstraction Layer**
```
Without OS (bare metal):
  To read a file: know exact disk sectors, send low-level ATA commands,
  handle motor spin-up, manage retries on read errors, ...
  
With OS:
  read(fd, buffer, 1024);  ← one function call, OS handles everything

The OS hides hardware complexity behind simple, clean interfaces.
Same program runs on:
  HDD, SSD, NVMe, USB drive, network filesystem
  Intel x86, ARM, RISC-V
  1GB RAM, 32GB RAM
```

**3. Security and Isolation**
```
Your bank app and a random downloaded game run simultaneously.
The OS ensures:
  - Game cannot read bank app's memory
  - Game cannot write bank app's files
  - Game cannot impersonate bank app
  - If game crashes, bank app keeps running

Hardware enforces this via privilege levels and virtual memory.
OS configures and manages that hardware.
```

---

## Part 2 — Operating System Structure

### The Kernel

The **kernel** is the core of the OS — the part that runs with full hardware privileges.

```
User Space (restricted):        Kernel Space (privileged):
┌────────────────────┐          ┌────────────────────────────┐
│  Chrome  │  VS Code │         │  Process Manager           │
│  Python  │  Your app│         │  Memory Manager            │
└────────────────────┘          │  File System               │
         │                      │  Device Drivers            │
         │ System Calls         │  Network Stack             │
         ▼                      │  Security                  │
┌─────────────────────────────────────────────────────────┐
│                      KERNEL                             │
└─────────────────────────────────────────────────────────┘
                         │
                         ▼
        Hardware: CPU, RAM, Disk, Network, Devices
```

**Kernel vs User Space:**
```
Kernel mode (ring 0 in x86):
  - Can execute any CPU instruction
  - Can access any memory address
  - Can read/write any I/O device
  - One bug here can crash the whole system

User mode (ring 3 in x86):
  - Restricted instruction set
  - Can only access own virtual memory
  - Must ask kernel for hardware access (system calls)
  - One bug crashes only that program
```

### Kernel Architectures

**Monolithic Kernel:**
```
All OS services run in kernel space in one large program.

┌─────────────────────────────────────────┐
│              KERNEL (ring 0)            │
│  File System + Memory + Scheduler +     │
│  Drivers + Network + IPC + Security     │
└─────────────────────────────────────────┘

Pros: fast (no context switches between services)
Cons: one buggy driver can crash the whole OS
Examples: Linux, early Windows, BSD
```

**Microkernel:**
```
Only minimal services in kernel. Everything else in user space.

┌────────────────────────────┐  User space services:
│  KERNEL (ring 0):          │  ┌──────────┐ ┌────────────┐
│  IPC + basic scheduling    │  │File System│ │Device Driver│
│  + memory + interrupts     │  └──────────┘ └────────────┘
└────────────────────────────┘  ┌──────────┐ ┌────────────┐
                                │ Network  │ │  Security  │
                                └──────────┘ └────────────┘

Pros: more reliable (driver crash doesn't crash OS), better security
Cons: slower (lots of message passing between services)
Examples: Mach, QNX, L4, MINIX, some of macOS
```

**Hybrid Kernel:**
```
Compromise: microkernel base with some services moved in for performance
Examples: Windows NT, macOS (XNU = Mach microkernel + BSD monolithic parts)
```

**Exokernel:**
```
Minimal kernel that only multiplexes hardware.
Applications implement their own abstractions.
Research systems: MIT Exokernel
Pros: maximum flexibility and performance
Cons: very complex application code
```

---

## Part 3 — System Calls

The mechanism by which user programs request OS services.

**Real-world analogy:** You're a visitor in a secure government building. You can't just walk into the filing room (kernel space). You fill out a request form at the reception desk (system call), show your ID, and a security-cleared employee fetches the file for you.

### How System Calls Work

```
User program calls read(fd, buf, n)
         │
         ▼
Library wrapper (libc):
  1. Put arguments in registers
  2. Put system call number in register (e.g., rax = 0 for read on Linux)
  3. Execute SYSCALL instruction (x86-64) / SVC (ARM) / ECALL (RISC-V)
         │
         ▼  (hardware switches to kernel mode)
Kernel:
  4. Save user register state
  5. Verify arguments (valid fd? valid buffer pointer? valid count?)
  6. Dispatch to sys_read() handler
  7. Execute the operation
  8. Restore user registers, put return value in rax
  9. Return to user mode (SYSRET instruction)
         │
         ▼
User program receives return value
```

### Common System Calls

```
File Operations:
  open(path, flags)     → file descriptor
  read(fd, buf, n)      → bytes read
  write(fd, buf, n)     → bytes written
  close(fd)             → 0 on success
  lseek(fd, offset, w)  → new position
  stat(path, &statbuf)  → file metadata

Process:
  fork()                → child PID (in parent), 0 (in child)
  exec(path, argv)      → replaces current process
  exit(status)          → terminates process
  wait(pid)             → waits for child to finish
  getpid()              → current process ID

Memory:
  mmap(addr, len, ...)  → virtual address mapping
  munmap(addr, len)     → remove mapping
  brk(addr)             → change heap size

Networking:
  socket(domain, type)  → socket descriptor
  bind(fd, addr)        → bind socket to address
  connect(fd, addr)     → connect to remote
  send(fd, buf, n)      → send data
  recv(fd, buf, n)      → receive data
```

**Cost of system calls:**
```
Function call:   ~1-5 cycles
System call:     ~100-1000 cycles

Why so expensive?
  - CPU privilege level switch (ring 3 → ring 0)
  - Register saving/restoring
  - Argument validation (security)
  - TLB/cache effects of switching to kernel address space

This is why:
  printf() buffers output (batch many characters → 1 write syscall)
  read() has internal buffers (reduce syscall frequency)
  io_uring submits many I/O requests with 1 syscall
```

---

## Part 4 — OS as Virtualizer

The OS presents each program with the illusion that it owns the machine.

```
Reality:                    Illusion presented by OS:

One CPU                     Each process thinks it has dedicated CPU
  → CPU time-shared         (preemptive multitasking)

One physical memory         Each process thinks it has contiguous private RAM
  → virtual memory           (address 0x400000 means different things per process)

One disk                    Each process sees an organized file tree
  → file system              (not raw sectors)

One network card            Each process gets its own socket interface
  → TCP/IP stack             (port numbers isolate connections)
```

---

## Part 5 — Brief History

Understanding where OS concepts came from clarifies why they exist.

```
1950s — No OS:
  Programs ran one at a time, directly on hardware
  Operator manually loaded punch cards
  CPU idle 99% of time (human too slow)

1960s — Batch Systems:
  Jobs queued and run automatically
  CPU still idle waiting for I/O
  Problem: one crash killed all queued jobs

1960s — Multiprogramming:
  Multiple programs loaded in memory simultaneously
  When one waits for I/O, run another
  First real use of process scheduling

1970s — Time-sharing (UNIX born):
  Multiple interactive users on one machine
  Each gets illusion of dedicated computer
  UNIX designed at Bell Labs: clean, simple, powerful
  Key innovation: file system abstraction, fork/exec model

1980s — Personal Computers:
  DOS: single-user, no protection, no multitasking
  Early Mac: GUI but cooperative multitasking

1990s — Modern Systems:
  Windows NT: preemptive multitasking, memory protection
  Linux 1.0 (1994): free UNIX-like OS
  Symmetric multiprocessing (multiple CPUs)

2000s-present:
  Virtualization becomes mainstream
  Mobile OS (Android, iOS)
  Cloud and containers
  Multi-core everything
```

---

## Part 6 — Key OS Abstractions

Every complex OS feature is built from a few fundamental abstractions.

```
Abstraction     Virtualizes     Key Operations
────────────────────────────────────────────────
Process         CPU             fork, exec, exit, wait
Thread          CPU (per-process) create, join, sync
Address Space   Physical Memory  mmap, page fault, swap
File            Disk Blocks      open, read, write, close
Socket          Network Card     connect, send, recv
Pipe            N/A (IPC)        read, write (buffered)
Signal          N/A (Events)     kill, signal handlers
```

---

## Practice Problems

1. Why does the OS need to run in a privileged mode separate from user programs?

2. A user program calls `printf("hello")`. Trace all the layers this call passes through before anything appears on screen.

3. Why are system calls expensive compared to regular function calls? What techniques reduce this overhead?

4. What is the difference between a microkernel and monolithic kernel? Which does Linux use?

5. Name two things the OS virtualizes and explain the illusion it creates for each.

---

## Answers

**Problem 1:**
```
If user programs ran with full privileges:
- Any bug in any program could corrupt OS data structures
- Malicious programs could read other programs' memory
- Any program could disable interrupts and freeze the system
- Programs could issue direct disk commands bypassing file system security

Privileged mode ensures:
- Only the OS can configure hardware (MMU, interrupt controller, etc.)
- User programs can only access their own virtual memory
- System calls are the only gateway to privileged operations
- Hardware enforces this — unauthorized privileged instructions
  cause a fault that the OS handles
```

**Problem 2:**
```
printf("hello")
→ libc printf: format string, store in buffer
→ When buffer flushes: libc write() wrapper
→ write() sets up registers, executes SYSCALL instruction
→ CPU switches to kernel mode (ring 0)
→ Kernel sys_write() handler
→ Look up file descriptor 1 (stdout) → terminal device
→ Device driver for terminal/PTY
→ If real terminal: UART driver → hardware register write
  If emulated terminal (xterm): copy to PTY buffer
→ Terminal emulator reads from PTY → renders to framebuffer
→ GPU driver → GPU → display
→ Characters appear on screen
```

**Problem 3:**
```
Expensive because:
  1. Privilege level switch (hardware: ring 3 → ring 0, then back)
  2. All user registers saved to kernel stack
  3. Kernel address space activated (TLB shootdown if needed)
  4. Argument validation (every pointer must be checked)
  5. Kernel runs on different cache state → cold caches

Techniques to reduce overhead:
  - vDSO (virtual dynamic shared object): some syscalls (gettimeofday,
    clock_gettime) mapped into user space, no ring switch needed
  - io_uring: submit many I/O operations with a single syscall
  - Buffering: stdio buffers writes, reducing write() call frequency
  - Huge pages: reduce TLB pressure on syscall/return
```

**Problem 4:**
```
Monolithic kernel (Linux):
  All OS services compiled into one large kernel image
  Runs entirely in kernel space (ring 0)
  File system, scheduler, drivers, network — all in one
  
  Pros: very fast (direct function calls between components)
  Cons: one buggy driver = potential kernel panic

Microkernel (MINIX, QNX):
  Only minimal IPC, scheduling, basic memory in kernel
  File systems, drivers, network run as user-space servers
  
  Pros: more reliable (driver crash → restart that server, not crash OS)
  Cons: slower (IPC messages between components)

Linux is monolithic with modules:
  Core in kernel space, drivers can be loaded as modules
  Loadable kernel modules (LKM): add drivers without recompiling kernel
```

**Problem 5:**
```
1. CPU virtualization:
   Reality: 1 CPU for 100 running processes
   Illusion: each process thinks it has a dedicated CPU
   Mechanism: timer interrupt, context switch, scheduling
   
2. Memory virtualization:
   Reality: one physical RAM shared by all processes
   Illusion: each process has private 64-bit address space (0 to 2^64-1)
   Mechanism: page tables, MMU, virtual addresses
   Result: process A's address 0x1000 is different physical memory
           from process B's address 0x1000
```

---

## References

- Arpaci-Dusseau & Arpaci-Dusseau — *Operating Systems: Three Easy Pieces* (free online) — Chapters 1-2
- Tanenbaum — *Modern Operating Systems* — Chapter 1
- Silberschatz — *Operating System Concepts* — Chapter 1
- MIT 6.S081 — [Operating System Engineering](https://pdos.csail.mit.edu/6.828/2021/)
- OSTep free book — [ostep.org](https://ostep.org)
