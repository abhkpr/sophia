# File Systems

## Persistent, Organized Storage

A file system gives you the illusion of organized, named, persistent storage sitting on top of what is physically just a bunch of numbered disk sectors. It's one of the OS's most elegant abstractions.

**Real-world analogy:** Think of a file system as a library. The library building is the hard disk. Each book is a file. The library catalog (card catalog or digital index) is the file system's metadata structures. The Dewey Decimal System is the directory hierarchy. A librarian who knows where every book is located corresponds to the OS file system driver. Without the catalog, you'd have to search every shelf to find any book.

---

## Part 1 — File System Concepts

### What is a File?

A file is a named, persistent sequence of bytes managed by the OS.

```
From the user's perspective:
  - Has a name (path)
  - Has contents (bytes)
  - Has metadata (size, owner, permissions, timestamps)

From the OS perspective:
  - Stored as blocks on disk
  - Has an inode (metadata structure)
  - Accessed via file descriptor
  - Can be type: regular, directory, symlink, device, pipe, socket
```

**File operations:**
```c
// Open returns a file descriptor (small integer)
int fd = open("file.txt", O_RDONLY);           // open existing
int fd = open("file.txt", O_WRONLY|O_CREAT, 0644); // create/open for write

// Read and write move the file offset
ssize_t n = read(fd, buffer, 1024);  // read up to 1024 bytes
ssize_t n = write(fd, buffer, 1024); // write 1024 bytes

// Seek changes the file offset
off_t pos = lseek(fd, 0, SEEK_SET);  // seek to beginning
off_t pos = lseek(fd, 0, SEEK_END);  // seek to end (get file size)
off_t pos = lseek(fd, -10, SEEK_CUR); // seek 10 bytes backward

// Metadata
struct stat st;
fstat(fd, &st);
printf("size=%ld, permissions=%o\n", st.st_size, st.st_mode);

// Close when done
close(fd);
```

### Directories

Directories map names to inode numbers. A directory is a special file containing name→inode pairs.

```
Directory /home/user/:
┌─────────────────────────────────┐
│  Name         Inode Number      │
│  .            1234  (itself)    │
│  ..           1000  (parent)    │
│  documents    1235              │
│  photos       1236              │
│  code         1237              │
│  resume.pdf   1238              │
└─────────────────────────────────┘

Path resolution:
  /home/user/documents/notes.txt
  
  1. Start at root /  → inode 2 (root always inode 2)
  2. Look up "home"   → inode 1000
  3. Look up "user"   → inode 1234
  4. Look up "documents" → inode 1235
  5. Look up "notes.txt" → inode 5678
  6. Read inode 5678 to find disk blocks
  7. Read those blocks = file contents
```

---

## Part 2 — Inode (Index Node)

The core metadata structure for every file. On disk, the inode stores everything about a file except its name.

```
inode contents:
┌────────────────────────────────────────────────────┐
│  File type:      regular, directory, symlink...    │
│  Permissions:    rwxrwxrwx (owner, group, other)   │
│  Owner UID:      1000 (user ID)                    │
│  Owner GID:      1000 (group ID)                   │
│  File size:      1048576 (bytes)                   │
│  Link count:     2 (number of directory entries)   │
│  atime:          last access timestamp             │
│  mtime:          last modification timestamp       │
│  ctime:          last status change timestamp      │
│  Block count:    2048 (512-byte blocks used)       │
│                                                    │
│  Block pointers:                                   │
│    Direct[0]:  block 1024   ─────────────────────► │
│    Direct[1]:  block 1025                          │
│    ...                                             │
│    Direct[11]: block 1035                          │
│    Indirect:   block 2000  → [ptr][ptr][ptr]...    │
│    Double ind: block 3000  → [...] → [ptr]...      │
│    Triple ind: block 4000  → [...] → [...] → ...   │
└────────────────────────────────────────────────────┘
```

### Block Pointers

How inodes point to file data blocks (ext2/ext3 style):

```
Small files (≤ 12 blocks ≈ 48KB with 4KB blocks):
  12 direct pointers → 12 × 4KB = 48KB

Larger files use indirect blocks:
  1 indirect pointer → block of 1024 pointers → 1024 × 4KB = 4MB
  1 double indirect → 1024 × 1024 × 4KB = 4GB
  1 triple indirect → 1024³ × 4KB = 4TB

Total max file size (ext2):
  12 × 4KB + 4MB + 4GB + 4TB ≈ 4TB
```

