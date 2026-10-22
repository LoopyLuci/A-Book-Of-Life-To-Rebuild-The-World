# Quantum Error Correction

> **Domain:** quantum | **Difficulty:** master | **Safety:** green

*Reference material only. Verify this information against primary sources
and qualified professionals before acting on it. This entry is not a sole
source of information.*

## Overview

Quantum error correction is the only route to a machine that computes for
long enough to matter, because no physical qubit is good enough to run a
useful algorithm alone. The key principle is that the redundancy must be
matched to the type of error: a classical syndrome bit detects a bit flip,
a different syndrome bit detects a phase flip, and an ancilla that measures
the joint parity detects both. A code of distance d corrects
floor((d-1)/2) errors and detects d-1, and below a threshold error rate the
extra qubits buy a logical error rate lower than the physical one.

## Prerequisites

- Quantum gates, the Pauli group, and the stabilizer formalism
- Density matrices, the Bloch sphere, and noisy channels
- Elementary coding theory for the classical codes used inside quantum ones
- A working classical simulator and a circuit drawing tool

## Materials & Tools

- A state-vector simulator and a stabilizer simulator for small codes
- A density-matrix solver for the noise model of a single round
- Randomised benchmarking data for the platform under study
- A reference implementation of a minimum-weight perfect matching decoder
- Tables of logical error rate against code distance and physical error
- A spreadsheet or script for the physical and logical error budgets

## Procedure

### Classify the error

1. Separate bit-flip (X), phase-flip (Z), and combined (Y) errors, and note
   that a depolarizing channel produces all three at once.
2. Attach a noise model to each gate, and start from a single-qubit
   depolarizing rate of 1e-3 and a two-qubit rate of 1e-2, which is
   realistic for superconducting qubits.
3. Include the measurement error in the model, because a faulty syndrome
   readout can create a data error that did not exist.

### Choose the code

1. Fix the target logical error rate and the number of circuit cycles; the
   product is the number of independent chances to fail.
2. Compare code families: the nine-qubit Shor code corrects one error with
   nine qubits, the Steane code corrects one error with seven, and the
   surface code spends far more qubits to correct many more errors.
3. Check the Singleton bound, n - k >= 2(d-1), and remember that a
   subsystem code needs at least two copies for a logical two-qubit gate.

### Model the decoder and find the threshold

1. Compute the syndrome for every stabilizer round and find the
   minimum-weight error that explains it, using a minimum-weight perfect
   matching decoder for the surface code.
2. Keep the decoder latency below the syndrome round time, about
   1 microsecond on superconducting hardware, or the correction arrives too
   late to prevent the next error.
3. Sweep a ladder of distances, d = 5, 9, 13, and 17, and find the
   crossover where the logical error rate stops falling; expect about 1%
   for depolarizing noise and about 10% for erasure noise.

### Budget the overhead

1. Estimate the physical qubits needed; at a physical error rate of 1e-3
   and a target logical error rate of 1e-12, expect roughly 1e4 physical
   qubits per logical qubit.
2. Add the syndrome ancillas, one per stabilizer, so a distance-d surface
   code needs about d squared data qubits and d squared minus one ancillas.
3. Count the qubits that idle while the rest compute, and record the
   distance, the overhead, and the assumed physical error rate with the
   result.

## Safety Notes

- This is an analysis task, but the numbers decide whether a machine is
  worth building: never accept a claimed logical error rate that has not
  been measured on the noise model of the real hardware.
- A decoder slower than the syndrome round silently degrades the logical
  error rate, so measure the decoder latency on the target machine.
- Never reuse a decoder or a hardware configuration from a noiseless
  simulation; the error budget only holds on the real noise model.
- Keep the classical decoder away from the cryogenic stage and isolate the
  control hardware, so a fault in the decoder cannot act on the qubit
  state.
- Record the error budget and the code distance with the calibration data,
  because a device recalibrated without re-checking the budget may no
  longer be below threshold.
- Treat any claim of fault tolerance without a measured threshold as
  unproven, and say so in the write-up.

## Verification

- **Status:** draft
- **Tested by:** —
- **Date:** —

## Sources

- NIST Quantum Initiative Reference (public domain)
