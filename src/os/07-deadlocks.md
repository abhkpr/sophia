# Deadlocks and Classic Synchronization Problems

## When Systems Get Stuck

Deadlock is one of the most insidious problems in concurrent systems. Programs stop making progress, not because of a crash, but because they're all waiting for each other in a cycle. Nothing crashes — things just quietly freeze.

**Real-world analogy:** A four-way stop intersection where every car arrives simultaneously. Each driver is politely waiting for the car to their right to go first. Car A waits for B, B waits for C, C waits for D, D waits for A. Nobody moves. Ever. This is deadlock — each party holds something (the right to go) and waits for something held by the next party.

---

## Part 1 — Deadlock Defined

A set of processes is deadlocked if each process is waiting for an event that only another process in the set can cause.

### Four Necessary Conditions (Coffman, 1971)

ALL four must hold simultaneously for deadlock to occur. Remove any one → no deadlock.

```
1. MUTUAL EXCLUSION
   Resources are non-shareable: only one process can use a resource at a time.
   Example: mutex, printer, database write lock

2. HOLD AND WAIT
   A process holds at least one resource AND waits for additional resources.
   Example: holds file lock, waiting for database lock

3. NO PREEMPTION
   Resources cannot be forcibly taken from a process.
   They must be voluntarily released.
   Example: can't steal a mutex from another thread

4. CIRCULAR WAIT
   There exists a cycle in the wait-for graph:
   P1 waits for P2, P2 waits for P3, ..., Pn waits for P1

Break ANY condition → deadlock impossible.
```

### Resource Allocation Graph

Visualize deadlocks with a directed graph.

```
Nodes:
  ● Process (circle)
  ■ Resource (rectangle, dots inside = instances)

Edges:
  Process → Resource: process is requesting this resource
  Resource → Process: resource is assigned to this process

No deadlock:
  P1 ──request──► R1 ──assigned──► P2

Deadlock (cycle):
  P1 ──request──► R1
  R1 ──assigned──► P2
  P2 ──request──► R2
  R2 ──assigned──► P1
  
  P1 waits for R1, which P2 holds.
  P2 waits for R2, which P1 holds.
  DEADLOCK!
```

---

## Part 2 — Deadlock Prevention

Ensure at least one of the four conditions never holds.

### Break Mutual Exclusion

```
Make resources shareable where possible.
Examples:
  Read-only files: multiple processes can read simultaneously
  Reader-writer locks: many readers OR one writer
  
Cannot eliminate for all resources:
  Printers must be used by one job at a time
  Memory regions needing atomic update require exclusivity
```

### Break Hold and Wait

```
Require processes to request ALL resources at once:
  Request all needed resources before starting.
  If any unavailable: wait with nothing held.

Or: release all resources before requesting more:
  If need new resource and can't get it:
    release everything, wait, then reacquire all

Problems:
  - Poor resource utilization (holding idle resources)
  - May not know all needed resources upfront
  - Starvation possible (can never get all resources simultaneously)
  
Used in: databases (two-phase locking with cautious wait)
```

### Break No Preemption

```
Allow forced resource removal:
  If process P1 holds R1 and requests R2 (unavailable):
    OS preempts R1 from P1
    Gives R1 to whoever needs it
    P1 restarts when both R1 and R2 available

Practical for:
  CPU time (preemptive scheduling does this)
  Memory pages (swap out)
  
Impractical for:
  Printers (can't half-print a document, take it back, resume later)
  Mutexes (inconsistent data state if preempted mid-critical-section)
```

### Break Circular Wait

**Best practical approach: impose an ordering on resources.**

```
Assign each resource type a unique number.
Rule: always acquire resources in increasing order.

Example:
  R1 = file lock (order 1)
  R2 = database lock (order 2)
  R3 = network socket (order 3)

Thread A: must acquire R1, then R3
Thread B: must acquire R1, then R2

Both must acquire R1 before R2 or R3.
Thread B will get R1 first, then R2.
Thread A must wait for R1 (held by B), then gets R1, then R3.
No circular wait possible!

In practice:
  Lock all mutexes in alphabetical order (or by memory address)
  pthread_mutex_lock by address: always lock lower address first
  
  // Lock two mutexes safely:
  if (m1 < m2) {
      pthread_mutex_lock(m1); pthread_mutex_lock(m2);
  } else {
      pthread_mutex_lock(m2); pthread_mutex_lock(m1);
  }
```

