# Threads and Concurrency

## Lightweight Execution Units

A thread is an independent execution path within a process. Multiple threads share the same address space but have their own stack and CPU registers. Threads are how modern programs do multiple things simultaneously.

**Real-world analogy:** Think of a restaurant kitchen.
- The **restaurant** is the process (owns all the equipment, ingredients, space)
- Each **cook** is a thread (independent worker sharing the same kitchen)
- They share the stove, refrigerator, and workspace (shared memory)
- Each cook has their own hands and mind (own stack and registers)
- They must coordinate to avoid collisions (synchronization)

One cook (single-threaded): efficient but slow for complex orders.
Multiple cooks (multi-threaded): faster, but they must communicate to avoid two people using the same pot at the same time.

---

## Part 1 — Threads vs Processes

```
                Process              Thread
────────────────────────────────────────────────────
Memory          Separate             Shared (within process)
Creation cost   High (~1ms)          Low (~10-50µs)
Switching cost  High (change page    Low (same page tables)
                tables, TLB flush)
Communication   IPC (pipes, sockets) Direct (shared memory)
Isolation       Strong               Weak (one thread crash
                                     can kill all)
Resource usage  High (own page       Low (share everything)
                table, file table)
```

### What Threads Share vs Own

```
SHARED (all threads in process):
  ✓ Virtual address space (code, heap, globals)
  ✓ Open file descriptors
  ✓ Network sockets
  ✓ Signal handlers (disposition)
  ✓ Process ID (PID)
  ✓ Current working directory
  ✓ User and group IDs

PRIVATE (each thread has its own):
  ✗ Stack (local variables, function call frames)
  ✗ Registers (PC, SP, general purpose)
  ✗ Thread ID (TID)
  ✗ errno variable
  ✗ Signal mask (which signals blocked)
  ✗ Thread-local storage (TLS)
```

---

## Part 2 — POSIX Threads (pthreads)

The standard threading API on Linux/Unix.

### Creating and Joining Threads

```c
#include <pthread.h>

void* threadFunction(void* arg) {
    int id = *(int*)arg;
    printf("Thread %d running\n", id);
    
    // Do work
    long sum = 0;
    for (int i = 0; i < 1000000; i++) sum += i;
    
    // Return a value (as void*)
    long* result = malloc(sizeof(long));
    *result = sum;
    return result;
}

int main() {
    pthread_t threads[4];
    int ids[4] = {0, 1, 2, 3};
    
    // Create 4 threads
    for (int i = 0; i < 4; i++) {
        int rc = pthread_create(&threads[i], NULL, threadFunction, &ids[i]);
        if (rc != 0) { perror("create failed"); exit(1); }
    }
    
    // Wait for all to finish, collect return values
    for (int i = 0; i < 4; i++) {
        long* result;
        pthread_join(threads[i], (void**)&result);
        printf("Thread %d sum = %ld\n", i, *result);
        free(result);
    }
    return 0;
}
```

### Thread Stack

```
Each thread has its own stack:

Thread 1 stack:     Thread 2 stack:     Thread 3 stack:
┌────────────┐      ┌────────────┐      ┌────────────┐
│  main()    │      │ worker()   │      │ worker()   │
│  local vars│      │ local vars │      │ local vars │
│  saved regs│      │ saved regs │      │ saved regs │
└────────────┘      └────────────┘      └────────────┘

Shared heap:
┌──────────────────────────────────────────────────────┐
│  malloc'd objects accessible by all threads          │
└──────────────────────────────────────────────────────┘

Default thread stack size: 8MB on Linux
Can configure with pthread_attr_setstacksize()
Stack overflow = crash of entire process (guard pages)
```

---

## Part 3 — The Race Condition Problem

When multiple threads access shared data and at least one modifies it, results depend on execution order — **race condition**.

