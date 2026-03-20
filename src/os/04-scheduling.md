# CPU Scheduling

## The Art of Deciding Who Runs Next

When multiple processes are ready to run and there's only one CPU, the OS must decide: who runs next? For how long? This is CPU scheduling — one of the most studied problems in OS design.

**Real-world analogy:** An emergency room with multiple patients waiting and limited doctors. The triage nurse (scheduler) decides who gets treated first:
- Life-threatening cases first (priority scheduling)
- First come, first served for similar cases (FIFO)
- Short procedures done quickly to keep the queue moving (SJF)
- No patient waits forever no matter how minor (aging/fairness)

The optimal strategy depends on the goals: minimize wait time? maximize throughput? ensure fairness? These goals often conflict.

---

## Part 1 — Scheduling Concepts

### What the Scheduler Controls

```
Ready Queue: list of processes waiting to use CPU

FIFO order: [P1] [P2] [P3] [P4] [P5]
            head                   tail

Scheduler picks from ready queue based on:
  - Priority
  - Time waited
  - Estimated remaining execution time
  - Or complex combinations of all of the above

Then dispatcher:
  1. Context switch to selected process
  2. Switch to user mode
  3. Jump to correct location in user program
```

### Preemptive vs Non-Preemptive

```
Non-preemptive (cooperative):
  Once a process gets the CPU, it runs until:
    - It voluntarily gives up CPU (yield, sleep, I/O wait)
    - It terminates
  
  Pros: simple, no race conditions from scheduler
  Cons: one bad process can freeze the system
  Examples: early Mac OS, Windows 3.1, some embedded RTOS

Preemptive:
  OS can forcibly remove CPU from a process at any time
  Typically via timer interrupt
  
  Pros: fair, responsive, handles infinite loops
  Cons: need synchronization (process can be interrupted anytime)
  Examples: Linux, Windows NT+, macOS, all modern systems
```

### Scheduling Metrics

```
Turnaround Time:
  Time from job submission to job completion
  Turnaround = Completion Time - Arrival Time
  Goal: MINIMIZE

Response Time:
  Time from job submission to first response
  Response = First Run Time - Arrival Time
  Critical for interactive systems (keyboard feels snappy)

Throughput:
  Jobs completed per unit time
  Goal: MAXIMIZE

CPU Utilization:
  Fraction of time CPU is doing useful work (not idle)
  Goal: MAXIMIZE (typically 40-90% in practice)

Fairness:
  Each process gets its fair share of CPU
  Goal: no starvation (process never gets CPU)

Waiting Time:
  Total time spent in ready queue
  Goal: MINIMIZE
```

---

## Part 2 — Scheduling Algorithms

### FIFO (First In, First Out) / FCFS

The first process to arrive gets the CPU first.

```
Example: 3 processes arrive at t=0
Process  Burst Time
P1       24
P2        3
P3        3

Timeline: [P1 (24)][P2 (3)][P3 (3)]
           0        24      27      30

Waiting times: P1=0, P2=24, P3=27
Average waiting: (0+24+27)/3 = 17

Convoy effect: short jobs stuck behind long job
```

**Change order:**
```
If P2, P3 arrive at t=0 but P1 at t=1 (SJF solves this):
[P2(3)][P3(3)][P1(24)]
0       3      6       30

Waiting times: P2=0, P3=3, P1=6
Average waiting: (0+3+6)/3 = 3   (5.7× better!)
```

### SJF (Shortest Job First)

Run the process with shortest burst time next.

```
Provably optimal for minimizing average turnaround time.
(When all jobs arrive simultaneously)

Process  Arrival  Burst
P1         0        8
P2         0        4
P3         0        9
P4         0        5

SJF order: P2(4), P4(5), P1(8), P3(9)
Timeline:  [P2][P4 ][P1      ][P3       ]
           0    4    9         17        26

Waiting: P2=0, P4=4, P1=9, P3=17
Average: (0+4+9+17)/4 = 7.5

FIFO order (P1,P2,P3,P4):
Waiting: P1=0, P2=8, P3=12, P4=21
Average: (0+8+12+21)/4 = 10.25

SJF wins!

Problem: How do you know the burst time in advance?
Usually you DON'T. Prediction using history:
  estimated_burst(n+1) = α × actual_burst(n) + (1-α) × estimated_burst(n)
  Exponential average (α = 0.5 typical)
```

