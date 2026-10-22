# Quantum Circuit Construction

> **Domain:** quantum | **Difficulty:** apprentice | **Safety:** green

*Reference material only. Verify this information against primary sources
and qualified professionals before acting on it. This entry is not a sole
source of information.*

## Overview

A quantum circuit is a written recipe: a list of gates on a list of qubits,
followed by measurements. The key principle is that the circuit you write
is not the circuit that runs, because the compiler must first map it onto
the gates and the connections the hardware actually has. Learning to read
that translation, and to keep the two circuits close to each other, is the
practical skill.

## Prerequisites

- Complex vectors and matrix multiplication
- The Bloch sphere and the single-qubit gates
- Basic Python or another scripting language
- The rules of a quantum circuit: no cloning, and measurement destroys

## Materials & Tools

- A quantum SDK such as Qiskit, Cirq, or Braket
- A state-vector simulator for small circuits, up to about 20 qubits
- A hardware backend and its published calibration data
- A notebook or file holding the circuit and its expected output
- A local copy of the noise model for the target device

## Procedure

### Write the circuit

1. State the question the circuit answers before writing a single gate.
2. Build the circuit in layers, one gate at a time, and draw it to check
   that the wires are the qubits you meant.
3. Keep the gate count small, and prefer one entangling pair over several
   that overlap.
4. Add the measurements last, and remember that measuring early destroys
   the state for the rest of the circuit.

### Compile it

1. Send the circuit through the transpiler for the target backend and let
   it choose the native basis and the mapping.
2. Look at the layout the compiler picked: on a grid or heavy-hex
   connectivity, distant qubits are linked with swap gates that add error.
3. Choose the initial layout yourself when the circuit has a natural
   geometry, and compare the gate counts of both choices.
4. Set the optimisation level to 1 or 2, record which level produced the
   run you keep, and check the scheduled pulse times, because the
   compiler can insert idle time during which the qubit drifts.

### Run and read the result

1. Run the circuit many times and count the outcomes; a single shot tells
   you almost nothing.
2. Compare the histogram with the ideal simulation and state the
   difference as a number rather than as an impression.
3. Check the job metadata for the device calibration date, and refuse to
   report a number from a device that has not been calibrated.
4. Save the circuit, the compiled version, the seed, and the counts
   together, re-run with a different seed, and confirm the statistics
   agree before drawing any conclusion.

## Safety Notes

- A simulator can exhaust the memory of the machine: a state vector needs
  16 bytes per qubit, so 30 qubits needs 16 terabytes, and the
  stabilizer or density-matrix methods should be used instead.
- Never submit a circuit that holds a secret key in its gates to a shared
  device without reviewing it, because a circuit reveals a great deal
  about the data it was built from.
- Running on hardware costs queue time and cools the machine down, so
  batch the circuits and leave the device free for others.
- Measurement is destructive, and a circuit that measures early and then
  reuses the qubit gives a wrong answer rather than an error message.
- Do not report a hardware result without the device name, the
  calibration date, and the shot count, because none of them can be
  recovered later.
- A simulator with no noise will happily show a perfect result for a
  circuit that cannot run, so always state which one produced the
  numbers.

## Verification

- **Status:** draft
- **Tested by:** —
- **Date:** —

## Sources

- NIST Quantum Initiative Reference (public domain)
