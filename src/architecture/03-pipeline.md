# CPU Pipeline

## Making the CPU Work Faster

A non-pipelined CPU executes one instruction completely before starting the next. If each instruction takes 5 steps and each step takes 1ns, throughput is 1 instruction per 5ns.

**Real-world analogy:** An automobile assembly line. Without pipelining, one car must be completely built before starting the next — only one car uses the factory at a time. With pipelining, as car 1 moves from welding to painting, car 2 enters welding. Multiple cars are being built simultaneously at different stages.

---

## Part 1 — Classic 5-Stage Pipeline

The standard RISC pipeline has 5 stages.

```
Stage  Name     What happens
─────────────────────────────────────────────
IF     Fetch    Read instruction from memory at PC address
ID     Decode   Determine what instruction it is; read registers
EX     Execute  ALU performs computation
MEM    Memory   Load/store data from/to memory
WB     Writeback Store result back to register file
```

### Pipeline Execution Timeline

Without pipeline (sequential):
```
Clock:   1  2  3  4  5  6  7  8  9  10  11  12  13  14  15
Instr1: IF ID EX ME WB
Instr2:              IF ID EX ME WB
Instr3:                           IF ID EX ME  WB
3 instructions take 15 clock cycles
```

With pipeline (5-stage):
```
Clock:   1  2  3  4  5  6  7  8  9
Instr1: IF ID EX ME WB
Instr2:    IF ID EX ME WB
Instr3:       IF ID EX ME WB
3 instructions take 7 clock cycles!
After filling pipeline: 1 instruction completes per clock cycle
```

**Speedup = n × k / (k + n - 1)**
where n = instructions, k = pipeline stages

For large n: speedup ≈ k (one instruction per clock, k times faster)

### Pipeline Stages in Detail

```
┌────────┐  ┌────────┐  ┌────────┐  ┌────────┐  ┌────────┐
│   IF   │  │   ID   │  │   EX   │  │  MEM   │  │   WB   │
│        │  │        │  │        │  │        │  │        │
│ PC→Mem │→│Reg Read│→│  ALU   │→│ D-Cache│→│Reg Write│
│Inst Mem│  │ Decode │  │        │  │        │  │        │
└────────┘  └────────┘  └────────┘  └────────┘  └────────┘
     ↓            ↓           ↓           ↓
 IF/ID reg   ID/EX reg   EX/MEM reg  MEM/WB reg
 (pipeline   (pipeline   (pipeline   (pipeline
  register)   register)   register)   register)
```

**Pipeline registers** hold the output of each stage between clock edges. This allows each stage to work on a different instruction simultaneously.

---

## Part 2 — Hazards

Pipeline hazards prevent the next instruction from executing in the next clock cycle.

### Structural Hazard

Two instructions need the same hardware resource simultaneously.

```
Example: Only one memory unit, and instruction 1 needs data memory
while instruction 5 needs instruction memory.

Solution: Separate instruction cache and data cache (Harvard architecture)
          or stall the pipeline
```

### Data Hazard

An instruction depends on the result of a previous instruction still in the pipeline.

```
ADD x1, x2, x3     ; writes x1 in WB stage (cycle 5)
SUB x4, x1, x5     ; reads x1 in ID stage (cycle 3) ← HAZARD!
                    ; x1 not written yet when SUB reads it!
```

**Visualization:**
```
Clock:    1   2   3   4   5   6   7
ADD:     IF  ID  EX  ME  WB
SUB:         IF  ID  EX  ME  WB
                  ↑
                SUB reads x1 here (cycle 3)
                but ADD writes x1 in cycle 5
                SUB gets OLD value of x1!
```

**Solution 1 — Stalling (inserting bubbles):**
```
Clock:    1   2   3   4   5   6   7   8   9
ADD:     IF  ID  EX  ME  WB
SUB:         IF  ID  --  --  EX  ME  WB
                      ↑   ↑
                   NOP NOP  (stalls — pipeline bubbles)
Delay: 2 cycles wasted
```

**Solution 2 — Forwarding (Data Forwarding/Bypassing):**

Instead of waiting for WB, forward the result directly from EX or MEM output.

