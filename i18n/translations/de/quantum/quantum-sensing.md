# Quantum Sensing and Metrology

> **Domain:** quantum | **Difficulty:** journeyman | **Safety:** yellow

*Reference material only. Verify this information against primary sources
and qualified professionals before acting on it. This entry is not a sole
source of information.*

## Overview

Quantum sensing uses a controlled quantum system, most often an atomic
transition or a solid-state spin, as a reference whose frequency responds
to the field being measured. The key principle is that the same
superposition that makes the system a good clock also makes it a good
sensor, so the sensitivity depends on the coherence time and on how many
particles are averaged, while the resolution depends on the bandwidth of
the readout. Confusing those two is the usual way to overstate what an
instrument can do.

## Prerequisites

- Two-level systems, the Bloch sphere, and Ramsey fringe measurement
- The coherence times T1 and T2 and what limits them
- Signal to noise, shot noise, and the standard quantum limit
- Pulse shaping, digitisation, and basic control electronics

## Materials & Tools

- A sensor head: an atomic reference, a solid-state spin, or a magnetometer
- Narrow-linewidth microwave or optical sources for the transition used
- A digitiser and a field-programmable gate array for pulse shaping
- Magnetic shielding, a mu-metal enclosure or a multilayer cylinder
- A stable reference clock and an interferometer for the field readout
- A vibration isolation table and a non-magnetic sample holder

## Procedure

### Prepare the sensor

1. Choose the transition; the caesium hyperfine clock transition is
   exactly 9,192,631,770 Hz, and rubidium sits near the same frequency at
   a lower cost and a worse noise figure.
2. Bring the sensor into its working range: hold the atom or spin in a
   cell or a cavity, and set the bias field for the sensitivity wanted.
3. Reduce the magnetic noise with a mu-metal enclosure, since the
   shielding factor of a good cylinder exceeds 1000 in the sub-microtesla
   band, and stabilise the temperature and the vibration.

### Choose the sequence

1. Use a Ramsey sequence, a free precession between two pulses, when the
   field must be measured fast or is strong enough to shorten the
   coherence.
2. Use a spin-echo sequence, a pulse in the middle of the free evolution,
   when the field is weak and slowly drifting, because the echo rejects
   quasi-static noise.
3. Use a CPMG or XY sequence with many refocusing pulses when the drift
   is unknown, and fix the total interrogation time and the pulse spacing,
   because the sensitivity calculation depends on them.

### Calibrate the response

1. Measure the contrast by sweeping the interrogation time and fitting the
   fringe amplitude, and treat the fitted contrast as the calibration
   constant for the field estimate.
2. Determine the noise spectral density by taking the Fourier transform
   of repeated runs, and read the noise at the signal frequency.
3. Compute the sensitivity as the noise divided by the contrast and by
   the square root of the averaging time, and apply the projection-noise
   floor set by the polarisation of the sample.

### Turn sensitivity into resolution

1. Separate the two terms: sensitivity is the smallest field per unit
   bandwidth, and resolution is the smallest field that can be told apart
   from zero within the time available.
2. Include the bandwidth, since a field that varies faster than the
   inverse of the averaging time is averaged away, and include the sensor
   volume and the field gradient.
3. Calibrate against a traceable reference such as a Helmholtz coil, log
   the raw fringe data, verify with a second sequence, and report the
   averaging time with the result.

## Safety Notes

- Lasers and microwave sources are the real hazards here. A class 3B or
  class 4 laser can destroy the retina in a fraction of a second, so
  enclose the beam path, interlock it, and wear eye protection matched to
  the wavelength, and do this work only with appropriate training,
  supervision, and equipment.
- High-voltage supplies drive discharge lamps, magneto-optical traps, and
  detector bias, and the stored energy can be lethal. Discharge the supply
  before servicing and use interlocked enclosures.
- Cryogenic cells and magneto-optical traps bring asphyxiation and cold
  burns; the hazard is stated plainly and the work needs appropriate
  training, supervision, and equipment.
- Magnetic fields above the implant threshold interfere with pacemakers
  and implanted defibrillators, and a strong field near a magnet attracts
  ferromagnetic tools and implants.
- Never align an eye or a camera into a laser beam, and never rely on the
  beam being invisible, since near-infrared light is not visible at all.
- Keep ferromagnetic tools away from the sample, since a magnetised tool
  near the sensor ruins the calibration.

## Verification

- **Status:** draft
- **Tested by:** —
- **Date:** —

## Sources

- NIST Quantum Initiative Reference (public domain)
