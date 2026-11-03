# Quantum Gates and Gate Fidelity

> **Domain:** quantum | **Difficulty:** journeyman | **Safety:** green

*Reference material only. Verify this information against primary sources
and qualified professionals before acting on it. This entry is not a sole
source of information.*

## Overview

A quantum gate is a unitary operation applied to one or more qubits, and
the useful measure of a gate is not whether it is right but how close it
lands to the intended state. The key principle is that errors accumulate
with the number of gates, so the fidelity of the whole circuit sets the
size of the problem that can be run at all. Measuring that fidelity
honestly is therefore the centre of the work.

## Prerequisites

- Linear algebra over the complex numbers: vectors, matrices, and
  unitarity
- The Bloch sphere and the action of the common gates
- Probability and the statistics of repeated measurement
- Basic microwave control of a qubit

## Materials & Tools

- A quantum SDK able to build and run circuits on a real backend
- A simulator for the ideal case and for the noise models
- A hardware backend with a pulse-level interface
- An analysis script that computes the average gate fidelity
- A logbook or versioned file for every calibration record

## Procedure

### Know the gate set

1. Write down the native gates of the hardware and their ideal matrices:
   the X, Y, and Z rotations, the phase gate, and the entangling gate.
2. Express every logical operation in terms of those, and keep the
   decomposition short, because each extra gate adds error.
3. Remember that a 90 degree rotation is a pi over two angle, that the
   compiler expects radians, and that the phase gate costs no pulse.

### Calibrate a single qubit

1. Run a Rabi oscillation sweep and read the drive frequency and the
   amplitude from the fit.
2. Run a Ramsey sequence, find the frequency offset from the detuning
   curve, and correct the drive frequency.
3. Measure the relaxation and dephasing times of the same qubit and record
   them, since they bound the gate fidelity that can be reached.
4. Repeat the sweeps after a cooldown and record the drift; a device that
   moves by more than a few percent between sessions needs a daily
   calibration.

### Measure the fidelity

1. Run randomised benchmarking, in which long sequences of random Clifford
   gates are compiled to the hardware and each sequence is followed by
   its inverse.
2. Fit the reference decay, take the decay constant p, and turn it into
   an average error per Clifford of 24 over 23 times one minus p for
   single-qubit benchmarking.
3. Divide by the mean number of native gates in a Clifford, about 1.9 for
   single-qubit gates, to get the per-gate error.
4. Repeat with several seeds and report the spread rather than a single
   number, and cross-check with cycle benchmarking when a two-qubit gate
   needs its own figure.

## Safety Notes

- Calibrations drive real hardware, and the microwave power used for the
  amplitude sweeps is enough to damage the qubit if it is left on.
- A qubit left excited keeps dumping heat into the refrigerator, so
  reset the device between experiments.
- Calibration records are the only record of how the machine was
  behaving; keep them with the data and never overwrite a run without
  writing down the reason.
- Randomised benchmarking needs a large sample to give a tight error bar,
  and a small run can report a fidelity that is too optimistic.
- Do not compare fidelities taken with different compilation settings or
  different qubit counts without saying so.
- The simulator has no decoherence, so a circuit that works in simulation
  says nothing about whether it will run on the hardware.

## Verification

- **Status:** draft
- **Tested by:** —
- **Date:** —

## Sources

- NIST Quantum Initiative Reference (public domain)