```
Clock:    1   2   3   4   5   6   7
ADD:     IF  ID  EX  ME  WB
SUB:         IF  ID  EX  ME  WB
                      ↑↑
              ADD's EX result forwarded directly to SUB's EX input!
              No stall needed!
```

```
Forwarding paths:
EX/MEM → EX input:   result available 1 cycle after EX (most common)
MEM/WB → EX input:   result available 2 cycles after EX
MEM/WB → MEM input:  for load-use hazard

Hardware: Forwarding unit compares destination register of previous
          instructions with source registers of current instruction.
          If match, multiplexer selects forwarded value.
```

**Load-Use Hazard (unavoidable 1-cycle stall):**
```
LW   x1, 0(x2)     ; loads x1 from memory
ADD  x3, x1, x4    ; uses x1 immediately

The load result isn't available until end of MEM stage.
ADD needs it at start of EX stage.
Even with forwarding, 1 cycle stall is unavoidable.

Clock:    1   2   3   4   5   6   7   8
LW:      IF  ID  EX  ME  WB
ADD:         IF  ID  --  EX  ME  WB
                      ↑
                   1 stall cycle (unavoidable)
                   MEM→EX forwarding: LW result forwarded from MEM output
```

**Compiler solution — instruction scheduling:**
```c
// C code:
int a = arr[0] + arr[1];

// Naive assembly: load-use hazard
LW   x1, 0(x10)    ; load arr[0]
LW   x2, 4(x10)    ; load arr[1]
ADD  x3, x1, x2    ; a = arr[0] + arr[1]

// Scheduled: move independent instruction between loads
LW   x1, 0(x10)    ; load arr[0]
LW   x2, 4(x10)    ; load arr[1] — independent of x1, no hazard
// compiler puts something else here to fill stall slot
ADD  x3, x1, x2    ; x1 available now (2 cycles after LW)
```

### Control Hazard (Branch Hazard)

The pipeline doesn't know which instruction to fetch next after a branch.

```
BEQ  x1, x2, target    ; branch if equal

Clock:    1   2   3   4   5
BEQ:     IF  ID  EX  ME  WB
???:         IF  ID  EX  ME   ← What instruction goes here?
???:             IF  ID  EX   ← And here?
                      ↑
              Branch target known after EX (cycle 3)
              2 instructions already fetched after branch!
```

**Solution 1 — Stall (flush if wrong):**
Insert 2 NOPs after every branch → 2-cycle penalty per branch.
With 20% branch frequency: 20% × 2 = 40% overhead → 1.4× slowdown.

**Solution 2 — Branch Prediction:**
Guess which way the branch goes, start fetching from predicted path.
If wrong: flush incorrectly fetched instructions (branch misprediction penalty).
If right: no penalty.

---

## Part 3 — Branch Prediction

Modern CPUs achieve >95% prediction accuracy.

### Static Prediction

Always predict based on a fixed rule. No runtime information.

```
Predict Not Taken:  always fetch PC+4
  Correct for: forward branches (if-statements that usually don't branch)
  Wrong for:   backward branches (loops that usually DO branch back)

Predict Taken:      always fetch branch target
  Correct for: loop back-edges
  Wrong for:   forward if-statements

BTFN (Backward Taken, Forward Not Taken):
  Backward branch (negative offset): predict taken  → loops
  Forward branch (positive offset):  predict not taken → if-statements
  ~65-75% accuracy
```

### Dynamic Prediction — Branch History Table

```
1-bit predictor:
  Each branch has 1-bit entry: last outcome (T/NT)
  Predict based on last outcome

Problem: loop of 10 iterations always mispredicts first and last iteration:
  T T T T T T T T T NT T T T T T ...
                          ↑ mispredicts NT, then T (2 misses per loop)

2-bit predictor (saturating counter):
  State machine: Strongly Not Taken ← Weakly NT ← Weakly Taken → Strongly Taken
  Must be wrong TWICE to change prediction

  States:
  00 = Strongly Not Taken (predict NT)
  01 = Weakly Not Taken   (predict NT)
  10 = Weakly Taken       (predict T)
  11 = Strongly Taken     (predict T)

  Transition: Taken → increment; Not Taken → decrement (saturate at 0,3)

  Loop example: after warmup, all iterations predict T → only 1 miss per loop!
```

