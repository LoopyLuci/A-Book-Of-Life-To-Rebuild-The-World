# Firmware and Real-Time Operating Systems

> **Domain:** computers | **Difficulty:** journeyman | **Safety:** green

*Reference material only. Verify this information against primary sources
and qualified professionals before acting on it. This entry is not a sole
source of information.*

## Overview

Firmware is the program that owns a machine the moment it is powered, and
a real-time operating system is the small layer that decides what runs
when. The key principle is that a deadline is a requirement, not a wish: a
task that must answer in 10 ms has to be scheduled and budgeted, and the
design is finished only when the worst case has been measured on the
target rather than estimated on a desk.

## Prerequisites

- Embedded C and the C standard library
- Reading a microcontroller datasheet and its reference manual
- Binary and hexadecimal numbers, and bit masking
- Basic electronics: logic levels, pull-ups, and open-drain buses

## Materials & Tools

- A supported microcontroller board and a USB debug probe
- The Arm GCC toolchain and a make-based build, or an equivalent
- The FreeRTOS kernel source and the vendor port for the device
- A logic analyser for timing checks and an oscilloscope for analogue
- A multimeter, a solderable prototype board, and jumper wire

## Procedure

### Choose the architecture

1. List every job the firmware must do and the deadline attached to it.
2. Separate the work into tasks by deadline, not by whichever grouping is
   easiest to write.
3. Give the shortest deadline the highest priority, and move slow work out
   of the interrupt context into a task or a deferred handler.

### Write the tasks

1. Give each task its own stack, sized from measured high-water marks
   rather than from a guess, and check those marks at run time.
2. Keep every critical section short and never call a blocking function
   from inside one.
3. Protect shared data with a mutex or a semaphore, and hold it for the
   shortest possible time.
4. Pass data between tasks through a queue where you can, and set the tick
   rate to something the design can afford.

### Meet the deadlines

1. Use a periodic timer interrupt for sampling at a fixed rate and push
   the result into a queue instead of processing it in the handler.
2. Measure the worst-case execution time of every task with a cycle
   counter or with a GPIO toggle read by a logic analyser.
3. Record the jitter of each periodic task over a long run, since a task
   that meets its average but misses its worst case is not finished, and
   enable the watchdog fed from the task that knows the system is alive
   rather than from the interrupt that starts the work.

### Ship and observe

1. Build with optimisation and with debug symbols, keep the map file, and
   assert on the queue depths and the stack high-water marks so the
   numbers are logged over a serial link.
2. Save one binary image per board revision, put the version in a header
   the firmware can read back, and test the power-on path and the
   brown-out path so both land in a known state without a manual reset.

## Safety Notes

- Firmware drives relays, valves, heaters, and motors, so every state the
  machine can enter after a reset must be made safe by hardware, not by
  the code.
- A watchdog fed from an interrupt instead of from the work will not
  catch a hung task.
- A watchdog reset can leave actuators in an unknown state, so define the
  safe state for the reset path explicitly.
- Never trust an unvalidated buffer from a radio or a sensor; bound every
  length and reject malformed frames.
- Removing a debug assertion to ship a release also removes the check it
  was making, so keep the checks and log the failure instead.
- The debug probe and the target share a supply rail, and a mis-wired
  probe can destroy the microcontroller.

## Verification

- **Status:** draft
- **Tested by:** —
- **Date:** —

## Sources

- FreeRTOS Documentation (MIT)