**Extent-based inodes (ext4, APFS, NTFS):**
```
Instead of individual block pointers, store extents:
  extent = (start_block, length)
  
  A 10MB file stored contiguously:
    Old: 2560 block pointers
    New: 1 extent: (start=5000, length=2560)
  
  Advantages:
    - Fewer metadata reads for large sequential files
    - Less fragmentation (allocator tries to keep extents contiguous)
    - Faster large file operations
```

---

## Part 3 — File System Layout on Disk

**ext2/ext3 layout:**
```
Disk divided into block groups:

Block Group 0:
┌──────────────┬──────────────┬──────────────┬──────────────┐
│  Superblock  │ Group Desc.  │  Inode Table │  Data Blocks │
│  (FS info)   │  (bg info)   │  (all inodes)│  (file data) │
└──────────────┴──────────────┴──────────────┴──────────────┘
Block Group 1:
┌──────────────┬──────────────┬──────────────┬──────────────┐
│  Superblock  │ Group Desc.  │  Inode Table │  Data Blocks │
│  (backup)    │  (backup)    │              │              │
└──────────────┴──────────────┴──────────────┴──────────────┘
...

Superblock contains:
  - Total inode count, free inode count
  - Total block count, free block count
  - Block size (1KB, 2KB, 4KB)
  - Magic number (0xEF53 for ext2)
  - Last mount time, mount count

Inode Table:
  Fixed-size array of inodes
  inode number → table index → inode on disk
  
Block Bitmap:
  One bit per data block: 0=free, 1=used
  Fast allocation: scan for first 0 bit

Inode Bitmap:
  One bit per inode: 0=free, 1=used
```

---

## Part 4 — Journaling

**The crash consistency problem:**

```
Creating a file requires multiple disk writes:
  1. Update inode bitmap (mark inode used)
  2. Write inode (initialize metadata)
  3. Write directory entry (name → inode mapping)
  4. Write file data
  
If power fails after step 1 but before step 3:
  Inode marked used but no directory points to it → leaked inode!
  
If power fails after step 3 but before step 2:
  Directory points to uninitialized inode → garbage data!
  
Inconsistency!
```

**Solution: Journaling (write-ahead logging)**

```
Before writing to the actual filesystem, write the operation
to a journal (log) first.

Steps:
  1. Write "BEGIN" marker to journal
  2. Write all planned changes to journal
  3. Write "COMMIT" marker to journal
  4. Actually apply changes to filesystem
  5. Write "DONE" to journal (can now reuse journal space)

On crash recovery:
  Find incomplete operations in journal
  If COMMITTED but not DONE: redo the operation
  If not COMMITTED: ignore (incomplete transaction)
  
  File system is always consistent after recovery!

Journal modes (ext4):
  data=writeback: only metadata journaled (fastest, some data risk)
  data=ordered:   data written before metadata (default, safe)
  data=journal:   both data and metadata journaled (slowest, safest)

Journaling adds ~5-10% overhead but eliminates fsck on every crash.
Before journaling: after crash → must run fsck on entire disk (hours!)
With journaling: after crash → replay journal → ready in seconds
```

---

## Part 5 — Hard Links and Symbolic Links

**Hard link:**
```
Multiple directory entries pointing to the SAME inode.
The inode's link count tracks how many entries point to it.

ln file.txt hardlink.txt
# Both entries point to same inode

file.txt ──────────────────► inode 1234
hardlink.txt ───────────────►    (link count = 2)

Deletion:
  rm file.txt → link count becomes 1, inode not freed
  rm hardlink.txt → link count becomes 0, inode freed, blocks freed

Limitations:
  - Can't hard link directories (would create cycles)
  - Can't cross filesystem boundaries (inode numbers are per-filesystem)
  - Both names are equal — no "original" vs "link"
```

**Symbolic link (symlink):**
```
A special file whose content is a path to another file.

ln -s /home/user/documents/notes.txt shortcut.txt
# shortcut.txt is a file containing the string "/home/user/documents/notes.txt"

shortcut.txt (inode 9999) contains: "/home/user/documents/notes.txt"
↓ follow symlink
notes.txt (inode 1234) = actual file

Differences from hard link:
  - Can point to directories
  - Can cross filesystem boundaries
  - The target may not exist (dangling symlink)
  - Symlink has its own inode, own link count
  - Following symlink involves extra path traversal
  - stat() follows symlink; lstat() doesn't

rm notes.txt → symlink still exists but dangling (broken)
```

