# Photonic Quantum Computing

> **Domain:** quantum | **Difficulty:** master | **Safety:** red

*Reference material only. Verify this information against primary sources
and qualified professionals before acting on it. This entry is not a sole
source of information.*

## Overview

Photonic quantum computing sends single photons through a network of
beamsplitters and phase shifters and measures them at the output, so the
machine is an optical bench that happens to compute by interference. The
key principle is that photons do not interact, so all the nonlinearity has
to be arranged outside the light path, and the limiting factor is loss: a
lost photon is not a wrong answer, it is a missing sample. That makes
photon loss, rather than gate count, the number that decides whether a
photonic computer can work at all.

## Prerequisites

- Interference, coherence, and a photon as a superposition of paths or
  polarisations
- Single-photon states and how they are heralded
- Linear algebra over the complex numbers for the probability amplitudes
- Counting statistics, and the permanent of a matrix for sampling problems

## Materials & Tools

- A single-photon source: heralded down-conversion or a quantum dot, with
  its pump
- A stabilised optical table with vibration isolation and a cover
- Beamsplitters, waveplates, and phase shifters, or a photonic chip with
  interferometers
- Spectral and polarisation filters, and a spectrum analyser
- Single-photon detectors, avalanche diodes or superconducting nanowires,
  with a time-to-digital converter
- Fiber-coupled power meters, a laser safety enclosure, and interlocks

## Procedure

### Set up the source

1. Align the pump laser into the nonlinear crystal to produce correlated
   photon pairs, at a wavelength matched to the detectors, such as 1550 nm
   for telecom detectors.
2. Herald on one arm and detect on the other, and verify the heralded
   single-photon character by measuring the ratio of coincidences to
   singles; the heralded g2 must be well below 0.5 for a good source.
3. Measure the indistinguishability of the photons with a Hong-Ou-Mandel
   interference dip, and keep it above 90% if the scheme relies on
   two-photon interference.

### Build the optical network

1. Set the beamsplitters and phase shifters to encode the unitary of the
   circuit, and keep the two paths of every interferometer matched to
   within a fraction of a wavelength.
2. Characterise each beamsplitter by measuring its splitting ratio and
   its phase, because a 52/48 split accumulates a bias that spoils the
   interference.
3. Route the light onto a chip or into free space, stabilise the phase
   against drift with a feedback loop, and keep the network passive, since
   photons do not interact.

### Detect and post-select

1. Set the detector thresholds and gate the time tagger to reject dark
   counts, then measure the detection efficiency: 20 to 30% for an
   avalanche diode and up to 80% for a superconducting nanowire.
2. Record the click pattern with the time tags, and keep the count rate
   below the rate at which the detector piles up.
3. Post-select on the outcome: the KLM scheme shows that a universal
   machine is possible with single photons, linear optics, photon counting,
   and adaptive feed-forward, at the cost of ancilla photons and a
   decision after every step.

### Test a sampling application

1. Implement a boson sampling instance: prepare m single photons or
   squeezed states in n modes, send them through a passive interferometer,
   and record the output counts.
2. Compare the measured interference with the permanent of the submatrix
   selected by the observed outcomes, and show the samples are not
   classically reproducible by comparing the histogram with a uniform draw
   over the same outcome space.
3. Report the measured loss and its effect, because the tolerance is
   tight: with a total transmission of 99% the computation survives, and
   the fall-off above that is steep.

## Safety Notes

- This is a red-level task because of the lasers. Pump lasers at 405 nm and
  355 nm are class 4 and cause permanent eye damage, and even 1550 nm
  light is dangerous because the blink reflex does not protect the eye.
  Enclose the beam path, interlock it, and wear eyewear rated for the
  wavelength, and do this work only with appropriate training,
  supervision, and equipment.
- Never view a fibre end or a beam with an alignment card in the beam, and
  use a beam dump instead of a card, which can burn and reflect.
- Superconducting nanowire detectors run at cryogenic temperature, so
  asphyxiation and cold burn are hazards alongside the electrical ones.
- Detector bias supplies reach tens to hundreds of volts, and the stored
  energy in the avalanche back-up circuit can be dangerous.
- Optical tables are heavy and the levelling feet are unstable; do not
  lean on the table and secure the equipment before moving it.
- Never assume a path is dark because the shutter is closed; verify with a
  power meter and keep the shutter interlocked to the interlock.
- The nonlinear crystals are fragile and their faces are coated, so never
  touch the polished face and handle them as shatter hazards.

## Verification

- **Status:** draft
- **Tested by:** —
- **Date:** —

## Sources

- NIST Quantum Initiative Reference (public domain)
