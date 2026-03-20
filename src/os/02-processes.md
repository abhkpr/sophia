# Processes

## The Most Fundamental OS Abstraction

A **process** is a running program. When you double-click a program, the OS creates a process — it allocates memory, loads the executable, and starts executing instructions. The program (on disk) is a recipe. The process is the actual cooking happening in your kitchen.

**Real-world analogy:** A recipe book is like a program file sitting on disk. It has instructions, but nothing is actually happening. When you start cooking following the recipe, that's a process — the active execution. You can cook the same recipe multiple times simultaneously in different kitchens (multiple processes from one program). Each kitchen is independent — burning one kitchen doesn't affect the others.

---

## Part 1 — What is a Process?

A process consists of:

```
┌─────────────────────────────────────┐
│           PROCESS                   │
│                                     │
│  Address Space:                     │
│  ┌───────────────────────────────┐  │
│  │  Stack (function calls, vars) │  │
│  │       ↓ grows down            │  │
│  │                               │  │
│  │       ↑ grows up              │  │
│  │  Heap (malloc'd memory)       │  │
│  ├───────────────────────────────┤  │
│  │  BSS  (uninitialized globals) │  │
│  ├───────────────────────────────┤  │
│  │  Data (initialized globals)   │  │
│  ├───────────────────────────────┤  │
│  │  Text (program code)          │  │
│  └───────────────────────────────┘  │
│                                     │
│  CPU State (when not running):      │
│    PC, SP, registers saved          │
│                                     │
│  OS Resources:                      │
│    Open file descriptors            │
│    Network connections              │
│    Signal handlers                  │
│    Current directory                │
└─────────────────────────────────────┘
```

### Process Control Block (PCB)

The OS represents each process as a **Process Control Block** — a data structure storing everything the OS needs to know about the process.

```c
// Simplified PCB (similar to Linux task_struct)
struct PCB {
    int pid;                    // Process ID
    enum State state;           // RUNNING, READY, BLOCKED, ZOMBIE
    
    // CPU context (saved when not running)
    struct Registers context;   // all CPU registers
    uint64_t pc;                // program counter
    uint64_t sp;                // stack pointer
    
    // Memory
    PageTable* page_table;      // virtual memory mapping
    
    // Resources
    File* open_files[MAX_FD];   // open file descriptors
    int exit_code;              // exit status when done
    
    // Relationships
    struct PCB* parent;         // who created this process
    struct PCB* children;       // linked list of children
    
    // Scheduling
    int priority;               // scheduler priority
    uint64_t cpu_time;          // total CPU time used
    uint64_t start_time;        // when created
};
```

---

## Part 2 — Process States

