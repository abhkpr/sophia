# CPU Architecture & Instruction Set Architecture

## The Heart of the Computer

The CPU (Central Processing Unit) executes your program. Every second, a modern CPU executes billions of instructions — each one a tiny, precise operation like "add these two numbers" or "load this value from memory."

**Real-world analogy:** A CPU is like a highly efficient factory assembly line. Instructions are the work orders. Registers are the workbenches — small, fast, right next to the workers. RAM is the warehouse — much larger but further away. The pipeline is the assembly line — multiple stages processing different work orders simultaneously.

---

## Part 1 — Von Neumann Architecture

The architecture underlying virtually every computer ever built.

```
┌─────────────────────────────────────────────────────┐
│                                                     │
│  ┌───────────────────┐      ┌────────────────────┐  │
│  │        CPU         │      │      Memory        │  │
│  │  ┌─────────────┐  │      │                    │  │
│  │  │   Control   │  │      │  Programs stored   │  │
│  │  │    Unit     │◄─┼──────┼─ as data (!)       │  │
│  │  └─────────────┘  │      │                    │  │
│  │  ┌─────────────┐  │      │  Variables stored  │  │
│  │  │ Arithmetic  │◄─┼──────┼─ here too          │  │
│  │  │ Logic Unit  │  │      │                    │  │
│  │  └─────────────┘  │      └────────────────────┘  │
│  │  ┌─────────────┐  │                              │
│  │  │  Registers  │  │      ┌────────────────────┐  │
│  │  │  (fast!)    │  │      │    I/O Devices     │  │
│  │  └─────────────┘  │      │  Keyboard, Screen  │  │
│  └───────────────────┘      └────────────────────┘  │
│                                                     │
│              System Bus (data highway)              │
└─────────────────────────────────────────────────────┘
```

**Key insight — stored-program concept:** Programs and data live in the same memory. This allows programs to be treated as data, modified, and loaded dynamically. This is why you can run different programs without hardware changes.

**Von Neumann bottleneck:** Only one bus between CPU and memory. CPU is much faster than memory. The CPU often sits idle waiting for data. This bottleneck is why cache memory exists.

---

## Part 2 — CPU Components

### Registers

The fastest storage in a computer. Typically 32 or 64 flip-flops. Access time: ~1 clock cycle.

**x86-64 registers:**
```
General Purpose (64-bit):
RAX  RBX  RCX  RDX   — accumulator, base, counter, data
RSI  RDI               — source index, destination index
RSP  RBP               — stack pointer, base pointer
R8   R9   R10  R11
R12  R13  R14  R15

Each 64-bit register has sub-registers:
   RAX (64-bit)
   EAX (32-bit, lower half)
    AX (16-bit, lower quarter)
    AH / AL (8-bit each)

Special Purpose:
RIP  — instruction pointer (current instruction address)
RFLAGS — status flags (zero, carry, overflow, sign, ...)

Floating Point / SIMD:
XMM0-XMM15 (128-bit)
YMM0-YMM15 (256-bit, AVX)
ZMM0-ZMM31 (512-bit, AVX-512)
```

**RISC-V registers (cleaner architecture for learning):**
```
x0  (zero)  — always 0, writes ignored
x1  (ra)    — return address
x2  (sp)    — stack pointer
x3  (gp)    — global pointer
x4  (tp)    — thread pointer
x5-x7       — temporaries
x8  (s0/fp) — saved register / frame pointer
x9  (s1)    — saved register
x10-x17     — function arguments / return values (a0-a7)
x18-x27     — saved registers (s2-s11)
x28-x31     — temporaries (t3-t6)
```

### ALU — Arithmetic Logic Unit

Performs all arithmetic and logic operations.

```
         ┌────────────┐
  A ─────┤            ├───── Result
         │    ALU     │
  B ─────┤            ├───── Flags
         └──────┬─────┘
                │
           Operation
           (ADD, SUB, AND, OR, ...)

Operations:
Arithmetic: ADD, SUB, MUL, DIV
Logical:    AND, OR, XOR, NOT
Shift:      SHL, SHR, SAR (shift left/right/arithmetic)
Compare:    sets flags without storing result

Flags register:
  Z (Zero flag):     result was zero
  N (Negative flag): result was negative
  C (Carry flag):    unsigned overflow
  V (Overflow flag): signed overflow
```

