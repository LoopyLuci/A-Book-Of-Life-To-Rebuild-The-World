# Surface and Lattice Codes

> **Domain:** quantum | **Difficulty:** master | **Safety:** green

*Reference material only. Verify this information against primary sources
and qualified professionals before acting on it. This entry is not a sole
source of information.*

## Overview

The surface code puts physical qubits on a two-dimensional lattice and uses
local four-qubit stabilizers, so a logical qubit is a property of the whole
patch rather than of any one qubit. It is the default choice for a
near-term machine because the stabilizers can be measured locally and in
parallel, the decoder works on a small classical graph, and the distance
grows as the square root of the qubit count. The key principle is that a
logical error is a string of faults spanning the patch, so the code
distance is the size of the smallest damage the code cannot absorb.

## Prerequisites

- The stabilizer formalism and the definition of a code distance
- Elementary graph theory: paths, matchings, and boundary conditions
- Circuit-level noise modelling with a density-matrix simulator
- The general principles of quantum error correction

## Materials & Tools

- A stabilizer simulator and a density-matrix simulator for small patches
- A circuit library with lattice patch and stabilizer round schedules
- A minimum-weight perfect matching decoder, such as pymatching
- A sampling tool to sweep a physical error rate over a code distance
- Reference layouts for the rotated, unrotated, and color-code geometries
- A spreadsheet for tracking the logical error rate against distance

## Procedure

### Lay out the patch

1. Place the data qubits on a square grid of side d, so a distance-7 patch
   holds 49 data qubits.
2. Add the stabilizer qubits; the rotated surface code uses one ancilla per
   stabilizer and needs 48 for that patch, 97 qubits in all.
3. Choose the boundary conditions, one rough and one smooth boundary for
   one logical qubit, and check the layout against the coupling map of the
   hardware.

### Schedule the syndrome round

1. Measure the weight-4 X and weight-4 Z stabilizers in parallel, with one
   round of ancilla interaction per stabilizer.
2. Repeat the round at the cycle rate of the hardware, about 1 microsecond
   on superconducting qubits, and reset the ancillas between measurements.
3. Tag every syndrome with its round index, since a mis-assigned round
   turns a recoverable data error into an undecodable one.

### Decode the syndrome

1. Convert each round's syndrome into an edge-flip graph and find the
   minimum-weight set of edges consistent with it.
2. Apply the boundary conditions, so that a chain running from a rough to a
   smooth boundary is read as a logical error rather than as a repair.
3. Use the union-find or belief-propagation decoder when the patch is too
   large for the matching solver to run inside the round time.

### Pick the variant and estimate the error rate

1. Compare the rotated and unrotated layouts, and compare against a color
   code, which reaches the same distance with fewer qubits at low distance
   but needs a more complex decoder.
2. Count the fault-tolerant gates: lattice surgery needs about two extra
   logical qubits per gate, so the 2 to 3 qubits of a single gate become 8
   to 12 in the workspace.
3. Sweep the physical error rate from 1e-4 to 1e-1 for each distance, find
   the threshold, and multiply the logical error rate per round by the
   number of rounds to get the error rate for the whole computation.

## Safety Notes

- This is desk and simulator work; the physical hazards are the cryostat
  and the microwave equipment, which belong to their own procedures.
- Never trust a logical error rate fitted on a noise model that has not
  been checked against the measured gate and readout errors of the device.
- Beware of distance inflation: a lattice that does not fit the coupling
  map has a shorter effective distance than its drawn size suggests, and
  this must be stated rather than assumed away.
- Keep the decoder and the control electronics off the low-temperature
  stage, and check the thermal budget whenever ancillas are added.
- Do not report a threshold from a simulation without the number of shots
  and the confidence interval, because a single lucky sweep looks like a
  threshold.
- Treat a large logical qubit count as a schedule and a cost risk, and
  carry it in the project plan rather than in a footnote.

## Verification

- **Status:** draft
- **Tested by:** —
- **Date:** —

## Sources

- NIST Quantum Initiative Reference (public domain)
