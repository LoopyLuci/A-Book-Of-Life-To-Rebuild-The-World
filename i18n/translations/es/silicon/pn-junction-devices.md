# P-N Junctions, Diodes and Transistors

> **Domain:** silicon | **Difficulty:** apprentice | **Safety:** green

*Reference material only. Verify this information against primary sources
and qualified professionals before acting on it. This entry is not a sole
source of information.*

## Overview

Doping silicon with a few parts per million of phosphorus or boron creates
n-type and p-type regions, and the junction between them is the basis of
every rectifier, switch, and amplifier. The key principle is that the
junction blocks one polarity and conducts the other, so the forward drop and
the current rating decide which part fits a given load. Almost every device
failure is thermal or a reverse-voltage exceedance, so the ratings on the
data sheet are the design.

## Prerequisites

- Atomic structure and electron band theory, at the basic level only
- Reading a data sheet: pinout, ratings, and the derating curve
- Using a multimeter, a bench supply, and a breadboard
- Soldering and Through-Hole Assembly for building the test circuits

## Materials & Tools

- Test parts: 1N4001 to 1N4007 rectifiers, 1N4148 small-signal diodes,
  2N3904 NPN and 2N3906 PNP transistors, and a logic-level MOSFET
- Resistors from 100 ohm to 10 kilohm, a 5 V supply, and a 100 mA current
  limit
- Digital multimeter, and an oscilloscope for the diode curve
- Breadboard, jumper wire, and a soldering iron
- Notebook for recording the measurements

## Procedure

### Build the model

1. Recall that an n-type region has electrons as the majority carriers and
   a p-type region has holes, and that the junction forms a depletion
   region with a built-in potential of about 0.7 V in silicon.
2. Sketch the equilibrium, the forward-biased, and the reverse-biased
   conditions, and label the current direction in each.
3. Record the reverse rating of the part in hand: 1000 V for a 1N4007 and
   about 75 V for a 1N4148.

### Measure a diode

1. Wire the diode in series with a 1 kilohm resistor across a 5 V supply
   and measure the forward voltage at 1 mA; expect 0.55 to 0.75 V.
2. Measure the reverse leakage at 10 V; it should sit in the nanoamp range
   for a good silicon diode.
3. Measure the forward voltage at 25 °C and again at 60 °C; the forward
   voltage falls by about 2 mV for each degree.
4. Compute the dissipation as current times the forward voltage and compare
   it with the package rating; a 1N4007 carries 1 A at 75 °C with 5 cm of
   lead.

### Measure a transistor and choose a device

1. Identify the pin order for the package in hand: E-B-C for the 2N3904 and
   G-D-S for a TO-220 MOSFET, and confirm it with the continuity function.
2. Measure the base-emitter and base-collector voltages, then drive 10 uA
   into the base and measure the collector current to get hFE; expect 100
   to 300 for a small-signal NPN.
3. Confirm that the collector current stays below 1 uA with the base open,
    and treat anything higher as a possibly leaky part.
4. Size a rectifier at twice the load current with a reverse rating above
    the peak of the supply, and size a switch on its on-resistance at the
    actual gate voltage rather than the headline figure.
5. Add a 10 to 100 ohm gate resistor and a 100 kilohm pull-down on any
    floating gate, then fuse every branch that a failed short could
    reach.

## Safety Notes

- Most of this work is low voltage and low energy: keep the supply under
  30 V and the current under 1 A.
- Exceeding the reverse rating destroys the part, and a MOSFET avalanche
  can permanently damage the gate oxide.
- A MOSFET gate holds charge; discharge it through a resistor before
  handling the device and never touch it with a soldering iron.
- A failed rectifier can fail short and start a fire; fuse the branch and
  keep the current limit set on the bench supply.
- Reverse-connecting a battery destroys semiconductors instantly; check the
  polarity before the first power-up.
- Do not exceed the maximum power dissipation of the package, and derate it
  for the ambient temperature.

## Verification

- **Status:** draft
- **Tested by:** —
- **Date:** —

## Sources

- NIST Semiconductor Reference (public domain)