### Control Unit

Decodes instructions and coordinates all CPU components.

```
Fetch instruction from memory (using PC)
     ↓
Decode: what operation? which registers?
     ↓
Execute: tell ALU what to do
     ↓
Memory access: load/store if needed
     ↓
Write back: store result in register
     ↓
Update PC (next instruction)
     ↓
Repeat
```

---

## Part 3 — Instruction Set Architecture (ISA)

The ISA is the contract between hardware and software — the set of instructions a CPU understands. It's the lowest-level programming interface.

### RISC vs CISC

**CISC (Complex Instruction Set Computer):**
```
Philosophy: complex instructions do more work per instruction
Example: x86
  MOVS  — copies a string (loop + load + store in ONE instruction)
  FSIN  — computes sine in hardware

Pros: fewer instructions per program, backward compatibility
Cons: complex decoder, variable instruction length, hard to pipeline
Examples: x86, x86-64 (Intel/AMD)
```

**RISC (Reduced Instruction Set Computer):**
```
Philosophy: simple instructions, do one thing each
Example: RISC-V, ARM
  All instructions same size (32 bits)
  Load/store only accesses memory
  ALU operations only on registers

Pros: simple, fast, easy to pipeline, lower power
Cons: more instructions per program
Examples: RISC-V, ARM (used in phones, Apple Silicon), MIPS
```

**Modern reality:** x86 chips internally translate CISC instructions to RISC-like micro-operations. The ISA is CISC but the implementation is RISC.

### Instruction Format (RISC-V)

```
32-bit instruction, several formats:

R-type (register operations):
┌─────────┬──────┬──────┬───┬──────┬───────┐
│ funct7  │ rs2  │ rs1  │fn3│  rd  │ opcode│
│  [31:25]│[24:20]│[19:15]│[14:12]│[11:7]│[6:0]│
└─────────┴──────┴──────┴───┴──────┴───────┘
  7 bits    5      5     3    5      7

Example: ADD x1, x2, x3  (x1 = x2 + x3)
  funct7=0000000, rs2=x3, rs1=x2, funct3=000, rd=x1, opcode=0110011

I-type (immediate operations):
┌─────────────┬──────┬───┬──────┬───────┐
│    imm[11:0]│ rs1  │fn3│  rd  │ opcode│
│    12 bits  │  5   │ 3 │  5   │   7   │
└─────────────┴──────┴───┴──────┴───────┘

Example: ADDI x1, x2, 10  (x1 = x2 + 10)
  Immediate can encode constants up to 12 bits (-2048 to 2047)

S-type (stores):
┌──────────┬──────┬──────┬───┬──────────┬───────┐
│ imm[11:5]│ rs2  │ rs1  │fn3│ imm[4:0] │ opcode│
└──────────┴──────┴──────┴───┴──────────┴───────┘

B-type (branches):
Similar to S-type but immediate encodes PC-relative offset

J-type (jumps):
20-bit immediate for long-range jumps
```

### Types of Instructions

**Arithmetic/Logic:**
```asm
ADD  x1, x2, x3     ; x1 = x2 + x3
SUB  x1, x2, x3     ; x1 = x2 - x3
AND  x1, x2, x3     ; x1 = x2 & x3
OR   x1, x2, x3     ; x1 = x2 | x3
XOR  x1, x2, x3     ; x1 = x2 ^ x3
SLL  x1, x2, x3     ; x1 = x2 << x3  (shift left logical)
SRL  x1, x2, x3     ; x1 = x2 >> x3  (shift right logical)
SRA  x1, x2, x3     ; x1 = x2 >> x3  (shift right arithmetic, sign-extend)

; Immediate variants (I-type):
ADDI x1, x2, 10     ; x1 = x2 + 10
ANDI x1, x2, 0xFF   ; x1 = x2 & 0xFF
```