### Tournament Predictor (Modern CPUs)

```
Uses multiple predictors and a meta-predictor to choose between them:

  Global predictor:  uses global branch history
  Local predictor:   uses per-branch history
  Meta-predictor:    chooses which one was more accurate recently

Result: 95-99% accuracy on typical workloads
```

### Branch Target Buffer (BTB)

Stores the target address of previously seen branches.

```
Without BTB:
  Fetch branch instruction → decode → compute target → fetch target
  2-3 cycle penalty even for correctly predicted taken branches

With BTB:
  Hash PC → lookup BTB → if hit, fetch from stored target immediately
  0-cycle penalty for correctly predicted taken branches!

BTB stores: {PC → predicted target}
On hit: start fetching from BTB entry's target
On miss or wrong: flush and refetch (misprediction penalty)
```

---

## Part 4 — Superscalar Execution

Execute multiple instructions simultaneously.

### In-Order Superscalar

Fetch and decode multiple instructions per cycle, execute in order.

```
2-wide in-order pipeline:
Cycle 1: Fetch instr 1 and 2
Cycle 2: Decode instr 1 and 2
         Fetch instr 3 and 4
Cycle 3: Execute instr 1 and 2 (if no dependency)
         Decode instr 3 and 4
...

If instr 2 depends on instr 1: must stall instr 2
Throughput: up to 2 instructions per cycle (IPC ≤ 2)
```

### Out-of-Order (OOO) Execution

Execute instructions in any order, as long as data dependencies allow.

**Real-world analogy:** A restaurant kitchen. Orders (instructions) come in sequence, but the chef doesn't wait for the slow pizza to finish before starting the fast salad. Different dishes (instructions) are prepared in parallel based on ingredient availability (data availability), not order received.

```
C code:
  a = b + c;          // ADD — depends on b,c
  d = e - f;          // SUB — INDEPENDENT of ADD!
  g = a * d;          // MUL — depends on both ADD and SUB

In-order execution:
  Cycle 1: ADD (b+c)
  Cycle 2: SUB (e-f)  — waits for ADD even though independent
  Cycle 3: MUL (a*d)

Out-of-order execution:
  Cycle 1: ADD, SUB (parallel! they're independent)
  Cycle 2: MUL (waits for both results)
```

**OOO pipeline stages:**
```
Fetch → Decode → Rename → Issue Queue → Execute → Commit

Rename (Register Renaming):
  Eliminates false dependencies (WAR, WAW hazards)
  Maps architectural registers (x1-x31) to physical registers (100+)

Issue Queue (Reservation Stations):
  Instructions wait here until operands ready
  When all operands available: issue to execution units

Execute:
  Multiple execution units: ALU, Load/Store, FPU, etc.
  Instructions execute as soon as operands ready

Reorder Buffer (ROB):
  Tracks in-flight instructions in program order
  Ensures correct state after exceptions/branch mispredictions
  Commits instructions in order (even if executed out of order)
```

---

## Part 5 — Modern CPU Microarchitecture

Intel Core / AMD Zen pipeline (simplified):

```
                    Frontend
┌───────────────────────────────────────────────┐
│  Branch Predictor                             │
│  ┌─────────┐  ┌─────────┐  ┌──────────────┐  │
│  │  Fetch  │→ │  Decode │→ │  Rename/     │  │
│  │ (16-32B │  │(complex │  │  Allocate    │  │
│  │ /cycle) │  │ x86 →   │  │  (map regs)  │  │
│  └─────────┘  │ µops)   │  └──────────────┘  │
│               └─────────┘                    │
└──────────────────────────────────────────────┘
                    Backend
┌───────────────────────────────────────────────┐
│  ┌──────────────────────────────────────────┐ │
│  │       Reservation Stations / Scheduler   │ │
│  └────┬──────┬──────┬──────┬──────┬────────┘ │
│       │      │      │      │      │          │
│    ┌──┴─┐ ┌──┴─┐ ┌──┴─┐ ┌──┴─┐ ┌──┴─┐      │
│    │ALU0│ │ALU1│ │AGU │ │Load│ │ FP │      │
│    └────┘ └────┘ └────┘ └────┘ └────┘      │
│                                             │
│  ┌──────────────────────────────────────┐   │
│  │     Reorder Buffer (ROB ~256 entries)│   │
│  │     Commit in order                  │   │
│  └──────────────────────────────────────┘   │
└────────────────────────────────────────────-┘

Key metrics:
  Width: 4-6 µops decoded per cycle
  ROB size: 256-512 entries
  Issue ports: 6-10 execution ports
  Branch misprediction penalty: 15-20 cycles
  Peak IPC: 4-8 instructions per cycle
```

