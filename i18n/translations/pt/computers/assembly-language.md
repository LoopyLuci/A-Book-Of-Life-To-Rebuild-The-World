# Assembly Language and the Machine Model

> **Domain:** computers | **Difficulty:** journeyman | **Safety:** green

*Reference material only. Verify this information against primary sources
and qualified professionals before acting on it. This entry is not a sole
source of information.*

## Overview

Assembly is the text form of what the processor actually executes. It
shows how the machine moves data between registers and memory, how it
branches, and how the stack is used, which makes it the right tool for the
parts of a system where time or memory cannot be wasted. The key principle
is that the architecture is a contract: the instruction encoding, the
register set, and the calling convention are all fixed, so code that obeys
them stays correct across compilers, libraries, and future revisions.

## Prerequisites

- Embedded C Programming
- Binary and hexadecimal number systems
- Boolean logic and two's complement
- Reading a memory map and a processor datasheet

## Materials & Tools

- Cortex-M board with a debug probe, or a host machine with a disassembler
- ARM GCC toolchain, including the objdump and nm utilities
- Reference manual for the instruction set and the memory map
- Text editor with a hexadecimal view
- Logic analyser for observing pin and bus timing
- A test script or terminal program that drives a known input

## Procedure

### Learn the instruction set

1. List the register set of the architecture: 13 general purpose registers
   from R0 to R12, plus the stack pointer, the link register, and the
   program counter, and the flags holding negative, zero, carry, and
   overflow.
2. Write down the addressing modes, from register and immediate through
   register offset and register indirect to stack push and pop, with a
   one-line example of each.
3. Note the encodings: 16-bit instructions in the base encoding, 32-bit
   instructions in the wide encoding, and that a 32-bit instruction must
   sit on a 4-byte boundary.

### Read a disassembly

1. Compile a small C function with debug information and disassemble it
   with the objdump utility, then match each C line with its instructions.
2. Identify the prologue that saves the registers, the body, and the
   epilogue that restores them and returns through the link register.
3. Find the stack frame size in the listing and confirm that it matches
   what the compiler reports for the same function.

### Write a routine

1. Write a function in assembly that takes two arguments in the first two
   registers and returns a result in the first, following the procedure
   call standard.
2. Keep the stack pointer 8-byte aligned at every call boundary and check
   the alignment before returning.
3. Test the routine against a C implementation over many inputs and
   compare the results value by value.

### Mix with C and profile

1. Mark a routine as naked only where it is needed, and let the compiler
   manage the registers around the call everywhere else.
2. Measure the cycle count with the core's cycle counter and compare it
   with the same work written in C at each optimisation level.
3. Read the linker's map file to see how much flash and RAM the assembly
   saved, and keep it only where the saving is worth the maintenance.

## Safety Notes

- A routine in assembly can drive an output pin to any state the instant
  it runs, and an infinite loop inside an interrupt handler will trip the
  watchdog or hang the machine. Prove the new code with the actuators
  disconnected.
- Writing to the wrong address in assembly corrupts memory and peripheral
  registers without warning. Check every address against the memory map
  before you write to it, and confirm that the region is executable and
  not protected.
- Respect the alignment rules of the core; an unaligned 32-bit access
  faults on some devices and silently costs cycles on others.
- Single-stepping changes the timing of the program, so do not debug a
  control loop by stepping through it. Use a trace buffer or a logic
  analyser instead.
- Keep a hardware reset, a bootloader, or a recovery image available, and
  test the recovery path before you depend on it.
- Treat assembly as unmaintainable by default: keep it small, commented
  with the register usage, and covered by the C reference test.

## Verification

- **Status:** draft
- **Tested by:** —
- **Date:** —

## Sources

- Arm Cortex-M Documentation (public domain)