---

## Part 6 — File System Implementations

### FAT (File Allocation Table)

Used in USB drives, SD cards, historical Windows.

```
Disk layout:
┌─────────┬─────────┬──────────────────────────────┐
│  Boot   │   FAT   │           Data Area           │
│  sector │  table  │  cluster 2, 3, 4, 5, ...     │
└─────────┴─────────┴──────────────────────────────┘

FAT table: one entry per cluster
  0x000:    free
  0x002-FFx: next cluster in file
  0xFFF:    end of file

File "hello.txt" stored in clusters 2, 5, 7:
  FAT[2] = 5     (next cluster after 2 is 5)
  FAT[5] = 7     (next cluster after 5 is 7)
  FAT[7] = 0xFFF (end of file)

Simple linked list on disk.
Pros: simple, universal, no fragmentation check needed
Cons: FAT must be read into RAM; slow for large disks;
      no permissions, no journaling, 4GB file size limit (FAT32)
```

### ext4 (Linux Standard)

```
Modern features added to ext2/ext3 design:
  - Extent-based allocation (contiguous ranges vs individual blocks)
  - Delayed allocation (batch allocations for better placement)
  - Journaling (data=ordered by default)
  - Large file support (up to 16TB files, 1EB filesystem)
  - Extents tree in inode (replaces indirect blocks for large files)
  - Checksums on journal and metadata
  - Supports Unix permissions, ACLs
  
Performance features:
  - Multiblock allocator (allocates multiple contiguous blocks at once)
  - Persistent preallocation (guarantee space before writing)
  - Online defragmentation
```

### NTFS (Windows)

```
Master File Table (MFT):
  Every file and directory = one MFT record (1KB each)
  First 16 records reserved for metadata
  MFT can grow as files added
  
MFT record structure:
┌────────────────────────────────────────────┐
│ Header (magic, flags, size)                │
│ $STANDARD_INFORMATION: times, flags        │
│ $FILE_NAME: name, parent directory         │
│ $DATA: file data (inline if < ~700 bytes!) │
│         or run list for larger files       │
└────────────────────────────────────────────┘

Run list (like extents):
  File stored as list of runs (contiguous blocks)
  (start_cluster, length) pairs

Features:
  - ACLs (Access Control Lists) for permissions
  - Encryption (EFS)
  - Compression
  - Journaling (change journal)
  - Hard links and junctions (directory hard links)
  - Max file size: 16TB, max volume: 256TB
```

### Copy-on-Write File Systems (ZFS, BTRFS, APFS)

```
Traditional file system: update in place
  Old data: [A][B][C] → write B' → [A][B'][C]
  Problem: interrupted write = partial update = inconsistency

COW file system: never overwrite
  Old: [A][B][C]
  Write B': [A][B][C][B'] → update pointers → [A][B'][C]
  Old [B] still exists until pointer removed

Benefits:
  - No corruption: partially written state is never exposed
  - Snapshots are FREE: just preserve old root pointer
  - Data integrity: checksums on every block
  - No need for journal (COW IS the atomicity mechanism)

Snapshots example (ZFS):
  zfs snapshot pool/data@backup   # instant, zero cost!
  # If files change, only changed blocks are copied
  # Unmodified blocks shared between snapshot and current

ZFS features:
  - Built-in RAID (raidz = software RAID-5)
  - Checksums on all data and metadata (detects bit rot)
  - Deduplication (same data stored once)
  - Compression (transparent)
  - Unlimited snapshots and clones
  - Send/receive (incremental backup)
```

---

## Part 7 — File System Caching

Disk is 1000× slower than RAM. Cache frequently used disk data in memory.

```
Linux Page Cache:
  File data cached in page-sized chunks (4KB)
  Reads: first time = disk, subsequent = cache (if not evicted)
  Writes: written to cache first, written to disk later (write-back)
  
  Cache coherence: mmap and read/write see same data
  
  free command shows:
    Mem:  8G total, 2G used, 1G free, 5G buff/cache
    The 5G "buff/cache" is pages used for disk cache
    This is NOT wasted — it will be freed if programs need RAM

Buffer Cache:
  Caches raw disk blocks (for file system metadata)
  Directory entries, inodes, superblock all cached
  
  Without buffer cache: every path traversal = multiple disk reads
  With buffer cache: frequently used directories served from RAM
```

