# Quantum Software Stacks

> **Domain:** quantum | **Difficulty:** apprentice | **Safety:** green

*Reference material only. Verify this information against primary sources
and qualified professionals before acting on it. This entry is not a sole
source of information.*

## Overview

A quantum software stack is the layer between an algorithm and a processor:
the circuit you write is translated, mapped onto the qubits and gates of a
device, scheduled, submitted, and returned as counts or expectation values.
The key principle is that the simulator and the hardware are different
engines with different fidelity, so the workflow is to prove the logic in
an ideal simulator, then prove the mapping and the noise model on the
device, and only then to claim a result. The stack is what turns an idea
into a measurement somebody else can repeat.

## Prerequisites

- The circuit model: gates, qubits, measurement, and the basic algebra
- Python and the shape of a software development kit
- Linear algebra over the complex numbers, for the simulator
- Statistics for shot-based results and confidence intervals

## Materials & Tools

- A quantum SDK such as Qiskit, Cirq, or Braket
- Local simulators: a state-vector simulator, a density-matrix simulator,
  and a noise-sampling simulator
- The device properties file from the target processor, with the T1, T2,
  gate times, and error rates
- An intermediate representation such as OpenQASM 3 or QIR, for archiving
- A version control repository and a notebook for the experiment record
- A plotting tool for the results and a script to average repeats

## Procedure

### Write the circuit

1. Build the circuit in the SDK, keeping the parameters as named variables
   so that a sweep is reproducible.
2. Draw the circuit and check it by eye, counting the qubits and the gates
   against the design.
3. Export to OpenQASM 3 and read it back, because a round trip that
   changes the gate count means the front end is transforming something.

### Simulate

1. Run the ideal state-vector simulator for the exact answer, and keep the
   circuit below about 30 qubits, since a state vector of 2^30 amplitudes
   needs 17 GB at double precision.
2. Use the density-matrix simulator only for small noisy systems, since its
   memory grows as 4^n, and use a stabilizer or tensor-network simulator
   for wider circuits.
3. Add a noise model built from the device properties and simulate with
   shots, then compare the noisy distribution with the ideal one to see
   where the circuit is fragile.

### Transpile to the device

1. Set the target to the real device, so that the transpiler optimises for
   the actual couplers and the native gate set, for example rz, sx, and x
   with the entangling gate cx.
2. Let the transpiler choose the layout and then check it, because a
   layout that scatters the circuit across the chip costs a lot of
   two-qubit gates.
3. Let it route and count the added SWAP gates, since each SWAP is three
   two-qubit gates, and read the scheduling report for the depth before
   and after optimisation.

### Submit and report

1. Submit with a fixed seed and an explicit shot count so the run can be
   repeated, and choose the shots from the precision needed: 1000 shots
   give roughly 3% standard error on a probability near 0.5.
2. Save the raw result object with its calibration metadata, repeat the
   run on a different day to see the drift, and compute the expectation
   value with its confidence interval.
3. Report the transpiled circuit, its two-qubit gate count, the
   calibration round, and the averaging time, and archive the circuit,
   the seed, the properties file, and the raw results together.

## Safety Notes

- This is software work, but the real risk sits in the laboratory where
  the hardware runs: the cryostat, the lasers, and the microwave sources
  are governed by their own procedures.
- Never report an ideal-simulation result as a hardware result, and label
  clearly which engine produced every number.
- Never publish a result without the transpiled circuit and the
  calibration round, because that is what makes it checkable.
- Keep the credentials for the hardware and the cloud access out of the
  repository, and in a secret store with rotation.
- Do not run a job against a shared device without agreeing the queue
  priority and the shot budget with the owner of that device.
- Log the calibration data with the result, because a device that drifted
  silently will otherwise produce a plausible wrong answer.

## Verification

- **Status:** draft
- **Tested by:** —
- **Date:** —

## Sources

- NIST Quantum Initiative Reference (public domain)
