# DC Circuit Analysis

> **Domain:** computers | **Difficulty:** novice | **Safety:** green

*Reference material only. Verify this information against primary sources
and qualified professionals before acting on it. This entry is not a sole
source of information.*

## Overview

DC circuit analysis is the discipline of turning a drawing into numbers
you can check. The key principle is that every network obeys two
conservation laws, conservation of charge and conservation of energy,
and that every method, from a simple series divider to node analysis,
is only bookkeeping for those two statements. Solve the network twice
by two different methods; if the answers disagree then one of them is
wrong, and the disagreement is the cheapest fault-finding tool there
is.

## Prerequisites

- None

## Materials & Tools

- Paper, a pencil, and an eraser for the working
- A calculator
- A bench supply, 0 to 30 V, with a current limit
- A digital multimeter with a continuity and a diode function
- Resistors in the E12 series, 0.25 W, and a few capacitors and coils
- A solderless breadboard, jumper wires, and a battery for the test
  circuits

## Procedure

### Set up the network

1. Draw the circuit, label every node, mark the reference node as
   ground with a 0 V label, mark the direction of every current and the
   polarity of every source, and write the value of every component
   next to its symbol.
2. Reduce the network step by step: combine the resistors in series
   into one and the resistors in parallel into one, before writing any
   equation.

### Apply Ohm's law

1. Compute the total resistance of a series chain by adding the
   resistances, and check that the result is larger than the largest
   single resistor.
2. Compute an equivalent parallel resistance from 1/R = 1/R1 + 1/R2 +
   the rest, and check that it is smaller than the smallest single
   resistor.
3. Use the voltage divider V_out = V_in x R2 / (R1 + R2) for a series
   pair, and the current divider I = I_total x R_other / (R1 + R2) for a
   parallel pair.

### Apply Kirchhoff's laws

1. Sum the currents entering a node and set the sum to zero, using a
   sign convention and writing the direction of each current beside the
   equation.
2. Sum the voltage changes around any closed loop and set the sum to
   zero, remembering that a rise is positive and a drop is negative.
3. Solve the simultaneous equations, then check the answer against the
   source: the power leaving the source must equal the power in the
   resistors, with P = V x I = I^2 x R = V^2 / R.

### Find the equivalent source

1. Remove the load and measure the open-circuit voltage for the
   Thevenin voltage, then short the independent voltage sources, open
   the independent current sources, and measure the resistance across
   the terminals for the Thevenin resistance.
2. Convert to the Norton form with I_N = V_th / R_th and the same
   resistance, then load the equivalent source with the real load and
   check that the current and the voltage match.

### Verify by superposition and measurement

1. Solve the network again with one source at a time and the others
   set to zero, then add the results; the total must match the first
   answer.
2. Build the circuit on the breadboard, apply the supply with the
   current limit set low, and measure the node voltages against the
   calculation; check that no resistor is dissipating more than its
   rating, because a 0.25 W resistor at full rating can reach 100 °C
   and is a fire hazard.

## Safety Notes

- Keep the work at low voltage and low current. Mains voltage is
  lethal, and 230 V across the body can stop the heart.
- A short circuit across a battery or a large supply can produce
  thousands of amps: set the current limit, fit a fuse of the right
  rating, and keep a hand on the switch.
- Charge every capacitor through a resistor before handling it, and
  discharge the large ones with a proper discharge tool rather than a
  screwdriver.
- Resistances get hot when the power is wrong; keep within the rating
  and leave a gap between the parts so that the heat can get away.
- Protect the work from static discharge: use a grounded wrist strap
  and a grounded mat for the components that cannot tolerate a shock.
- Check the polarity of every electrolytic capacitor and every diode
  before energising the circuit; reverse polarity destroys parts and
  can start a fire.

## Verification

- **Status:** draft
- **Tested by:** —
- **Date:** —

## Sources

- OpenStax University Physics (CC BY)
