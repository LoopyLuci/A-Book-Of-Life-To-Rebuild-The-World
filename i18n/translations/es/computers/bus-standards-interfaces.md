# Bus Standards and Signal Interfaces

> **Domain:** computers | **Difficulty:** apprentice | **Safety:** green

*Reference material only. Verify this information against primary sources
and qualified professionals before acting on it. This entry is not a sole
source of information.*

## Overview

A bus is an agreement about wires: what a logic level means, who is
allowed to drive the line, and how a receiver knows that a bit is valid.
The key principle is that every bus standard solves the same three
problems, drive strength, clocking, and arbitration, and that a device
which ignores any one of them fails intermittently rather than cleanly.
The three interfaces below cover most of what a workshop has to connect.

## Prerequisites

- Digital logic: push-pull, open-drain, pull-ups, and logic levels
- Reading a datasheet pin table and a timing diagram
- Serial framing: baud rate, data bits, parity, and stop bits
- Basic soldering and use of a multimeter or a logic analyser

## Materials & Tools

- A logic analyser able to decode UART, I2C, and SPI
- A microcontroller development board and a few breakout boards
- Pull-up resistor packs, 2 kOhm to 10 kOhm for I2C at 400 kHz
- 22 to 33 Ohm series resistors and 120 Ohm terminations for long runs
- A bench supply, a multimeter, and an oscilloscope

## Procedure

### UART

1. Agree the frame first: 8 data bits, no parity, and 1 stop bit, which
   gives 10 bits on the wire for every byte.
2. Set both ends to the same baud rate, and remember that a 2 percent
   error is usually tolerable while 5 percent is not.
3. Wire transmit to receive and receive to transmit, and tie the grounds
   together; a common ground is the part most often left out.
4. Confirm that the idle state is logic 1 and that a logic 0 marks the
   start bit, then check the logic levels at both ends before trusting
   the data and fit a level shifter for a 5 V to 3.3 V link.

### I2C

1. Pull SDA and SCL up to the supply through 2 kOhm to 10 kOhm, and check
   the rise time against the bus capacitance before raising the clock.
2. Address the devices with a 7-bit address, and remember that many
   parts use two separate addresses for their two voltage rails.
3. Read the address and register order from the datasheet, then confirm
   both on the analyser before trusting the sequence.
4. Check the setup and hold times in the timing diagram, keep the clock
   under 100 kHz for a first test, and reset a stuck bus with a
   nine-clock pulse rather than by holding SDA low.

### SPI

1. Wire the clock, the master input, the master output, and the chip
   select, and give every device its own select line.
2. Start in mode 0, clock idle low, with data sampled on the rising edge,
   then confirm the mode against the datasheet.
3. Keep the clock under 1 MHz for a first test, shorten the wires if the
   edges look rounded on the analyser, and fit 22 to 33 Ohm in series
   with the clock and the data lines to damp the ringing.
4. Read the full-duplex timing in the datasheet, including the delay
   between chip select going active and the first clock edge.

## Safety Notes

- Logic analysers and many development boards tie their ground to the
  host earth, so probing a high-voltage or mains circuit can destroy the
  analyser and start a fire.
- Check the supply rails of both ends before connecting a bus; a 5 V
  peripheral driving a 3.3 V input can destroy the controller.
- Never probe a live motor or heating circuit without a differential
  probe rated for the voltage.
- Keep a common ground between the two devices; a floating ground gives
  false data and can damage the ports.
- Keep the I2C pull-ups as short as the routing allows, because a long
  unterminated run radiates and produces intermittent faults.
- One shorted line takes down every device on the bus, so power the
  section down before rewiring it.

## Verification

- **Status:** draft
- **Tested by:** —
- **Date:** —

## Sources

- NXP and Analog Devices Interface Notes (public domain)
