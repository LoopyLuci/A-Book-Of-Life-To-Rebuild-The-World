# Operating System Concepts

> **Domain:** computers | **Difficulty:** journeyman | **Safety:** green

*Reference material only. Verify this information against primary sources
and qualified professionals before acting on it. This entry is not a sole
source of information.*

## Overview

An operating system is the layer that turns hardware into a place where
programs run without stepping on one another. It owns the processor time,
the memory map, and the files, and it exposes those through system calls
and a filesystem namespace. The key principle is that the kernel enforces
the boundaries: a process may only touch the memory and the files the
kernel grants it, and everything above the kernel, including the shell,
the compiler, and the database, assumes that enforcement is real.

## Prerequisites

- Embedded C Programming
- Computer architecture and the memory hierarchy
- C with pointers and file handling
- Command line use and a text editor

## Materials & Tools

- A machine running Linux, plus a second machine to act as a peer
- Kernel documentation or source matching the running kernel version
- Build tools: compiler, linker, and make
- Shell, core utilities, and a terminal multiplexer
- System call tracer, process inspector, and packet sniffer
- A spare disk or a virtual disk image for filesystem experiments
- A load generator and a small scripting harness

## Procedure

### Follow a process

1. Start a program and inspect its identifier, its parent, its state, and
   its open file descriptors in the process table.
2. Trace its life from the fork and exec through to exit, and note which
   system calls the kernel handled on its behalf.
3. Measure the cost of a context switch and of creating a process, and
   compare both with the same work done inside one process.

### Schedule and synchronise

1. Start several processes competing for the processor and watch the run
   queue and the scheduling policy the kernel reports for them.
2. Change the priority of one process, confirm the scheduler responds,
   then restore the original priority.
3. Reproduce a race with two threads sharing a counter, fix it with a
   mutex, and confirm the count is exact over many runs.

### Manage memory

1. Inspect the address space of a running process and locate its code,
   data, heap, stack, and shared mappings.
2. Set a memory limit on a test process and watch it fail in a controlled
   way, then read the error the kernel returns.
3. Copy a large file and measure the effect of the page cache and of the
   read and write buffer sizes on throughput.

### Use the filesystem

1. Create a directory tree, list the inodes and file types, and compare
   the on-disk layout with the logical tree.
2. Fill a small filesystem until it reports an error, then check which
   operations still succeed and which fail cleanly.
3. Copy a tree with a checksum tool, corrupt one byte in the copy, and
   confirm that verification reports the damaged file.

## Safety Notes

- Run unfamiliar code as an ordinary user, never as the superuser, and
  never on the only machine that holds a copy of the data.
- Destructive commands such as removing a directory recursively do not
  check what they are pointed at. Dry-run the command, read the path
  twice, and never run it on a mounted network filesystem by accident.
- Killing a process that owns a database can leave the data inconsistent.
  Stop services in an orderly way so they can close and flush their files.
- A filesystem that fills up corrupts databases before it reports the
  error. Keep a margin of free space and monitor it.
- Understand the mount options before mounting anything: a sync, noexec,
  or nosuid setting changes what the filesystem will allow.
- Permissions and ownership mistakes expose private files. Review the
  group and mode of new shared directories and files.
- Back up before experimenting with partitions, and remember that a
  filesystem can lose the last writes if the machine is powered off
  without a flush.

## Verification

- **Status:** draft
- **Tested by:** —
- **Date:** —

## Sources

- Linux Kernel Documentation (public domain)