```c
// Seemingly innocent code: two threads increment a counter
int counter = 0;

void* increment(void* arg) {
    for (int i = 0; i < 100000; i++) {
        counter++;   // NOT atomic — this is 3 operations!
    }
    return NULL;
}

int main() {
    pthread_t t1, t2;
    pthread_create(&t1, NULL, increment, NULL);
    pthread_create(&t2, NULL, increment, NULL);
    pthread_join(t1, NULL);
    pthread_join(t2, NULL);
    printf("counter = %d\n", counter);  // Expected: 200000
    // Actual: anywhere from 100001 to 200000!
}
```

**Why `counter++` is not atomic:**

```
counter++ compiles to 3 instructions:
  LOAD:  R1 = counter        (read from memory)
  ADD:   R1 = R1 + 1         (add in register)
  STORE: counter = R1        (write back)

Race condition:
Thread 1:         Thread 2:         counter
LOAD R1 = 5       ...               5
ADD  R1 = 6       ...               5
...               LOAD R2 = 5       5
...               ADD  R2 = 6       5
STORE counter=6   ...               6
...               STORE counter=6   6    ← LOST INCREMENT!

Both threads loaded the same value (5), both incremented to 6.
Net result: only 1 increment happened despite 2 operations.
```

---

## Part 4 — Mutex (Mutual Exclusion)

A mutex ensures only one thread executes a critical section at a time.

**Real-world analogy:** A single-stall bathroom. There's one lock on the door. When you enter, you lock it. Others must wait outside. When you leave, you unlock it and the next person enters. Mutual exclusion prevents two people from using it simultaneously.

```c
pthread_mutex_t lock = PTHREAD_MUTEX_INITIALIZER;
int counter = 0;

void* increment(void* arg) {
    for (int i = 0; i < 100000; i++) {
        pthread_mutex_lock(&lock);
        counter++;              // critical section
        pthread_mutex_unlock(&lock);
    }
    return NULL;
}
// Result: exactly 200000 every time ✓
```

### Mutex Internals

```
typedef struct {
    int locked;        // 0 = free, 1 = locked
    thread_t owner;    // which thread holds it
    queue_t waiters;   // threads waiting
} mutex_t;

lock():
  if (mutex.locked == 0):
    mutex.locked = 1
    mutex.owner = current_thread
    return  // lock acquired
  else:
    add current_thread to mutex.waiters
    block current_thread (put to sleep)
    // When woken up: retry

unlock():
  assert(mutex.owner == current_thread)
  if (mutex.waiters is not empty):
    wake up one waiter
    transfer ownership to them
  else:
    mutex.locked = 0

Critical: lock() and unlock() must check-and-set atomically!
Hardware provides: LOCK XCHG, CMPXCHG, LL/SC instructions
```

### Deadlock

**Real-world analogy:** Two people each holding one half of a door key. Person A has the top half and waits for Person B to give the bottom half. Person B has the bottom half and waits for Person A to give the top half. Neither moves. Forever.

```c
// Classic deadlock: two threads, two locks, wrong order
pthread_mutex_t lock1 = PTHREAD_MUTEX_INITIALIZER;
pthread_mutex_t lock2 = PTHREAD_MUTEX_INITIALIZER;

void* thread1(void*) {
    pthread_mutex_lock(&lock1);
    sleep(1);                    // pause (forces interleaving)
    pthread_mutex_lock(&lock2);  // WAIT: thread2 holds lock2
    // ... do work ...
    pthread_mutex_unlock(&lock2);
    pthread_mutex_unlock(&lock1);
    return NULL;
}

void* thread2(void*) {
    pthread_mutex_lock(&lock2);
    sleep(1);
    pthread_mutex_lock(&lock1);  // WAIT: thread1 holds lock1
    // ... do work ...
    pthread_mutex_unlock(&lock1);
    pthread_mutex_unlock(&lock2);
    return NULL;
}
// Result: both threads wait forever = DEADLOCK!
```

**Deadlock conditions (all four must hold):**
```
1. Mutual exclusion: resources can't be shared
2. Hold and wait: thread holds one resource while waiting for another
3. No preemption: resources can't be forcibly taken
4. Circular wait: A waits for B waits for C waits for A

Break ANY one condition → no deadlock.
```