**Load/Store (memory access):**
```asm
; Only way to access memory in RISC!
; All operations must be register-to-register
; Except load and store

LW   x1, 8(x2)      ; x1 = Memory[x2 + 8]  (load word = 4 bytes)
LH   x1, 4(x2)      ; load halfword (2 bytes, sign-extended)
LB   x1, 0(x2)      ; load byte (sign-extended)
LWU  x1, 8(x2)      ; load word unsigned (zero-extended)

SW   x1, 8(x2)      ; Memory[x2 + 8] = x1  (store word)
SH   x1, 4(x2)      ; store halfword
SB   x1, 0(x2)      ; store byte

; Why offset addressing?
; Accessing a struct field:
;   struct Point { int x; int y; }  (x at offset 0, y at offset 4)
;   LW x5, 0(x10)   ; load point.x
;   LW x6, 4(x10)   ; load point.y
```

**Control Flow:**
```asm
; Conditional branches (PC-relative):
BEQ  x1, x2, label  ; if x1==x2, jump to label
BNE  x1, x2, label  ; if x1!=x2, jump
BLT  x1, x2, label  ; if x1 < x2 (signed)
BGE  x1, x2, label  ; if x1 >= x2 (signed)
BLTU x1, x2, label  ; if x1 < x2 (unsigned)
BGEU x1, x2, label  ; if x1 >= x2 (unsigned)

; Unconditional:
JAL  x1, label      ; x1 = PC+4, jump to label (call)
JALR x1, x2, 0      ; x1 = PC+4, jump to x2+0 (return)

; Example: if (a == b) { ... }
;   a in x10, b in x11
BNE  x10, x11, skip ; if not equal, skip body
; ... body ...
skip:
```

---

## Part 4 — Assembly Language

Assembly is a human-readable form of machine code. Each assembly instruction corresponds to one machine instruction.

### C to Assembly Translation

```c
// C code
int sum(int a, int b) {
    return a + b;
}
```

```asm
; RISC-V Assembly
; Arguments: a in a0, b in a1
; Return value: a0
sum:
    add  a0, a0, a1    ; a0 = a0 + a1
    ret                ; return (jalr x0, ra, 0)
```

**Loop example:**
```c
// Sum array of n integers
int arraySum(int* arr, int n) {
    int sum = 0;
    for (int i = 0; i < n; i++) {
        sum += arr[i];
    }
    return sum;
}
```

```asm
; arr in a0, n in a1
; sum in a2, i in a3
arraySum:
    li   a2, 0         ; sum = 0
    li   a3, 0         ; i = 0
loop:
    bge  a3, a1, done  ; if i >= n, exit loop
    slli t0, a3, 2     ; t0 = i * 4 (byte offset for int)
    add  t1, a0, t0    ; t1 = &arr[i]
    lw   t2, 0(t1)     ; t2 = arr[i]
    add  a2, a2, t2    ; sum += arr[i]
    addi a3, a3, 1     ; i++
    j    loop
done:
    mv   a0, a2        ; return sum
    ret
```

**If-else example:**
```c
int max(int a, int b) {
    if (a > b)
        return a;
    else
        return b;
}
```

```asm
; a in a0, b in a1
max:
    bge  a1, a0, return_b  ; if b >= a, return b
    ret                     ; return a (already in a0)
return_b:
    mv   a0, a1
    ret
```

### Addressing Modes

Different ways to specify where an operand is:

```
Immediate:    ADDI x1, x2, 42      operand = 42 (in instruction)
Register:     ADD  x1, x2, x3      operand = value in x3
Base+Offset:  LW   x1, 8(x2)       operand = Memory[x2 + 8]
PC-Relative:  BEQ  x1, x2, +100    target = PC + 100

x86 has more modes (complex addressing):
  [base + index*scale + displacement]
  e.g. [rbx + rcx*4 + 8]  → arr[rbx/4 + rcx]
```

---

## Part 5 — x86 Assembly (Brief)

Since most desktops run x86, useful to recognize:

