# Operating Systems

## What is an Operating System?

An **operating system** is system software that manages hardware resources and provides services for application software. It sits between the hardware and user applications, acting as an intermediary.

Without an OS, every program would need to manage hardware directly — handling CPU scheduling, memory allocation, disk I/O, and device drivers itself. The OS abstracts this complexity.

## Core Responsibilities

**Process Management** — creating, scheduling, and terminating processes. Deciding which process gets CPU time and for how long.

**Memory Management** — allocating and deallocating memory to processes. Implementing virtual memory so processes think they have more RAM than physically exists.

**File System** — organizing data on persistent storage. Providing a hierarchical namespace (directories and files) and managing read/write operations.

**I/O Management** — abstracting hardware devices behind a uniform interface. A program writes to a file the same way whether the file is on an SSD, HDD, or network drive.

**Security** — enforcing access controls, isolating processes from each other, preventing unauthorized access to resources.

## Kernel vs User Space

The OS runs in two modes:

**Kernel space** — privileged mode. Direct hardware access. OS code runs here. A bug here can crash the entire system.

**User space** — restricted mode. Application code runs here. Cannot directly access hardware. Must ask the kernel via system calls.

```
User Application
      ↓ system call (read, write, fork, etc.)
  Kernel (OS)
      ↓
   Hardware
```

## Topics in This Section

- Processes and Threads
- CPU Scheduling
- Memory Management and Virtual Memory
- Deadlocks
- File Systems
- I/O Systems
- Synchronization
- Inter-process Communication