**Solutions:**
```
1. Lock ordering: always acquire locks in same global order
   Thread 1 and 2 both: lock1 first, then lock2
   → no circular wait

2. trylock with backoff:
   if (!pthread_mutex_trylock(&lock2)) {
       pthread_mutex_unlock(&lock1);  // release what we have
       backoff();                     // sleep briefly
       goto retry;                    // try again
   }

3. Single lock for multiple resources (coarser granularity)

4. Banker's algorithm: check if allocation is safe before granting
   (used in databases, resource managers)
```

---

## Part 5 — Condition Variables

Mutex ensures mutual exclusion. Condition variables let threads wait for a condition to become true.

**Real-world analogy:** A package notification system. You ordered something (need a condition — package arrives). Instead of repeatedly calling the delivery company (busy-waiting), you register your number and they call you when it arrives (condition variable). You can do other things in the meantime.

```c
pthread_mutex_t mtx = PTHREAD_MUTEX_INITIALIZER;
pthread_cond_t  cond = PTHREAD_COND_INITIALIZER;
int data_ready = 0;
int data = 0;

// Producer thread: produces data
void* producer(void* arg) {
    sleep(1);  // simulate work
    
    pthread_mutex_lock(&mtx);
    data = 42;
    data_ready = 1;
    pthread_cond_signal(&cond);    // wake ONE waiting thread
    // pthread_cond_broadcast(&cond); // wake ALL waiting threads
    pthread_mutex_unlock(&mtx);
    return NULL;
}

// Consumer thread: waits for data
void* consumer(void* arg) {
    pthread_mutex_lock(&mtx);
    
    // ALWAYS use while, not if! (spurious wakeups)
    while (!data_ready) {
        pthread_cond_wait(&cond, &mtx);
        // cond_wait ATOMICALLY:
        //   1. Releases mtx
        //   2. Puts thread to sleep
        //   3. On wakeup: reacquires mtx before returning
    }
    
    printf("Got data: %d\n", data);
    pthread_mutex_unlock(&mtx);
    return NULL;
}
```

**Why `while` not `if`:**
```
Spurious wakeups: pthread_cond_wait can return even if no signal sent
                  (OS implementation artifact, POSIX allows it)
Multiple waiters: if broadcast wakes 3 threads but only 1 item available,
                  the other 2 must go back to sleep
                  
Always pattern:
  while (!condition) {
      pthread_cond_wait(&cond, &mutex);
  }
```

### Producer-Consumer with Bounded Buffer

```c
#define BUFFER_SIZE 10

int buffer[BUFFER_SIZE];
int in = 0, out = 0, count = 0;
pthread_mutex_t mtx = PTHREAD_MUTEX_INITIALIZER;
pthread_cond_t not_full  = PTHREAD_COND_INITIALIZER;
pthread_cond_t not_empty = PTHREAD_COND_INITIALIZER;

void produce(int item) {
    pthread_mutex_lock(&mtx);
    while (count == BUFFER_SIZE)          // buffer full?
        pthread_cond_wait(&not_full, &mtx); // wait for space
    buffer[in] = item;
    in = (in + 1) % BUFFER_SIZE;
    count++;
    pthread_cond_signal(&not_empty);      // wake a consumer
    pthread_mutex_unlock(&mtx);
}

int consume() {
    pthread_mutex_lock(&mtx);
    while (count == 0)                    // buffer empty?
        pthread_cond_wait(&not_empty, &mtx); // wait for item
    int item = buffer[out];
    out = (out + 1) % BUFFER_SIZE;
    count--;
    pthread_cond_signal(&not_full);       // wake a producer
    pthread_mutex_unlock(&mtx);
    return item;
}
```

---

## Part 6 — Semaphores

A semaphore is an integer counter with two atomic operations:
- **wait (P, down):** decrement; if < 0, block
- **signal (V, up):** increment; if threads waiting, wake one

**Real-world analogy:** Parking lot with a counter. Counter shows spaces available. When you enter, counter decreases. If 0, you wait. When someone leaves, counter increases and waiting car enters.