---

## Part 3 — Deadlock Avoidance: Banker's Algorithm

The OS dynamically decides whether to grant resource requests based on whether granting them might lead to deadlock.

**Real-world analogy:** A bank that lends money carefully. A customer (process) declares maximum loan needs upfront. Bank checks: if I lend this now, can all customers still eventually be fully funded and repay? If yes (safe state), lend it. If no (unsafe state), make them wait.

### Safe State

A state is **safe** if there exists at least one sequence in which all processes can complete (get all resources, execute, release).

```
Example:
  3 processes, 12 instances of one resource type

  Process   Max Need   Current Hold   Still Needs
    P1          10            5            5
    P2           4            2            2
    P3           9            3            6

  Available = 12 - (5+2+3) = 2

  Try P2: needs 2, available 2 → run P2, it finishes, releases 2
  Available = 2+2 = 4
  
  Try P1: needs 5, available 4 → can't run yet
  Try P3: needs 6, available 4 → can't run yet
  
  Wait, let's reconsider. After P2:
  Available = 4
  Try P1: needs 5 > 4 → nope
  Try P3: needs 6 > 4 → nope
  
  Hmm, we're stuck with P2 done. What if initial state different?
  
  Actually with available=2: try P2 first (needs 2).
  P2 finishes: available = 2+2 = 4
  Try P1: needs 5 > 4 → no
  Try P3: needs 6 > 4 → no
  
  State is UNSAFE if P2 is the only one that can run and
  after P2, neither P1 nor P3 can complete.
  
  This is NOT necessarily a deadlock (P3 might not need 6 more),
  but the OS will say "unsafe" and deny new allocations.
```

### Banker's Algorithm (Dijkstra, 1965)

```
Data structures:
  Available[m]:        available instances of each resource
  Max[n][m]:           maximum demand of each process
  Allocation[n][m]:    current allocation
  Need[n][m]:          Max - Allocation (still needed)

Safety Algorithm:
  Work = Available
  Finish = [false, ..., false]
  
  while (some process i with Finish[i]=false and Need[i] ≤ Work):
    Work += Allocation[i]   // process i finishes, releases
    Finish[i] = true
  
  if all Finish[i] == true: SAFE STATE
  else: UNSAFE STATE

Resource Request Algorithm:
  When process Pi requests Request[i]:
  
  1. If Request[i] > Need[i]: error (requesting more than declared max)
  2. If Request[i] > Available: wait (not enough available)
  3. Tentatively allocate:
       Available -= Request[i]
       Allocation[i] += Request[i]
       Need[i] -= Request[i]
  4. Run safety algorithm
  5. If SAFE: grant request
     If UNSAFE: rollback step 3, make Pi wait
```

**Limitations of Banker's Algorithm:**
```
- Requires processes to declare maximum needs upfront (often unknown)
- Fixed number of processes (no dynamic creation)
- Fixed number of resources (no hardware hot-plug)
- Each resource has multiple identical instances (no differentiation)
- High overhead for every resource request

In practice: most systems don't use Banker's.
Use prevention (lock ordering) or detection+recovery instead.
```

---

## Part 4 — Classic Synchronization Problems

These problems appear in every OS textbook because they capture the essence of concurrent programming challenges. Mastering them gives you the patterns to solve real problems.

### Dining Philosophers Problem

**Setup:** 5 philosophers sit around a circular table. Each has a bowl of spaghetti. Between each pair of adjacent philosophers is ONE chopstick (5 total). To eat, a philosopher needs BOTH adjacent chopsticks. Philosophers alternate thinking and eating.

```
        P0
     /      \
  fork4    fork0
   /            \
 P4              P1
   \            /
  fork3    fork1
     \      /
       P3-P2
          |
        fork2
```

