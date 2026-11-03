# Qubit Physics and Superconducting Circuits

> **Domain:** quantum | **Difficulty:** master | **Safety:** red

*Reference material only. Verify this information against primary sources
and qualified professionals before acting on it. This entry is not a sole
source of information.*

## Overview

A qubit is a physical system with two distinguishable states that can be
held in a superposition. In superconducting hardware that system is a
circuit built around a Josephson junction, and the whole field's scale is
set by how long the quantum state survives there. The key principle is
that the qubit is an oscillator whose energy levels must stay clear of the
thermal noise floor, so the device must be far colder than the energy gap
it depends on.

## Prerequisites

- Quantum mechanics at the level of the harmonic oscillator and the
  two-level system
- Superconductivity: the BCS state, the energy gap, and the critical
  temperature
- Circuit analysis and the Josephson relations
- Statistical mechanics and the Boltzmann factor

## Materials & Tools

- A dilution refrigerator with a base temperature below 100 mK
- A vector network analyser and a signal generator for spectroscopy
- Low-noise microwave amplifiers and heavily filtered DC lines
- A small permanent magnet and a superconducting tuning loop
- A cryogenic attenuator chain and a vacuum-rated wire access

## Procedure

### Build the transmon

1. Choose an aluminium or niobium film and evaporate it on a sapphire or
   silicon substrate.
2. Pattern two capacitor pads and the Josephson junction with an
   electron-beam lithography write.
3. Control the junction resistance in a monitored oxidation step, because
   a change of 1 percent in the critical current moves the qubit
   frequency by roughly 25 MHz.

### Work out the energy levels

1. Write the transmon Hamiltonian in terms of the charging energy E_C and
   the Josephson energy E_J.
2. Keep the ratio E_C to E_J between 0.01 and 0.05 so the device is
   weakly anharmonic and behaves as a qubit.
3. Convert the circuit values with E_J over h at about 497 GHz per
   microampere of critical current, and E_C over h at about 277 MHz for a
   70 fF shunt capacitance.
4. Use the approximation f01 = (square root of 8 E_C E_J minus E_C) over h;
   with E_J over h of 10 GHz and E_C over h of 0.3 GHz the transition
   lands near 4.6 GHz.
5. Take the anharmonicity as E_C, about 300 MHz in that example, and check
   that it exceeds the linewidth of the qubit.

### Characterise the decoherence

1. Measure the relaxation time T1 by applying a pi pulse and watching the
   decay of the readout signal.
2. Measure the dephasing time T2 with a Ramsey sequence, and use the echo
   sequence to separate static noise from dynamic noise.
3. Account for the noise added by the amplifier, the attenuators, and the
   wiring, which often dominate the measured floor.
4. Track how T1 and T2 change with temperature, with magnetic field, and
   with the qubit frequency, then use the resulting T2 limit to size how
   many operations a useful algorithm can contain; a working surface
   transmon shows T1 of 20 to 100 microseconds.

## Safety Notes

- Cryogenic liquid helium and a sealed reliquify system can
  over-pressurise and rupture, so work only with appropriate training,
  supervision, and equipment, and with a relief device on every sealed
  volume.
- Liquid helium and liquid nitrogen cause cold burns and asphyxiation;
  vent only with good extraction and never enter a room after a heavy
  cryogen release.
- A microwave source at high power can damage the amplifier and leave the
  qubit in an unknown state, so set the level low and ramp it.
- A magnet in the room is a projectile hazard for anything ferrous,
  including tools and implants, so control access to the magnet area.
- High-voltage bias on the sample holder and the pin base can arc and
  damage the refrigerator; never probe a live cold line.
- A single mis-wired ground on a cryogenic line can warm the whole stage
  and destroy the measurement.

## Verification

- **Status:** draft
- **Tested by:** —
- **Date:** —

## Sources

- NIST Quantum Initiative Reference (public domain)