```c
#include <semaphore.h>

sem_t semaphore;
sem_init(&semaphore, 0, 1);  // initial value = 1 (binary semaphore = mutex)

// Thread safe increment using semaphore as mutex:
sem_wait(&semaphore);   // P: decrement, block if 0
counter++;              // critical section
sem_post(&semaphore);   // V: increment, wake waiter
```

**Counting semaphore — limit concurrent access:**
```c
sem_t db_connections;
sem_init(&db_connections, 0, 5);  // max 5 concurrent connections

void queryDatabase() {
    sem_wait(&db_connections);    // acquire connection slot
    // ... use database ...
    sem_post(&db_connections);    // release slot
}
// At most 5 threads can be in queryDatabase() simultaneously
```

**Semaphore vs Mutex:**
```
Mutex:
  Binary (locked/unlocked)
  Owner-based: only locking thread can unlock
  Used for: mutual exclusion

Semaphore:
  Integer counter
  No owner: any thread can signal
  Used for: resource counting, signaling between threads

Signaling pattern (one-shot):
sem_t ready;
sem_init(&ready, 0, 0);  // initially 0 (locked)

// Thread 1: waits for Thread 2 to signal
sem_wait(&ready);
use_data();

// Thread 2: signals when data is ready
prepare_data();
sem_post(&ready);   // Thread 1 can now proceed
```

---

## Part 7 — Reader-Writer Problem

Multiple readers allowed simultaneously, but writers need exclusive access.

```c
// Reader-Writer lock using pthreads
pthread_rwlock_t rwlock = PTHREAD_RWLOCK_INITIALIZER;

void* reader(void* arg) {
    pthread_rwlock_rdlock(&rwlock);   // multiple readers allowed
    // read shared data...
    printf("Reading: %d\n", shared_data);
    pthread_rwlock_unlock(&rwlock);
    return NULL;
}

void* writer(void* arg) {
    pthread_rwlock_wrlock(&rwlock);   // exclusive access
    // modify shared data...
    shared_data++;
    pthread_rwlock_unlock(&rwlock);
    return NULL;
}
```

**Implementation (manual):**
```c
// Variables:
int readers = 0;           // count of active readers
pthread_mutex_t rmutex;    // protect readers count
pthread_mutex_t write_lock; // writers and readers-writing conflict

// Reader entry:
pthread_mutex_lock(&rmutex);
readers++;
if (readers == 1)
    pthread_mutex_lock(&write_lock);  // first reader blocks writers
pthread_mutex_unlock(&rmutex);
// ... read ...

// Reader exit:
pthread_mutex_lock(&rmutex);
readers--;
if (readers == 0)
    pthread_mutex_unlock(&write_lock);  // last reader unblocks writers
pthread_mutex_unlock(&rmutex);

// Writer: just acquires write_lock
pthread_mutex_lock(&write_lock);
// ... write ...
pthread_mutex_unlock(&write_lock);
```

---

## Part 8 — C++ Threads (C++11 and later)

Modern C++ wraps pthread in cleaner interfaces.

```cpp
#include <thread>
#include <mutex>
#include <condition_variable>

// Basic thread
std::thread t([]() {
    std::cout << "Running in thread\n";
});
t.join();

// Mutex
std::mutex mtx;
int counter = 0;

auto increment = [&]() {
    for (int i = 0; i < 100000; i++) {
        std::lock_guard<std::mutex> lock(mtx);  // RAII: auto-unlock
        counter++;
    }
};

std::thread t1(increment), t2(increment);
t1.join(); t2.join();
// counter == 200000 ✓

// Unique lock (can unlock manually)
std::unique_lock<std::mutex> lock(mtx);
// ... do something ...
lock.unlock();
// ... do something without lock ...
lock.lock();
// ...

// Condition variable
std::condition_variable cv;
bool ready = false;

// Waiter:
std::unique_lock<std::mutex> lock(mtx);
cv.wait(lock, [&]{ return ready; });  // wait until ready == true

// Notifier:
{
    std::lock_guard<std::mutex> lock(mtx);
    ready = true;
}
cv.notify_one();

// Atomic variables (no mutex needed for simple ops)
#include <atomic>
std::atomic<int> atomic_counter(0);
atomic_counter++;           // atomic increment, no race condition
atomic_counter.fetch_add(1); // same
```