### SRTF (Shortest Remaining Time First) — Preemptive SJF

When a new job arrives, if its burst is shorter than remaining time of current job, preempt.

```
Process  Arrival  Burst
P1          0        8
P2          1        4
P3          2        9
P4          3        5

t=0: P1 starts (only one)
t=1: P2 arrives with burst=4 < P1 remaining=7 → preempt!
t=5: P2 done. P4 arrives at t=3 with burst=5 = P1 remaining=7
     P4 is shorter → P4 runs
t=10: P4 done. P1 remaining=7, P3 burst=9 → P1 runs
t=17: P1 done. P3 runs
t=26: P3 done.

Timeline:
[P1][P2  ][P4  ][P1         ][P3          ]
0    1     5     10           17            26

Average turnaround:
P1: 17-0=17, P2: 5-1=4, P3: 26-2=24, P4: 10-3=7
Average: (17+4+24+7)/4 = 13

Better than SJF for mixed arrivals!
```

### Round Robin (RR)

Each process gets a small fixed time slice (quantum). After quantum expires, process is preempted and goes to back of queue.

**Real-world analogy:** A round table discussion where each person gets exactly 2 minutes to speak, then the turn moves to the next person. Everyone gets heard, no one monopolizes.

```
Quantum = 4

Process  Burst
P1         24
P2          3
P3          3

Timeline (RR with q=4):
[P1(4)][P2(3)][P3(3)][P1(4)][P1(4)][P1(4)][P1(4)][P1(4)]
0       4      7      10     14     18     22     26     30

Waiting times:
P1: 0 + (10-4) + (14-8) + ... = complicated
P2: 4 - 0 = 4  (wait from t=0 to first run at t=4)
P3: 7 - 0 = 7

Average response time for RR much better than FCFS!
(P2 responds at t=4, not t=24)
```

**Choosing quantum size:**
```
Too small (q=1):
  Lots of context switches → overhead dominates
  If context switch costs 1ms and q=1ms → 50% CPU wasted on overhead!

Too large (q=∞):
  Degenerates to FIFO
  Long response time for short jobs

Sweet spot: 10-100ms in practice
  10-20ms for interactive workloads
  Larger for batch systems

Rule of thumb: quantum should be > 80% of actual CPU bursts
```

### Priority Scheduling

Each process has a priority. Highest priority runs first.

```
Process  Priority  Burst
P1          3        10
P2          1         1   ← highest priority (1 = highest)
P3          4         2
P4          5         1
P5          2         5

Execution order: P2, P5, P1, P3, P4

Common priority assignments:
  Static: set at creation, never changes
  Dynamic: changes based on behavior, time waited

Starvation problem:
  Low priority process might never run if high priority keep arriving

Solution: Aging
  Gradually increase priority of waiting processes
  After waiting T seconds: priority += 1
  Eventually even low priority process runs
```

### Multilevel Queue Scheduling

Different queues for different types of processes. Each queue has its own scheduling algorithm.

```
Priority 1 (highest):  ┌───────────────────┐
  System processes     │ Real-time FIFO     │
                       └───────────────────┘
Priority 2:            ┌───────────────────┐
  Interactive processes│ Round Robin q=8ms │
                       └───────────────────┘
Priority 3:            ┌───────────────────┐
  Batch processes      │ Round Robin q=16ms│
                       └───────────────────┘
Priority 4 (lowest):   ┌───────────────────┐
  Background/idle      │ FCFS              │
                       └───────────────────┘

Higher queues have absolute priority over lower.
Process in queue 3 only runs if queues 1 and 2 empty.
```

### MLFQ (Multilevel Feedback Queue)

The best general-purpose scheduler. Processes can move between queues based on behavior.

**Real-world analogy:** Airline check-in. You start in the regular queue. If you're frequently traveling, you earn status and move to the priority queue. If a "first class" passenger is causing delays, they can be deprioritized. The system learns and adapts.