---

## Part 6 — Performance Analysis

### Amdahl's Law

If fraction f of a program can be sped up by factor S:
```
Speedup = 1 / ((1-f) + f/S)

Example: 80% of code sped up 10×:
Speedup = 1 / (0.2 + 0.8/10) = 1 / (0.2 + 0.08) = 1/0.28 ≈ 3.57×

Not 10× because the remaining 20% still takes the same time.

Implication: even infinite speedup of 80% gives max 5× speedup
  Speedup(∞) = 1/(1-0.8) = 1/0.2 = 5×
```

### CPU Performance Equation

```
CPU Time = Instructions × CPI × Clock Period
         = Instructions × CPI / Clock Frequency

Where:
  Instructions = instruction count (depends on ISA and compiler)
  CPI          = cycles per instruction (depends on architecture)
  Clock Freq   = cycles per second (depends on implementation)

Example:
  Program: 10^9 instructions
  CPI: 1.5 (due to stalls, cache misses)
  Frequency: 3 GHz = 3 × 10^9 cycles/second

  CPU Time = 10^9 × 1.5 / (3×10^9) = 0.5 seconds

To improve performance:
  - Reduce instructions: better algorithm, better compiler
  - Reduce CPI: better pipeline, caching, OOO execution
  - Increase frequency: better manufacturing process
```

---

## Practice Problems

1. A 5-stage pipeline runs at 2 GHz. What is the maximum throughput?

2. Given this sequence, identify all hazards:
   ```asm
   LW   x1, 0(x2)
   ADD  x3, x1, x4
   SUB  x5, x3, x6
   AND  x7, x1, x8
   ```

3. A program has 10^8 instructions, 30% are branches. Branch misprediction penalty is 10 cycles. Misprediction rate is 5%. What is the effective CPI if base CPI = 1?

4. With forwarding, which of these still need a stall?
   - `ADD x1, x2, x3` followed by `ADD x4, x1, x5`
   - `LW  x1, 0(x2)` followed by `ADD x4, x1, x5`

---

## Answers

**Problem 1:**
```
2 GHz = 2×10^9 cycles/second
In steady state: 1 instruction per cycle
Maximum throughput: 2×10^9 instructions/second = 2 GIPS (Giga Instructions Per Second)
```

**Problem 2:**
```
LW   x1, 0(x2)     ; writes x1
ADD  x3, x1, x4    ; reads x1 → Load-Use hazard! 1 stall cycle
                   ;             can't forward in time
SUB  x5, x3, x6   ; reads x3 → EX-EX hazard, but forwarding handles it
AND  x7, x1, x8   ; reads x1 → MEM/WB → EX forward, no stall needed
```

**Problem 3:**
```
Mispredictions per instruction = 0.30 × 0.05 = 0.015
Extra cycles from mispredictions = 0.015 × 10 = 0.15 cycles/instruction
Effective CPI = 1 + 0.15 = 1.15
```

**Problem 4:**
```
ADD then ADD: EX→EX forwarding available, NO stall needed
LW  then ADD: Load-Use hazard, 1 stall cycle unavoidable
              MEM→EX forwarding, but timing is 1 cycle too late
```

---

## References

- Patterson & Hennessy — *Computer Organization and Design* — Chapter 4
- Hennessy & Patterson — *Computer Architecture: A Quantitative Approach*
- MIT 6.004 — [Pipeline lectures](https://ocw.mit.edu/courses/6-004-computation-structures-spring-2017/)
- Branch Prediction — [Dan Luu's article](https://danluu.com/branch-prediction/)