---

## Practice Problems

1. Two threads increment a shared counter 100,000 times each. Without synchronization, what range of values is the final counter?

2. Identify the bug:
   ```c
   pthread_mutex_t m;
   void* thread1(void*) { pthread_mutex_lock(&m); /* work */ return NULL; }
   void* thread2(void*) { pthread_mutex_lock(&m); /* work */ pthread_mutex_unlock(&m); return NULL; }
   ```

3. When should you use a condition variable instead of a loop that keeps checking a flag?

4. Show a minimal deadlock scenario and fix it.

5. What is a spurious wakeup? Why must condition variable waits use `while` instead of `if`?

---

## Answers

**Problem 1:**
```
Minimum: 100,001
  Thread 1 runs entirely, counter = 100,000
  Thread 2 runs, but on the very last increment:
    Thread 2 loads counter=100,000 into register
    Thread 1 is done
    Thread 2 increments to 100,001, stores
  Worst case: almost all of thread 2's increments lost

Maximum: 200,000
  No race conditions happen to occur
  (Unlikely but possible)

Most common: somewhere between 100,001 and 200,000
The exact value depends on thread interleaving = non-deterministic
```

**Problem 2:**
```
Thread 1 acquires the mutex but NEVER releases it (no unlock call).
Thread 2 will wait forever trying to acquire the mutex.
This is a LIVELOCK / DEADLOCK situation.

Fix: always pair lock with unlock, use RAII in C++:
void* thread1(void*) {
    pthread_mutex_lock(&m);
    /* work */
    pthread_mutex_unlock(&m);   // ADD THIS
    return NULL;
}
```

**Problem 3:**
```
Use condition variable when:
  - Condition might not become true for a long time
  - Busy-waiting (spinning) would waste CPU

Example: consumer waiting for items in a queue.
  Bad (busy-wait):
    while (queue.empty()) {}  // spins, burns 100% CPU
  Good (condition variable):
    while (queue.empty()) cond_wait(&cond, &mutex);  // sleeps
    
Use busy-wait only when:
  - Expected wait is very short (< 1µs)
  - Running on dedicated core (real-time systems)
  - In kernel spinlocks (can't sleep in interrupt context)
```

**Problem 4:**
```c
// Deadlock: two locks acquired in different order
mutex A, B;
Thread 1: lock(A), lock(B)  // A first
Thread 2: lock(B), lock(A)  // B first → circular wait!

// Fix: establish global lock ordering
Thread 1: lock(A), lock(B)
Thread 2: lock(A), lock(B)  // same order → no circular wait

// Or: use trylock with backoff
Thread 2:
  lock(A);
  if (!trylock(B)) {
      unlock(A);    // release, try again later
      sleep(random_backoff);
      goto retry;
  }
```

**Problem 5:**
```
Spurious wakeup: condition variable wakes up a waiting thread
even though no signal/broadcast was sent.
Allowed by POSIX specification (implementation artifact).
Can happen due to:
  - Signal delivery to the process
  - OS implementation choices
  - Multi-processor synchronization overhead

Why while instead of if:
  if (!ready) { cond_wait(...); }
  // After wakeup: goes straight to use_data()
  // But might have been spurious wakeup! ready is still false!

  while (!ready) { cond_wait(...); }
  // After spurious wakeup: checks condition again
  // Not ready → goes back to sleep
  // Only proceeds when ready is actually true ✓
```

---

## References

- Arpaci-Dusseau — *OSTEP* — Chapters 26-32 (Concurrency)
- Butenhof — *Programming with POSIX Threads*
- Herlihy & Shavit — *The Art of Multiprocessor Programming*
- cppreference.com — [Thread support library](https://en.cppreference.com/w/cpp/thread)
- man pages: `man 3 pthread_create`, `man 3 pthread_mutex_lock`
