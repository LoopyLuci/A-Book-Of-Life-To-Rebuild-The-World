# Quantum Simulation of Chemistry

> **Domain:** quantum | **Difficulty:** master | **Safety:** green

*Reference material only. Verify this information against primary sources
and qualified professionals before acting on it. This entry is not a sole
source of information.*

## Overview

Quantum simulation of chemistry aims at the electronic structure of a
molecule, where the size of the state space grows as the square of the
number of basis functions and the exact answer is out of reach for anything
but a handful of electrons. The key principle is that the molecule is
mapped onto qubits, the fermionic Hamiltonian is rewritten as a sum of
Pauli operators, and the energy is measured as the expectation value of
that Hamiltonian in a prepared state. The method with a chance of working
is variational: a classical optimiser steers a parameterised ansatz while
the quantum computer supplies the expectation values.

## Prerequisites

- Molecular orbital theory and the Hartree-Fock method
- Second quantisation, creation and annihilation operators, and fermionic
  anticommutation
- The Pauli group and the mapping of a fermionic operator onto it
- Linear algebra in the space of 2^n states, and the variational principle

## Materials & Tools

- A quantum chemistry package for the geometry, the integrals, and the
  Hartree-Fock orbitals
- A quantum SDK with a chemistry module and an estimator primitive
- The mapping you intend to use: Jordan-Wigner, Bravyi-Kitaev, or tapering
- A basis set and an active-space choice, for example aug-cc-pVDZ with a
  frozen core
- An optimiser such as COBYLA, or the built-in variational driver
- Reference energies from a classical correlated method, for validation

## Procedure

### Build the molecular Hamiltonian

1. Choose the geometry, optimise it classically, and compute the
   Hartree-Fock orbitals and the one- and two-electron integrals in the
   chosen basis.
2. Set the active space by freezing the core orbitals, and write the
   second-quantised Hamiltonian with its one-body and two-body terms.
3. Estimate the size: an n-orbital molecule needs 2n spin-orbitals and so
   2n qubits for a full active space, and record the Hartree-Fock and
   correlation energies as the baseline.

### Map the operators

1. Apply the Jordan-Wigner transform, which uses one qubit per
   spin-orbital and realises the parity of the fermions as a string of Z
   gates, so a two-body term acts on up to 2n qubits.
2. Consider the Bravyi-Kitaev transform, which shortens the parity string
   to O(log n) at the cost of a denser Hamiltonian.
3. Taper out the symmetries, which removes a factor of about 2^(n/2) of
   the qubits, and count the Pauli terms, which scale roughly as the
   fourth power of the number of orbitals.

### Prepare the state and optimise

1. Prepare the Hartree-Fock state with X gates on the occupied
   spin-orbitals, and verify that the circuit reproduces the classical
   Hartree-Fock energy within the statistical error.
2. Prepare the reference state for the parity sector being studied and
   build the ansatz, a unitary coupled-cluster ansatz of single and double
   excitations, then count the parameters.
3. Measure each Pauli term over many shots, grouping the commuting terms,
   and optimise with a classical optimiser from several starting points to
   avoid a local minimum.

### Validate the result

1. Compare the correlation energy with a classical coupled-cluster
   calculation, which sets the practical accuracy bar at about 1 kcal per
   mole, or 4.2 kJ per mole, for a chemical accuracy claim.
2. Report the basis set, the active space, and the number of parameters
   with the result, because they set the accuracy more than the ansatz
   does.
3. State the readout and error-mitigation overhead, use symmetry checks
   when the circuit noise is comparable to the correlation energy, and
   extrapolate the resources to a fault-tolerant machine.

## Safety Notes

- This is computational work; the practical hazards belong to the
  cryostat, the lasers, and the chemistry laboratory.
- Never report a correlation energy without the basis set and the active
  space, because a small basis makes the number meaningless.
- Validate the mapping by reproducing the Hartree-Fock energy on the
  hardware before trusting any correlated result.
- Keep the shot budget and the statistical error visible in every table,
  because an energy quoted to more decimals than the error is misleading.
- Remember that error mitigation scales poorly with circuit depth, so a
  mitigated result on a noisy device is not the same claim as one from a
  fault-tolerant device.
- Keep the classical reference calculations under version control, since
  the comparison is what makes the result checkable.

## Verification

- **Status:** draft
- **Tested by:** —
- **Date:** —

## Sources

- NIST Quantum Initiative Reference (public domain)