```asm
; x86-64 (AT&T syntax used by GCC)
; Format: instruction src, dst  (reversed from Intel syntax!)

mov  $5, %rax         ; rax = 5
add  %rbx, %rax       ; rax = rax + rbx
sub  $3, %rax         ; rax = rax - 3
imul %rcx, %rax       ; rax = rax * rcx
push %rax             ; push onto stack
pop  %rbx             ; pop from stack
call function         ; call function
ret                   ; return from function
cmp  %rbx, %rax       ; set flags based on rax-rbx
je   label            ; jump if equal (ZF=1)
jg   label            ; jump if greater (signed)

; Intel syntax (used by MASM, NASM):
mov  rax, 5           ; rax = 5 (destination first)
add  rax, rbx         ; rax = rax + rbx
```

**Seeing assembly from C++:**
```bash
# Compile with assembly output
g++ -O0 -S -masm=intel file.cpp -o file.asm

# With optimization
g++ -O2 -S -masm=intel file.cpp -o file_opt.asm

# Or use Compiler Explorer online:
# godbolt.org — type C++, see assembly live
```

---

## Part 6 — Calling Conventions

How functions pass arguments and return values. This is the ABI (Application Binary Interface).

### RISC-V Calling Convention

```
Argument registers: a0-a7 (x10-x17)
  First 8 arguments passed in registers
  Remaining: pushed on stack

Return value:       a0, a1 (for large returns)

Caller-saved (caller must save if needed):
  ra, t0-t6, a0-a7
  Callee can freely modify these

Callee-saved (callee must restore):
  s0-s11 (x8-x9, x18-x27)
  If callee uses these, must save/restore

Stack frame:
  ┌─────────────────┐ ← old sp
  │  saved ra       │  (if function calls others)
  │  saved s0       │  (if used)
  │  saved s1       │  (if used)
  │  local vars     │
  │  ...            │
  └─────────────────┘ ← sp (points here during function)
```

**Function call example:**
```asm
; int factorial(int n)
factorial:
    addi sp, sp, -16   ; allocate stack frame
    sw   ra, 12(sp)    ; save return address
    sw   s0, 8(sp)     ; save s0
    mv   s0, a0        ; s0 = n

    li   t0, 1
    ble  a0, t0, base  ; if n <= 1, base case

    addi a0, a0, -1    ; a0 = n-1
    call factorial     ; recursive call
    mul  a0, s0, a0    ; a0 = n * factorial(n-1)
    j    done

base:
    li   a0, 1         ; return 1

done:
    lw   ra, 12(sp)    ; restore return address
    lw   s0, 8(sp)     ; restore s0
    addi sp, sp, 16    ; deallocate frame
    ret
```

---

## Practice Problems

1. Translate to RISC-V assembly:
   ```c
   int absolute(int x) {
       if (x < 0) return -x;
       return x;
   }
   ```

2. What does this assembly do?
   ```asm
   li   t0, 1
   li   t1, 0
   loop:
       mul  t1, t1, a0  ; what's wrong here?
       mul  t0, t0, a0
       addi t2, t2, -1
       bnez t2, loop
   ```

3. How many bytes does `LW x5, 0(x6)` load?

4. What is the difference between `SRL` and `SRA`?

---

## Answers

**Problem 1:**
```asm
; x in a0, result in a0
absolute:
    bge  a0, x0, done  ; if x >= 0, done
    neg  a0, a0        ; a0 = -a0 (pseudo: sub a0, x0, a0)
done:
    ret
```

**Problem 3:** 4 bytes (LW = Load Word = 32 bits = 4 bytes)

**Problem 4:**
```
SRL (Shift Right Logical):  fills with 0s from left
  1000 1010 >> 2 = 0010 0010  (unsigned right shift)

SRA (Shift Right Arithmetic): fills with sign bit from left
  1000 1010 >> 2 = 1110 0010  (signed right shift, preserves sign)

Use SRL for unsigned numbers
Use SRA for signed numbers (equivalent to division by 2^n)
```

---

## References

- Patterson & Hennessy — *Computer Organization and Design* RISC-V ed. — Chapters 2-3
- Nisan & Schocken — *The Elements of Computing Systems* (Nand2Tetris)
- RISC-V Spec — [riscv.org](https://riscv.org/technical/specifications/)
- Godbolt Compiler Explorer — [godbolt.org](https://godbolt.org)
- MIT 6.004 — [Computation Structures](https://ocw.mit.edu/courses/6-004-computation-structures-spring-2017/)
