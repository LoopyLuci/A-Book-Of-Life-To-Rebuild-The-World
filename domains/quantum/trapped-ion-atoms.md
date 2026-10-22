# Trapped-Ion and Neutral-Atom Platforms

> **Domain:** quantum | **Difficulty:** master | **Safety:** red

*Reference material only. Verify this information against primary sources
and qualified professionals before acting on it. This entry is not a sole
source of information.*

## Overview

Trapped-ion and neutral-atom platforms manipulate single atoms rather than
patterns on a chip, which buys much longer coherence times and a different
error profile from a superconducting circuit. The key principle is that the
qubit is an internal atomic state, so it is protected by the atom's own
energy levels and the environment can be made almost perfectly quiet, while
the cost is that the gates are slow and the gates are optical. Ion traps
give the best single-atom control, and neutral-atom arrays give the largest
qubit count.

## Prerequisites

- Atomic structure, selection rules, and the fine and hyperfine structure
- Laser cooling, Doppler cooling, and resolved-sideband cooling
- Radio-frequency and microwave traps, and the secular and micromotion
  modes
- Two-qubit entanglement mechanisms, including Rydberg blockade
- Optical tweezers, and radial and axial confinement

## Materials & Tools

- An ultra-high-vacuum chamber with an ion pump and bake-out hardware
- A linear Paul trap, or an optical tweezer array with a high-NA objective
- Narrow-linewidth lasers, usually frequency-doubled, with chasers and
  frequency locks
- Radio-frequency and microwave sources with phase-locked synthesis
- Imaging: a photon-counting camera, or a high-NA objective with an
  atomic-vapour filter
- Field coils with a low-noise current supply and active cancellation

## Procedure

### Build the trap

1. Assemble the trap in vacuum and bake the chamber at 150 °C for at
   least 24 hours, since a single layer of water molecules is enough to
   shorten an ion's lifetime.
2. Light the trap from several directions, find the electric field nulls,
   and cancel the micromotion by trimming the DC voltages until the RF
   amplitude modulation is below 1%.
3. For a neutral-atom array, focus the tweezers to a 0.5 to 1 micrometre
   waist at 532 nm, load the atoms from a magneto-optical trap, and
   rearrange them into the target geometry.

### Load and cool

1. Load the ions from a neutral atomic beam and photoionise them in place,
   or load the atoms from a magneto-optical trap and transfer them to the
   tweezer array.
2. Cool the motion with Doppler cooling to the Doppler limit, near
   0.5 mK for the light species, then close the cooling transition and use
   resolved-sideband cooling to reach a few hundred microkelvin.
3. Match the cooling scheme to the trap; if the trap is shallower than the
   cooling transition, cool along a different mode.

### Drive the qubits

1. Set the qubit states as two hyperfine levels, for example the 0 and 1
   clock states of caesium or strontium, and make the readout light
   resonant with a closed transition.
2. Apply a single-qubit gate with a focused pulse of a few milliseconds,
   calibrating the amplitude by Ramsey and the phase by an echo.
3. Apply the entangling gate, a shared photon excitation for ions and a
   Rydberg excitation for neutral atoms, and verify it by randomised
   benchmarking and by the Bell state fidelity.

### Assess the error profile and scale

1. Measure T1 and T2 for the qubit and for the motional modes; expect
   seconds to tens of seconds for trapped ions against about
   100 microseconds for a transmon.
2. Compare the two-qubit gate error across platforms: ion gates sit in
   the 1e-3 range and take 20 to 200 microseconds, while neutral-atom
   Rydberg gates take 1 to 3 microseconds at a similar error rate.
3. Plan the shuttling for a neutral-atom array and the chain splitting and
   merging for the ion trap, and include the loading and imaging time in
   the cycle budget.

## Safety Notes

- This is a red-level task because of the lasers. Blue and
  near-ultraviolet light from 355 to 532 nm is a retinal hazard and the
  exposure limits are tiny. Enclose the beam path, interlock it, and wear
  eyewear rated for the wavelength, and do this work only with appropriate
  training, supervision, and equipment.
- High voltage drives the trap and the detector electronics, and a
  capacitor bank can hold enough energy to be lethal. Discharge and earth
  the supply before opening the rack, and keep one hand out of the
  enclosure.
- Ultra-high vacuum means the chamber can implode, and a hot bake-out
  burns the operator. Use a rated window and a lid clamp, and treat the
  hot chamber as a burn hazard.
- Cryogenic sections bring asphyxiation and cold burns, and the helium
  supply must be ventilated.
- Compressed gas cylinders must be chained and the regulator checked for
  leaks, because oxygen displacement in a closed room is fatal.
- Ultraviolet plasma sources must be shielded, and the interlock must
  prevent a strike while the chamber is open.
- Never look into a trap or an objective along the beam axis, and never
  defeat an interlock to speed up an alignment.

## Verification

- **Status:** draft
- **Tested by:** —
- **Date:** —

## Sources

- NIST Quantum Initiative Reference (public domain)