**Naive solution (deadlock!):**
```c
void philosopher(int i) {
    while (true) {
        think();
        pick_up(fork[i]);           // left fork
        pick_up(fork[(i+1) % 5]);   // right fork
        eat();
        put_down(fork[(i+1) % 5]);
        put_down(fork[i]);
    }
}

Deadlock scenario:
  All 5 philosophers simultaneously pick up their LEFT fork.
  All now waiting for right fork (held by right neighbor).
  Circular wait → DEADLOCK.
```

**Solution 1 — Lock ordering:**
```c
void philosopher(int i) {
    int left = i, right = (i+1) % 5;
    int first = min(left, right);   // always pick lower-numbered first
    int second = max(left, right);
    
    think();
    pick_up(fork[first]);   // always lower-numbered first
    pick_up(fork[second]);
    eat();
    put_down(fork[second]);
    put_down(fork[first]);
}
// One philosopher (P4) picks fork4 before fork0
// Others pick their lower fork first
// No circular wait possible!
```

**Solution 2 — Allow at most 4 philosophers at table simultaneously:**
```c
sem_t room;
sem_init(&room, 0, 4);  // max 4 at the table

void philosopher(int i) {
    think();
    sem_wait(&room);           // enter only if < 4 at table
    pick_up(fork[i]);
    pick_up(fork[(i+1)%5]);
    eat();
    put_down(fork[(i+1)%5]);
    put_down(fork[i]);
    sem_post(&room);           // leave table
}
// Pigeonhole principle: 4 philosophers, 5 forks → at least one can eat
```