**Real-world analogy:** Think of customers at a bank.
- **Running** = being served at the teller window (using the CPU)
- **Ready** = in the queue, waiting for a teller to become free
- **Blocked** = sitting in the waiting area because you need a document from outside (waiting for I/O, a lock, or an event)
- **Zombie** = your transaction is done but the teller is waiting for your receipt confirmation (process finished but parent hasn't collected exit status)

```
                      ┌─────────┐
                      │  NEW    │
                      └────┬────┘
                           │ admitted
                           ▼
         interrupt   ┌─────────┐  scheduler
   ┌─────────────────│  READY  │◄─────────────────┐
   │                 └────┬────┘                  │
   │                      │ scheduled (dispatch)  │
   ▼                      ▼                       │
┌─────────┐          ┌─────────┐          ┌────────┤
│ BLOCKED │◄─────────│ RUNNING │          │I/O done│
│  (wait) │  I/O req │         │          │or event│
└─────────┘          └────┬────┘          └────────┘
    │                     │ exit
    │                     ▼
    │               ┌──────────┐
    │               │  ZOMBIE  │ (waiting for parent wait())
    │               └──────────┘
    │                     │ parent waits
    │                     ▼
    └──────────────► TERMINATED

States:
  NEW:     Being created, not yet in ready queue
  READY:   Runnable, waiting for CPU
  RUNNING: Currently executing on CPU
  BLOCKED: Waiting for event (I/O completion, lock, timer, signal)
  ZOMBIE:  Finished, but parent hasn't called wait() yet
           - Still has PCB with exit status
           - Once parent collects: PCB freed
```

**What causes state transitions:**
```
READY → RUNNING:   Scheduler selects this process (dispatch)
RUNNING → READY:   Timer interrupt (preemption), higher priority process arrives
RUNNING → BLOCKED: Process calls read(), waits on lock/semaphore, calls sleep()
BLOCKED → READY:   I/O completes, lock released, timer fires, signal arrives
RUNNING → ZOMBIE:  Process calls exit() or returns from main()
ZOMBIE → gone:     Parent calls wait(), OS collects exit status
```

---

## Part 3 — Process Creation: fork() and exec()

### fork() — Creating a Child Process

`fork()` creates an exact copy of the calling process.

**Real-world analogy:** A cell dividing. The original cell (parent) splits, creating an identical new cell (child). After division, they're independent — changes in one don't affect the other.

```c
#include <unistd.h>
#include <stdio.h>
#include <sys/wait.h>

int main() {
    printf("Before fork: PID=%d\n", getpid());
    
    int pid = fork();
    
    if (pid < 0) {
        // fork failed
        perror("fork failed");
        exit(1);
    } else if (pid == 0) {
        // We are the CHILD process
        // fork() returns 0 to child
        printf("I am child: PID=%d, Parent=%d\n", getpid(), getppid());
    } else {
        // We are the PARENT process
        // fork() returns child's PID to parent
        printf("I am parent: PID=%d, Child=%d\n", getpid(), pid);
        wait(NULL);    // wait for child to finish
    }
    
    return 0;
}
```

**What fork() copies:**
```
Copied from parent:
  ✓ Virtual address space (all memory — copy-on-write!)
  ✓ Open file descriptors (share underlying file table entries)
  ✓ Signal handlers
  ✓ Environment variables
  ✓ Working directory
  ✓ User/group IDs

NOT copied:
  ✗ PID (child gets new unique PID)
  ✗ Parent PID (child's PPID = parent's PID)
  ✗ Memory locks (don't inherit mlock)
  ✗ Timers
```

**Copy-on-Write (COW) optimization:**
```
Naively, fork() would copy all parent memory immediately.
For a process using 2GB of RAM, that's 2GB copy → very slow!

COW optimization:
  After fork(), child and parent SHARE physical pages
  Pages marked read-only for both
  
  When either process WRITES to a page:
    Hardware fault → OS copies that single page
    Both processes now have their own copy of that page
  
  Result: if child immediately calls exec():
    No pages ever written → no copies made → fork() nearly free!
  
This is why fork()+exec() is efficient despite the apparent full copy.
```

### exec() — Replacing the Process Image

`exec()` replaces the current process's program with a new one. PID stays the same, but everything else changes.

```c
// Child process after fork() runs this:
execvp("ls", (char*[]){"ls", "-la", "/", NULL});
// This process is now running "ls -la /"
// If exec succeeds, the line below NEVER executes
perror("exec failed");  // only reached if exec() failed
exit(1);
```

**What exec() does:**
```
1. Load new executable from disk
2. Reset address space:
   - New text segment (new program code)
   - New data segment
   - Fresh empty heap
   - Fresh stack
3. Reset signal handlers to default
4. Close file descriptors with FD_CLOEXEC flag set
5. Jump to new program's entry point (main)

PID does NOT change!
Open file descriptors inherited (unless FD_CLOEXEC set)
```

### The fork-exec Pattern

This is the fundamental way Unix creates new programs:

```c
// Shell implementing: ls -la | grep foo
int pipe_fd[2];
pipe(pipe_fd);  // create pipe

// Fork for "ls -la"
int ls_pid = fork();
if (ls_pid == 0) {
    // Child 1: become "ls"
    close(pipe_fd[0]);           // close read end
    dup2(pipe_fd[1], STDOUT_FILENO); // stdout → write end of pipe
    close(pipe_fd[1]);
    execvp("ls", (char*[]){"ls", "-la", NULL});
    exit(1);  // exec failed
}

// Fork for "grep foo"
int grep_pid = fork();
if (grep_pid == 0) {
    // Child 2: become "grep"
    close(pipe_fd[1]);           // close write end
    dup2(pipe_fd[0], STDIN_FILENO);  // stdin ← read end of pipe
    close(pipe_fd[0]);
    execvp("grep", (char*[]){"grep", "foo", NULL});
    exit(1);
}

// Parent: shell
close(pipe_fd[0]);
close(pipe_fd[1]);
waitpid(ls_pid, NULL, 0);
waitpid(grep_pid, NULL, 0);
```

---

## Part 4 — Process Termination

**Normal exit:**
```c
exit(0);         // success
exit(1);         // failure
return 0;        // from main() — equivalent to exit(0)
```

**Abnormal termination:**
```
SIGSEGV  — segmentation fault (invalid memory access)
SIGABRT  — abort() called or assert() failed
SIGFPE   — floating point exception (division by zero)
SIGILL   — illegal instruction
SIGKILL  — forceful kill (cannot be caught or ignored)
SIGTERM  — polite termination request (can be caught)
```

**Zombie processes:**
```
When process exits:
  Most resources freed immediately (memory, file handles)
  PCB kept with exit status — becomes ZOMBIE
  Parent must call wait() to collect exit status
  If parent doesn't: zombie accumulates in process table

// Parent collecting child exit status
int status;
pid_t child = wait(&status);      // wait for any child
pid_t child = waitpid(pid, &status, 0); // wait for specific child

if (WIFEXITED(status))
    printf("exited normally, code = %d\n", WEXITSTATUS(status));
if (WIFSIGNALED(status))
    printf("killed by signal %d\n", WTERMSIG(status));
```

**Orphan processes:**
```
If parent dies before child:
  Child becomes orphan
  Init process (PID 1, systemd on Linux) adopts all orphans
  Init always calls wait() → orphans never become permanent zombies
```

---

## Part 5 — Inter-Process Communication (IPC)

Processes are isolated — they can't directly access each other's memory. IPC mechanisms allow controlled communication.

### Pipes

Unidirectional byte stream between related processes.

```c
int pipefd[2];
pipe(pipefd);  // pipefd[0] = read end, pipefd[1] = write end

if (fork() == 0) {
    // Child: writes to pipe
    close(pipefd[0]);  // close unused read end
    write(pipefd[1], "hello", 5);
    close(pipefd[1]);
    exit(0);
} else {
    // Parent: reads from pipe
    close(pipefd[1]);  // close unused write end
    char buf[10];
    int n = read(pipefd[0], buf, sizeof(buf));
    buf[n] = '\0';
    printf("Got: %s\n", buf);  // prints: Got: hello
    close(pipefd[0]);
    wait(NULL);
}
```

**Shell pipes use this exactly:**
```
ls | grep .txt | wc -l
```

### Named Pipes (FIFOs)

Like pipes but have a name in the filesystem — unrelated processes can communicate.

```c
mkfifo("/tmp/myfifo", 0666);  // create named pipe

// Process 1:
int fd = open("/tmp/myfifo", O_WRONLY);
write(fd, "message", 7);

// Process 2 (separate program):
int fd = open("/tmp/myfifo", O_RDONLY);
char buf[100];
read(fd, buf, 100);
```

### Shared Memory

Fastest IPC — map the same physical memory into multiple processes.

```c
#include <sys/mman.h>

// Create shared memory region
int shm_fd = shm_open("/my_shm", O_CREAT | O_RDWR, 0666);
ftruncate(shm_fd, 4096);  // set size

// Map into this process's address space
void* ptr = mmap(NULL, 4096, PROT_READ|PROT_WRITE, MAP_SHARED, shm_fd, 0);

// Now write to ptr → visible to ALL processes that mapped this region
int* shared_counter = (int*)ptr;
*shared_counter = 42;

// Another process maps the same /my_shm → sees shared_counter = 42
// NO system call needed per access — just memory reads/writes!
// BUT: need synchronization (mutex or semaphore) to avoid race conditions
```

### Message Queues

Send discrete messages between processes.

```c
#include <mqueue.h>

// Create queue
mqd_t mq = mq_open("/my_queue", O_CREAT|O_RDWR, 0666, NULL);

// Send message (any process with rights)
mq_send(mq, "hello world", 11, 0);

// Receive message (any process with rights)
char buf[100];
mq_receive(mq, buf, 100, NULL);
printf("%s\n", buf);  // hello world
```

### Signals

Asynchronous notifications sent to a process.

```c
#include <signal.h>

// Register signal handler
void handleSIGINT(int sig) {
    printf("\nCaught Ctrl+C! Cleaning up...\n");
    exit(0);
}

signal(SIGINT, handleSIGINT);  // register handler
// Or more robust:
struct sigaction sa = { .sa_handler = handleSIGINT };
sigaction(SIGINT, &sa, NULL);

// Send signal to another process
kill(target_pid, SIGTERM);   // ask it to terminate
kill(target_pid, SIGUSR1);   // user-defined signal
```

**Common signals:**
```
Signal    Default Action    Meaning
SIGTERM   Terminate         Polite request to quit (catchable)
SIGKILL   Terminate         Force kill (CANNOT be caught or ignored)
SIGINT    Terminate         Ctrl+C from terminal
SIGQUIT   Core dump         Ctrl+\ from terminal
SIGSEGV   Core dump         Segmentation fault
SIGCHLD   Ignore            Child process stopped or terminated
SIGALRM   Terminate         Timer alarm expired
SIGUSR1   Terminate         User-defined
SIGUSR2   Terminate         User-defined
SIGPIPE   Terminate         Write to broken pipe
SIGHUP    Terminate         Terminal hangup (daemon reload)
```

### Sockets

Network communication between processes (even on different machines).

```c
// Server
int sock = socket(AF_INET, SOCK_STREAM, 0);
struct sockaddr_in addr = {.sin_family=AF_INET, .sin_port=htons(8080),
                           .sin_addr.s_addr=INADDR_ANY};
bind(sock, (struct sockaddr*)&addr, sizeof(addr));
listen(sock, 10);
int client = accept(sock, NULL, NULL);  // blocks until client connects
read(client, buffer, sizeof(buffer));
write(client, "hello", 5);

// Client
int sock = socket(AF_INET, SOCK_STREAM, 0);
struct sockaddr_in addr = {.sin_family=AF_INET, .sin_port=htons(8080)};
inet_pton(AF_INET, "127.0.0.1", &addr.sin_addr);
connect(sock, (struct sockaddr*)&addr, sizeof(addr));
write(sock, "hi", 2);
read(sock, buffer, sizeof(buffer));
```

---

## Part 6 — Context Switching

When the OS switches from one process to another.

**Real-world analogy:** A surgeon moving between operating rooms. When leaving room A, they document exactly what they've done and what state the patient is in. When entering room B, they read the documentation and pick up exactly where they left off. The surgeon (CPU) can work on multiple patients (processes) by carefully saving and restoring state.

```
Context switch steps:

1. Timer interrupt fires (or process voluntarily yields)
2. CPU switches to kernel mode
3. Save current process's CPU state:
   - All general-purpose registers
   - PC (program counter), SP (stack pointer)
   - FPU/SIMD registers (expensive!)
   - Store in current process's PCB
4. Run scheduler to choose next process
5. Load next process's CPU state:
   - Restore all registers from its PCB
6. Switch page tables (load new process's CR3/TTBR0)
7. Return to user mode, execute new process

Cost:
  - Register save/restore: ~100-200 ns
  - TLB flush (if no ASID support): very expensive
  - Cache pollution: new process's data not in cache → many misses
  - Total: 1-10 µs (1,000-10,000 cycles)

Linux minimizes this:
  - Lazy FPU save (only save FPU state if process used FP instructions)
  - ASID tags TLB entries (no flush needed on modern CPUs)
  - Kernel same-mapped memory (no TLB flush for kernel addresses)
```

---

## Practice Problems

1. What does `fork()` return in the parent process? In the child process? On failure?

2. Why do we need `wait()` after `fork()`? What happens if a parent exits without calling `wait()`?

3. Write pseudocode for a shell that executes: `ls | wc -l`

4. What is copy-on-write in the context of `fork()`? Why is it an optimization?

5. A process is in BLOCKED state. What events can move it to READY state?

---

## Answers

**Problem 1:**
```
fork() return values:
  Parent:  PID of child (positive integer)
  Child:   0
  Failure: -1 (errno set to ENOMEM, EAGAIN, etc.)

Use:
  pid_t p = fork();
  if (p < 0) handle_error();
  else if (p == 0) child_code();
  else parent_code();   // p contains child's PID
```

**Problem 2:**
```
wait() is needed to:
1. Collect child's exit status (prevents zombie accumulation)
2. Block parent until child finishes (synchronization)

If parent exits without wait():
  Child becomes ORPHAN
  Init process (PID 1) adopts it
  Init calls wait() periodically → orphans cleaned up
  No permanent zombie (orphan's PCB cleaned by init)

If parent STAYS ALIVE but never calls wait():
  Child becomes permanent ZOMBIE
  Zombies consume a PCB slot (limited system resource)
  Many zombies → can't create new processes (PCB table full)
  Fix: parent must call wait() or install SIGCHLD handler
```

**Problem 3:**
```c
// Shell executes: ls | wc -l
int pfd[2];
pipe(pfd);

// Fork for ls
if (fork() == 0) {
    close(pfd[0]);
    dup2(pfd[1], STDOUT_FILENO);  // ls stdout → pipe write
    close(pfd[1]);
    execlp("ls", "ls", NULL);
    exit(1);
}

// Fork for wc
if (fork() == 0) {
    close(pfd[1]);
    dup2(pfd[0], STDIN_FILENO);   // wc stdin ← pipe read
    close(pfd[0]);
    execlp("wc", "wc", "-l", NULL);
    exit(1);
}

close(pfd[0]); close(pfd[1]);
wait(NULL); wait(NULL);  // wait for both
```

**Problem 4:**
```
Without COW: fork() copies all parent pages immediately.
  Parent using 1GB: fork() takes 1GB copy = slow!

With COW:
  After fork(), child and parent share same physical pages
  Pages marked read-only for both

  When either process writes to a page:
    Hardware generates a fault (write to read-only page)
    OS copies just that one page (4KB)
    Both processes now have own copy → both marked writable

  If child immediately calls exec():
    exec() replaces address space entirely
    No pages were written → no copies made
    fork() cost ≈ copying page table only (few KB)
    HUGE optimization for fork+exec pattern

Real-world analogy: two colleagues sharing a Google Doc (view only).
When one edits, only then a separate copy is created for them.
```

**Problem 5:**
```
Process moves from BLOCKED to READY when:
  - I/O operation completes (disk read finished, network packet arrived)
  - Lock/mutex released (waited on lock, now available)
  - Semaphore incremented (V operation on semaphore it was waiting on)
  - Signal delivered (kill() sends signal to blocked process)
  - Timer expired (slept for N milliseconds, timer fired)
  - Child process exited (parent waiting in wait())
  - Another process sends message to it (message queue, pipe data)

Note: READY doesn't mean RUNNING immediately.
Process goes to ready queue, scheduler chooses when to run it.
```

---

## References

- Arpaci-Dusseau — *OSTEP* — Chapters 4-6 (Processes), 15 (Address Spaces)
- Silberschatz — *OS Concepts* — Chapter 3
- Stevens & Rago — *Advanced Programming in the UNIX Environment* — Chapters 7-8
- man pages: `man 2 fork`, `man 2 exec`, `man 7 signal`
- Linux source: `kernel/fork.c`, `kernel/exit.c`