```
Rules:
  1. If Priority(A) > Priority(B): A runs
  2. If Priority(A) == Priority(B): A and B run in RR
  3. New job: enters highest priority queue (Q0)
  4. If job uses full quantum: demote to next queue
  5. If job gives up CPU before quantum: stay in same queue
  6. After time period S: boost ALL jobs to highest queue (prevent starvation)

Queue   Quantum   Interpretation
Q0      8ms       Interactive (likely short bursts)
Q1      16ms      Medium jobs
Q2      FIFO      Long batch jobs

How a job's behavior determines placement:
  Short interactive (< 8ms burst): stays in Q0 forever
  Medium job (8-16ms bursts):      demotes to Q1
  Long CPU-bound job:              demotes to Q2

Why this works:
  Short jobs (interactive) naturally stay at high priority
  Long jobs naturally drift to lower queues
  No need to know burst time in advance!
  
  Gaming: some jobs artificially yield just before quantum expires
  Solution: rule 4 tracks total CPU time at each level, not just one quantum
```

---

## Part 3 — Linux CFS (Completely Fair Scheduler)

The actual scheduler used in Linux since 2007.

```
Goal: every process gets equal CPU time

Core concept: virtual runtime (vruntime)
  vruntime = actual CPU time spent × (1/weight)
  Higher priority → smaller weight → vruntime increases more slowly
  → high priority process always has smallest vruntime
  → gets selected first

Data structure: Red-black tree ordered by vruntime
  Leftmost node = process with smallest vruntime = runs next
  O(log n) operations for insert/delete

How it works:
  All processes in RB-tree sorted by vruntime
  Scheduler always picks leftmost (smallest vruntime)
  Runs it for a time slice
  Updates vruntime, reinserts in tree
  
  Process with least CPU time always runs next
  → perfectly fair over time

Time slice calculation:
  target_latency = 20ms (try to run each process once in 20ms)
  min_granularity = 4ms (minimum time slice, prevents too many switches)
  
  if n processes: time_slice = max(target/n, min_granularity)
  
  With 4 processes: 20/4 = 5ms each
  With 100 processes: 20/100 = 0.2ms → clamped to 4ms each
```

**Nice values (priority in Linux):**
```
nice value: -20 (highest priority) to +19 (lowest)
Default: 0

Higher nice = nicer to others = lower priority
Lower nice  = less nice = higher priority

Shell command:
  nice -n 10 ./long_job    # lower priority
  nice -n -5 ./important   # higher priority (need root for negative)
  renice 5 -p 1234         # change running process's nice value
```

---

## Part 4 — Real-Time Scheduling

For systems with timing deadlines: robotics, audio processing, flight control.

```
Real-time task properties:
  Period (T): task repeats every T milliseconds
  Execution time (C): CPU time needed per period
  Deadline (D): must complete within D ms of release

Utilization: U = C/T
  Sum of all utilizations must be ≤ 1.0 (100% CPU)

Rate Monotonic (RM):
  Static priority: shorter period → higher priority
  Provably optimal for static priority assignment
  If sum of C/T ≤ 0.693 (ln 2): schedulable guaranteed
  
  Example:
    Task 1: C=1, T=4  (runs every 4ms, takes 1ms)
    Task 2: C=2, T=6  (runs every 6ms, takes 2ms)
    U = 1/4 + 2/6 = 0.25 + 0.33 = 0.58 < 0.693 → schedulable!

Earliest Deadline First (EDF):
  Dynamic priority: closest deadline → highest priority
  Optimal: can schedule any feasible task set
  If sum of C/T ≤ 1.0: schedulable guaranteed
```

---

## Practice Problems

1. Given processes: P1 (burst=10, arrival=0), P2 (burst=1, arrival=1), P3 (burst=2, arrival=2). Calculate average turnaround time for FCFS, SJF (non-preemptive), and RR (q=4).

2. Why does RR have better response time but worse turnaround time than FCFS?

3. A MLFQ has queues Q0 (q=8ms) and Q1 (q=16ms). A process has bursts of: 5ms, 9ms, 3ms, 20ms. Trace its path through the queues.

4. What is the starvation problem with priority scheduling? How does aging solve it?

---

## Answers