**Solution 3 — Monitor-based (Hoare's solution):**
```c
typedef enum { THINKING, HUNGRY, EATING } State;
State state[5];
sem_t s[5];  // one per philosopher, initially 0
sem_t mutex; // protects state array

void test(int i) {
    if (state[i] == HUNGRY
        && state[(i+4)%5] != EATING
        && state[(i+1)%5] != EATING) {
        state[i] = EATING;
        sem_post(&s[i]);  // wake this philosopher
    }
}

void pickup(int i) {
    sem_wait(&mutex);
    state[i] = HUNGRY;
    test(i);              // try to start eating
    sem_post(&mutex);
    sem_wait(&s[i]);      // wait if can't eat yet
}

void putdown(int i) {
    sem_wait(&mutex);
    state[i] = THINKING;
    test((i+4)%5);  // maybe left neighbor can now eat
    test((i+1)%5);  // maybe right neighbor can now eat
    sem_post(&mutex);
}
// Starvation-free, deadlock-free!
```

---

### Readers-Writers Problem

**Setup:** Multiple readers can read simultaneously. A writer needs exclusive access.

```
Read operations: any number can proceed in parallel
Write operations: exclusive (no readers OR writers while writing)
```

**Solution 1 — Readers priority (writers may starve):**
```c
int readers = 0;
sem_t mutex = 1;     // protects readers count
sem_t rw_lock = 1;   // exclusive write access

// READER:
sem_wait(&mutex);
readers++;
if (readers == 1)
    sem_wait(&rw_lock);  // first reader locks out writers
sem_post(&mutex);

// *** READ DATA ***

sem_wait(&mutex);
readers--;
if (readers == 0)
    sem_post(&rw_lock);  // last reader allows writers
sem_post(&mutex);

// WRITER:
sem_wait(&rw_lock);    // exclusive access
// *** WRITE DATA ***
sem_post(&rw_lock);

Problem: if readers keep arriving, writers never get access → STARVATION
```

**Solution 2 — Writers priority:**
```c
int readers = 0, writers = 0, waiting_writers = 0;
pthread_mutex_t mtx;
pthread_cond_t can_read, can_write;

// READER:
pthread_mutex_lock(&mtx);
while (writers > 0 || waiting_writers > 0)  // wait for all writers
    pthread_cond_wait(&can_read, &mtx);
readers++;
pthread_mutex_unlock(&mtx);
// *** READ ***
pthread_mutex_lock(&mtx);
readers--;
if (readers == 0) pthread_cond_signal(&can_write);
pthread_mutex_unlock(&mtx);

// WRITER:
pthread_mutex_lock(&mtx);
waiting_writers++;
while (readers > 0 || writers > 0)  // wait for all readers/writers
    pthread_cond_wait(&can_write, &mtx);
waiting_writers--;
writers++;
pthread_mutex_unlock(&mtx);
// *** WRITE ***
pthread_mutex_lock(&mtx);
writers--;
if (waiting_writers > 0) pthread_cond_signal(&can_write);
else pthread_cond_broadcast(&can_read);
pthread_mutex_unlock(&mtx);
```

**Using pthread_rwlock (built-in):**
```c
pthread_rwlock_t rwlock = PTHREAD_RWLOCK_INITIALIZER;

// Reader:
pthread_rwlock_rdlock(&rwlock);
// ... read ...
pthread_rwlock_unlock(&rwlock);

// Writer:
pthread_rwlock_wrlock(&rwlock);
// ... write ...
pthread_rwlock_unlock(&rwlock);
```

---

### Sleeping Barber Problem

**Setup:** Barbershop with 1 barber, 1 barber chair, N waiting chairs. If no customers: barber sleeps. When customer arrives:
- If barber sleeping: wake barber
- If chairs available: sit and wait
- If all chairs full: leave (don't wait)

```c
#define CHAIRS 5
sem_t customers = 0;    // sleeping barber wakes for each
sem_t barber = 0;       // customer waits for barber
sem_t mutex = 1;        // protects waiting count
int waiting = 0;

void barber_thread() {
    while (true) {
        sem_wait(&customers);   // sleep if no customers
        sem_wait(&mutex);
        waiting--;
        sem_post(&barber);      // barber ready for customer
        sem_post(&mutex);
        cut_hair();             // actually cut hair
    }
}

void customer_thread() {
    sem_wait(&mutex);
    if (waiting < CHAIRS) {
        waiting++;
        sem_post(&customers);  // wake barber (or increment)
        sem_post(&mutex);
        sem_wait(&barber);     // wait for barber to be ready
        get_haircut();
    } else {
        sem_post(&mutex);      // no chairs: leave
    }
}
```

---

## Part 5 — Deadlock Detection and Recovery

Rather than prevent or avoid deadlock, let it happen and recover.

```
Detection:
  Maintain resource allocation graph
  Periodically run cycle detection algorithm: O(V²) for single instances
  Or run Banker's-style algorithm for multi-instance resources

When to detect:
  - Every resource request (expensive but immediate)
  - Periodically (e.g., every minute)
  - When CPU utilization falls below threshold (sign of thrashing/deadlock)

Recovery options:
  1. Kill ALL deadlocked processes
     Simple but brutal. All progress lost.
  
  2. Kill ONE process at a time
     Choose victim: lowest priority, most resources held,
     least progress made, most expensive to restart
     
     After each kill, run detection again
     Stop when no deadlock

  3. Resource preemption
     Forcibly take a resource from one process, give to another
     Rollback: process must restart from last checkpoint
     Problems: starvation (same process always chosen as victim)
```

**Ostrich Algorithm:**
```
Pretend deadlock can't happen. Ignore the problem.
Used by: UNIX, Windows, and most real systems

Rationale:
  - Deadlocks rare in practice (system locks designed carefully)
  - Cost of prevention/avoidance > cost of occasional deadlock
  - Deadlock usually resolved by user killing a program
  
  "If we never look at ostriches with their heads in the sand,
   maybe they'll never be a problem"
   
This is pragmatic, not lazy! Full avoidance has real costs.
```

---

## Practice Problems

1. Given: P1 holds R1, requests R2. P2 holds R2, requests R1. Draw the resource allocation graph. Is this a deadlock?

2. Which of the four Coffman conditions is broken by:
   a) Allowing only one process to request resources at a time
   b) Using read-write locks instead of exclusive locks for reads
   c) Always acquiring locks in alphabetical order
   d) OS can preempt memory from a process

