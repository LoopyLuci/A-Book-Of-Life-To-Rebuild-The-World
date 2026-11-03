# Compilers, Linkers and Build Systems

> **Domain:** computers | **Difficulty:** journeyman | **Safety:** green

*Reference material only. Verify this information against primary sources
and qualified professionals before acting on it. This entry is not a sole
source of information.*

## Overview

A build turns source into a binary through stages that are usually hidden:
preprocessing, compilation to assembly, assembly to an object file, and
linking of objects into an executable. Knowing each stage turns a
toolchain from a mystery into a tool, because most confusing failures, a
missing symbol, a sudden jump in size, a binary that differs between
machines, belong to one stage and have one fix. The key principle is that
every stage produces an artifact you can read, so a build should always be
inspectable rather than a black box.

## Prerequisites

- C programming and the preprocessor
- Embedded C Programming
- Command line use and a text editor
- Basic knowledge of files and directories

## Materials & Tools

- GNU toolchain: compiler, assembler, linker, archiver, objdump, nm, size
- GNU Make, or another build driver
- A small project with a header, two source files, and a test program
- Object and hex file viewers, plus a version control system
- A build directory kept separate from the source tree
- A manifest that pins the compiler version and the flags

## Procedure

### Follow the stages

1. Run the preprocessor alone and read its output, then compile to
   assembly and read that, so you know which stage a fault comes from.
2. Produce object files and inspect the section headers: the text, data,
   read-only data, and bss sections, together with the symbol table.
3. Link the objects into an executable and inspect the entry point and
   the map of what the linker placed where.

### Control the build

1. Write a makefile with explicit rules, phony targets, and one
   dependency file per source file, so a header change rebuilds every
   file that includes it.
2. Keep one target per output and the compiler command in a single
   variable, so no two rules can disagree about the flags.
3. Enable per-function sections and the linker option that discards
   unused sections, then measure the change in the map file.

### Link deliberately

1. Choose static or shared linking per component, and note that a shared
   library adds a version dependency to every machine that runs it.
2. Make the entry point, the start-up files, the stack, and the heap
   explicit in the linker script instead of accepting the defaults.
3. List the symbols left in the binary and strip the ones that were only
   needed for debugging before you release it.

### Make the build reproducible

1. Fix the toolchain version, the flags, and the environment in a manifest
   file that the build reads, so every machine compiles the same way.
2. Strip absolute paths from the object files with the source path
   remapping flag, and set the source date epoch variable to a fixed value.
3. Build the same commit twice on two different machines and compare the
   checksums of the outputs; they should be identical.

## Safety Notes

- A build script runs arbitrary code with your permissions. Only build
  from sources you have read and trust, and review any new build file
  before you run it.
- A make rule that deletes files can be triggered by a mistyped target
  name. Keep destructive commands out of rules, or guard them with a
  prompt, and never run an untrusted makefile as an administrator.
- Do not disable the stack protector, the fortify source checks, or the
  warnings to make a build pass; each of those catches a real defect.
- Debug information and symbol tables in a released binary reveal file
  paths, usernames, and internal structure. Strip them before shipping.
- Pin the toolchain version and record it with the build, because a
  compiler upgrade can change floating point results, struct layout, and
  optimisation output without any source change.
- Watch disk space and build time; a runaway include or an unbounded
  dependency loop can fill a volume and stall the pipeline.

## Verification

- **Status:** draft
- **Tested by:** —
- **Date:** —

## Sources

- GNU Toolchain Manual (public domain)
