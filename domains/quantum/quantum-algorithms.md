# Quantum Algorithms

> **Domain:** quantum | **Difficulty:** journeyman | **Safety:** green

*Reference material only. Verify this information against primary sources
and qualified professionals before acting on it. This entry is not a sole
source of information.*

## Overview

A quantum algorithm is a circuit whose value comes from interference
rather than from raw parallelism, and only a few families have been shown
to beat a good classical method on a real problem. The key principle is
that the algorithm has to be written as a reversible circuit built around a
controlled oracle, and the gain comes from the amplitude structure, not
from the number of states. Honest claims matter here, because a quadratic
search improvement and an exponential factoring improvement are very
different propositions.

## Prerequisites

- Complex amplitudes, phase, and interference
- The circuit model: unitary gates, ancillas, and measurement
- Elementary number theory: modular exponentiation, continued fractions, and
  the order of an element in a group
- Probability and the geometric series, for amplitude amplification

## Materials & Tools

- A simulator and a circuit editor such as Cirq or Qiskit
- A reference set of standard algorithms
- Number-theory software for the classical part of Shor's algorithm
- A shot budget plan for the sampling runs
- A record of the best classical runtime for the problem being solved

## Procedure

### Start from the query model

1. Write down what the algorithm queries, a function f on n bits or an
   oracle, and how many queries it needs.
2. Decide whether the oracle can be built reversibly, by computing it into
   ancillas and uncomputing them, and count the gates that costs.
3. Run the Deutsch-Jozsa case as the simplest instance: prepare the n-bit
   register and one ancilla, apply the oracle and a Hadamard to every
   input qubit, and read the output, where a constant function gives all
   zeros from a single query.

### Amplify with Grover

1. Build the oracle so it applies a phase of minus one to the marked
   states and plus one elsewhere, using about 2n gates for the
   multi-controlled phase, done by phase-swinging.
2. Apply the diffusion operator, which reflects the state about the mean,
   and repeat for r rounds, where r is the nearest integer to (pi/4) times
   the square root of N, the number of marked items.
3. Measure; the marked state appears with a probability of at least
   1 - 1/N, and the whole search costs O(sqrt(N)) queries against N for a
   classical scan, a quadratic gain of 2^(n/2) times and no exponential
   gain.

### Find a period with Shor

1. Pick a random a that is coprime to the number N being factored, and
   build the reversible modular exponentiation circuit for
   f(x) = a^x mod N, with about 4n to 8n qubits for an n-bit modulus.
2. Apply the quantum Fourier transform to the exponent register, measure,
   and use continued fractions on the result to recover a candidate factor
   of r, the order of a modulo N.
3. Take the greatest common divisor of the candidate with N and with
   a^(r/2) plus or minus 1 to extract a non-trivial factor, and repeat with
   a fresh a when the attempt fails.

### State the claim honestly

1. Report the query complexity against the best known classical complexity,
   not against exhaustive search.
2. Separate the algorithmic gain from the cost of fault-tolerant
   hardware; factoring a 2048-bit number is estimated to need millions of
   noisy qubits and hours of runtime.
3. Include the data-loading cost and note the cases where classical
   algorithms have caught up, since a query on a data structure can cost
   more than the quantum part saves.

## Safety Notes

- There is no physical hazard in this entry; the risk lies in the claim, so
  keep a written record of the classical baseline that any speed-up is
  measured against.
- Never present a simulation of a small instance as evidence of an
  asymptotic speed-up, and always give the instance size.
- Do not let a black-box or proprietary oracle hide its cost, because the
  oracle cost can exceed the speed-up it enables.
- Keep the logical-qubit and error-correction overhead in the estimate; a
  quadratic gain that needs 1e4 physical qubits per logical qubit is not a
  practical win.
- Record the number of shots and the confidence interval with every result
  that rests on sampling.
- Do not run a quantum algorithm on data that cannot be handed to a third
  party, since the readout itself leaks information about the computation.

## Verification

- **Status:** draft
- **Tested by:** —
- **Date:** —

## Sources

- NIST Quantum Initiative Reference (public domain)