3. Why does the naive dining philosophers solution deadlock? Write the fix using lock ordering.

4. In the readers-writers problem with readers priority, how can you modify it to prevent writer starvation?

---

## Answers

**Problem 1:**
```
Resource Allocation Graph:
  P1 ──request──► R2
  R2 ──assigned──► P2
  P2 ──request──► R1
  R1 ──assigned──► P1

Cycle: P1 → R2 → P2 → R1 → P1
This IS a deadlock.

All four conditions:
  1. Mutual exclusion: R1 and R2 are exclusive resources
  2. Hold and wait: P1 holds R1 and waits for R2
  3. No preemption: neither resource can be taken
  4. Circular wait: P1 waits for P2, P2 waits for P1
```

**Problem 2:**
```
a) "Only one process can request resources at a time"
   → Breaks HOLD AND WAIT: process must request everything atomically,
     releasing all held resources while waiting

b) "Read-write locks for reads"
   → Breaks MUTUAL EXCLUSION: readers can share the resource,
     eliminating exclusivity for read operations

c) "Always acquire locks in alphabetical order"
   → Breaks CIRCULAR WAIT: total ordering prevents cycles
     (can't have A wait for B and B wait for A if A < B)

d) "OS can preempt memory"
   → Breaks NO PREEMPTION: resources can be forcibly taken
```

**Problem 3:**
```
Naive deadlock cause:
  Each philosopher picks left fork, waits for right.
  All 5 hold exactly 1 fork simultaneously.
  Circular: P0 waits for P1's left, P1 waits for P2's left, ...P4 waits for P0's left.

Fix with lock ordering:
  void philosopher(int i) {
      int left = i;
      int right = (i+1) % 5;
      // Always pick lower-numbered fork first
      int first  = (left < right) ? left  : right;
      int second = (left < right) ? right : left;
      
      think();
      sem_wait(&forks[first]);   // lower number first
      sem_wait(&forks[second]);  // higher number second
      eat();
      sem_post(&forks[second]);
      sem_post(&forks[first]);
  }
  
  For P0: left=0, right=1 → pick fork[0] then fork[1]
  For P1: left=1, right=2 → pick fork[1] then fork[2]
  For P4: left=4, right=0 → pick fork[0] then fork[4] (0 < 4!)
  
  P4's order is reversed! Now P4 tries to pick fork[0] first,
  which P0 might have. But P0 waits for fork[0] → P0 gets it first.
  
  No circular wait possible → no deadlock.
```

**Problem 4:**
```
Preventing writer starvation in readers-priority solution:

Add a mutex that writers acquire BEFORE trying rw_lock.
When a writer arrives, it takes this mutex.
New readers must also take this mutex before entering.
Readers can't pile up once a writer is waiting.

int readers = 0;
sem_t mutex = 1;      // protect readers count
sem_t rw_lock = 1;    // read-write exclusion
sem_t turn = 1;       // prevents new readers from piling up

// READER:
sem_wait(&turn);       // queue behind waiting writers!
sem_wait(&mutex);
readers++;
if (readers == 1) sem_wait(&rw_lock);
sem_post(&mutex);
sem_post(&turn);       // release turn (only needed briefly)
// READ
sem_wait(&mutex);
readers--;
if (readers == 0) sem_post(&rw_lock);
sem_post(&mutex);

// WRITER:
sem_wait(&turn);       // get in line
sem_wait(&rw_lock);    // wait for readers to finish
sem_post(&turn);
// WRITE
sem_post(&rw_lock);

Now writers "jump in line" by taking turn.
New readers can't start while a writer is waiting.
Fair ordering between readers and writers.
```

---

## References

- Dijkstra, E.W. — *Cooperating Sequential Processes* (1965) — original semaphore paper
- Arpaci-Dusseau — *OSTEP* — Chapters 31-32
- Silberschatz — *OS Concepts* — Chapter 8 (Deadlocks)
- Coffman et al. (1971) — *System Deadlocks* — original four conditions paper
- Tanenbaum — *Modern OS* — Chapter 6
