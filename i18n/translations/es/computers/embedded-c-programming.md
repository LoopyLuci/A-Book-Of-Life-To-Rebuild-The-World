# Embedded C Programming

> **Domain:** computers | **Difficulty:** apprentice | **Safety:** green

*Reference material only. Verify this information against primary sources
and qualified professionals before acting on it. This entry is not a sole
source of information.*

## Overview

Embedded C is C written for a microcontroller with no operating system
underneath it. The programmer owns the memory map, the reset vector, and
the timing of every peripheral, so source that behaves on a desktop can
be wrong on bare metal. The key principle is that the datasheet, not the
tutorial, is the specification: every register access is a write to a
fixed address, and every delay depends on a clock the programmer set.

## Prerequisites

- C programming: pointers, structures, bitwise operators, and the
  preprocessor
- Digital logic and the ability to read a timing diagram
- DC Circuit Analysis
- Basic soldering and the use of a serial terminal program

## Materials & Tools

- A Cortex-M board, for example an STM32F103 or an RP2040, on headers
- ARM GCC cross compiler, GNU Make, and a linker script for the target
- ST-Link, CMSIS-DAP, or an equivalent debug probe
- USB serial adapter with 3.3 V logic levels, and a terminal program
- Oscilloscope or logic analyser with 3 or more channels
- The target's reference manual, datasheet, and errata sheet
- Breadboard, jumper wires, LEDs, a push button, and 330 ohm resistors
- Multimeter for checking the supply rails

## Procedure

### Set up the toolchain

1. Install the ARM GCC cross compiler and confirm that it targets the
   arm-none-eabi triple with the compiler version flag.
2. Write a linker script that places the vector table at the base of flash
   and the stack at the top of SRAM, then check the section sizes after
   every build with the size utility.
3. Compile a minimal program that drives one GPIO pin and blinks an LED
   at 1 Hz, and confirm the reset behaviour of the board.

### Map the registers

1. Read the memory map in the reference manual and write down the base
   address and the bit positions of every register you intend to use.
2. Declare the peripheral structures as volatile pointers in a header file
   so that the compiler cannot cache a register value in a CPU register.
3. Enable the peripheral clock in the reset and clock control block, then
   confirm the clock is running by measuring a pin with a scope.

### Use interrupts and timers

1. Configure a 1 kHz tick from the system timer using the 24-bit reload
   value from the reference manual, and allow for the count starting at 0.
2. Write the interrupt service routine with the standard name and the
   attribute that tells the compiler to keep its stack frame small.
3. Enable the interrupt in the nested vector interrupt controller, clear
   the pending bit, and prove the timing by toggling a pin and measuring
   the period on the scope.

### Drive a peripheral and debug

1. Bring up the UART at 115200 baud, 8 data bits, no parity, and 1 stop
   bit, and confirm several hundred bytes arrive intact.
2. Keep the linker map file with every build so you can see which section
   grew after a change and how much flash and RAM are left.
3. Attach the debugger, set a breakpoint in the handler, and read the
   stack frame and the peripheral registers to confirm the state.

## Safety Notes

- A soldering iron tip resting on a board will destroy the chip or the
  USB interface; work on an anti-static mat and set the iron temperature
  for the joint, not the board.
- Fit current limiting resistors of 330 to 1000 ohm on every LED and on
  any pin that drives an indicator, so a firmware fault cannot weld a
  driver or burn a trace.
- Lithium cells in a battery-powered board can vent and start a fire if
  they are shorted or overcharged; use a protected cell and never leave a
  charging board unattended.
- Firmware bugs act on real outputs the moment they are flashed. Test new
  firmware on the bench with the actuators disconnected, and keep a
  documented recovery path such as a bootloader or a hardware reset.
- Observe the electrostatic discharge precautions for the microcontroller,
  the probe, and any USB adapter, and ground yourself before handling.
- Keep low-voltage logic wiring away from mains wiring, and never rely on
  a firmware watchdog alone to make a system safe.

## Verification

- **Status:** draft
- **Tested by:** —
- **Date:** —

## Sources

- Arm Cortex-M Documentation (public domain)