---

## Practice Problems

1. A file is stored at blocks 4, 9, 15, 22 on disk. Draw the FAT entries for this file.

2. A file is created, written, and deleted. The user's data was written before the system crashed. Will the data be recovered? Why?

3. What is the difference between `stat` and `lstat`? When would you use each?

4. Why can't you create a hard link to a directory? (Most systems prevent this)

5. An inode has 12 direct pointers, 1 indirect, and block size = 4KB with 1024 pointers per indirect block. What is the maximum single-file size?

---

## Answers

**Problem 1:**
```
FAT entries for file at blocks 4, 9, 15, 22:

FAT index:  1    2    3    4    5    6    7    8    9   10   11...22   23...
FAT value: ...  ...  ...   9   free free free free  15  ...  ...   22  EOF

FAT[4] = 9    (next block after 4 is 9)
FAT[9] = 15   (next block after 9 is 15)
FAT[15] = 22  (next block after 15 is 22)
FAT[22] = EOF (end of file, 0xFFF in FAT16)
```

**Problem 2:**
```
The data IS on disk (we're told it was written).
Whether it's accessible depends on the crash timing:

Scenario 1 — journaling, data=ordered mode:
  Data written to disk BEFORE metadata
  Journal has COMMIT record
  After crash: journal replay updates metadata
  Result: file exists and contains correct data ✓

Scenario 2 — no journaling or crash before commit:
  Data blocks written but inode/directory not updated
  After crash: blocks may be "free" according to bitmap
  fsck might not find them as part of any file
  Data is on disk but inaccessible (no inode points to it)
  "Orphan blocks" might be recoverable with forensic tools

Scenario 3 — write-back caching, data not yet on disk:
  Data in page cache, power failure → data LOST
  Unless: sync(), fsync(), O_SYNC, or write-through mode used
```

**Problem 3:**
```
stat(path, &buf):
  Follows symbolic links
  Returns info about the target file
  
  symlink.txt → /etc/passwd
  stat("symlink.txt") → info about /etc/passwd (the target)
  
lstat(path, &buf):
  Does NOT follow symbolic links
  Returns info about the symbolic link itself
  
  lstat("symlink.txt") → info about symlink.txt itself
    (type=symlink, size=length of target path string, etc.)

Use stat when you want info about what the path refers to.
Use lstat when checking if something IS a symlink (st_mode check),
or when traversing a directory tree (avoid following links).
```

**Problem 4:**
```
If directory hard links were allowed:

mkdir /tmp/a
mkdir /tmp/a/b
ln -d /tmp/a /tmp/a/b/link_to_a  # if allowed!

File tree structure:
/tmp/a/b/link_to_a → points to /tmp/a → CYCLE!

Problems with directory cycles:
1. find, du, ls -R → infinite loop!
2. Path resolution: /tmp/a/b/link_to_a/b/link_to_a/b/... infinite!
3. File system consistency checks (fsck) break

Linux prevents it: open(2) with O_PATH + link syscalls reject directories.
Exception: . and .. are special hard links managed entirely by the kernel.

Symbolic links to directories ARE allowed but tools handle them:
  find handles -follow flag
  ls shows the symlink, not its contents by default
```

**Problem 5:**
```
12 direct pointers × 4KB = 48KB

1 indirect pointer:
  Points to one block of 1024 pointers
  1024 × 4KB = 4MB

Total = 48KB + 4MB = 4,194,304 + 49,152 ≈ 4.05MB

If we also had double and triple indirect:
  Double: 1024 × 1024 × 4KB = 4GB
  Triple: 1024³ × 4KB = 4TB

With only 12 direct + 1 indirect: max ≈ 4MB
```

---

## References

- Arpaci-Dusseau — *OSTEP* — Chapters 36-45 (Persistence)
- McKusick et al. — *The Design and Implementation of the FreeBSD Operating System*
- ext4 documentation — [kernel.org ext4](https://www.kernel.org/doc/html/latest/filesystems/ext4/)
- ZFS on Linux — [openzfs.org](https://openzfs.org)
- Silberschatz — *OS Concepts* — Chapters 13-14