**Problem 1:**
```
FCFS (arrival order: P1, P2, P3):
Timeline: [P1: 0-10][P2: 10-11][P3: 11-13]
Turnaround: P1=10-0=10, P2=11-1=10, P3=13-2=11
Average: (10+10+11)/3 = 10.33

SJF non-preemptive:
At t=0: only P1 ready → run P1 (t=0-10)
At t=10: P2(1), P3(2) both ready → run P2 (shorter)
Timeline: [P1: 0-10][P2: 10-11][P3: 11-13]
Same as FCFS in this case (P1 can't be preempted)
Average: 10.33

SRTF (preemptive SJF):
t=0: P1 runs
t=1: P2 arrives (burst=1) < P1 remaining(9) → preempt!
t=2: P2 done. P3 arrives (burst=2) < P1 remaining(9) → P3 runs
t=4: P3 done. P1 remaining=9 → P1 runs
t=13: P1 done.
Timeline: [P1:0-1][P2:1-2][P3:2-4][P1:4-13]
Turnaround: P1=13-0=13, P2=2-1=1, P3=4-2=2
Average: (13+1+2)/3 = 5.33  (much better!)

RR q=4:
Timeline: [P1:0-4][P2:4-5][P3:5-7][P1:7-11][P1:11-13*]
Wait, P2 only needs 1ms even though quantum is 4:
[P1:0-4][P2:4-5][P3:5-7][P1:7-11][P1:11-13]

Actually P2 arrives at t=1, P3 at t=2, so order at t=4:
ready queue = [P2, P3, P1_remaining]
[P1:0-4][P2:4-5][P3:5-7][P1:7-11][P1:11-13]
Turnaround: P1=13, P2=5-1=4, P3=7-2=5
Average: (13+4+5)/3 = 7.33
```

**Problem 2:**
```
RR response time is better because:
  Every process runs within q × n_processes time
  With q=4, 5 processes: max wait = 20ms before first run
  FCFS: last process waits for all others to complete

RR turnaround is worse because:
  Short jobs that would finish quickly in FCFS
  are interrupted and must wait for round-robin turns
  
  Example: P1=24ms, P2=3ms, P3=3ms
  FCFS turnaround: 24, 27, 30 (P2 done quickly at 27)
  RR q=4: P2 first runs at t=4, finishes at t=7 (much later!)
  
  Tradeoff: RR optimizes response time, hurts turnaround
  Interactive systems prefer response time (feels faster)
  Batch systems prefer turnaround (total throughput)
```

**Problem 3:**
```
MLFQ trace:

Burst 1: 5ms
  Enters Q0, runs 5ms, doesn't use full 8ms quantum
  → stays in Q0

Burst 2: 9ms
  Runs 8ms in Q0, still needs 1ms
  Used full quantum → demoted to Q1
  Runs remaining 1ms in Q1, gives up CPU

Burst 3: 3ms
  If stayed in Q1: runs 3ms (less than 16ms quantum) → stays Q1
  With "priority boost" (after time period S): back to Q0
  Assuming no boost: runs in Q1, finishes in 3ms

Burst 4: 20ms
  In Q1, runs 16ms (full quantum) → demoted to Q2 (FIFO)
  Runs remaining 4ms in Q2

Without boost: process drifts to lowest queue
With boost: periodically returns to Q0 (prevents starvation)
```

**Problem 4:**
```
Starvation:
  Low priority process P (priority=10) is ready
  High priority processes (priority=1,2,3) keep arriving
  P never gets CPU — "starved"
  
  Real scenario: background backup job never runs during busy day
  Process waits hours (even days) for CPU — unacceptable

Aging solution:
  Every T seconds a process waits without running: priority += 1
  
  Initially: P has priority 10 (low)
  After waiting 5 minutes: priority = 9
  After 10 minutes: priority = 8
  After 50 minutes: priority = 0 (highest!)
  
  Eventually, P's priority rises above even new high-priority arrivals
  Guarantees every process eventually runs
  
  After running: priority reset to original value
```

---

## References

- Arpaci-Dusseau — *OSTEP* — Chapters 7-10 (Scheduling)
- Silberschatz — *OS Concepts* — Chapter 5
- Linux CFS — [kernel.org: CFS scheduler](https://www.kernel.org/doc/html/latest/scheduler/sched-design-CFS.html)
- Real-time scheduling — Liu & Layland (1973) paper on RM scheduling
