# Transmon Qubit Fabrication

> **Domain:** quantum | **Difficulty:** master | **Safety:** red

*Reference material only. Verify this information against primary sources
and qualified professionals before acting on it. This entry is not a sole
source of information.*

## Overview

Fabricating a transmon means writing a sub-micron Josephson junction and
its capacitor onto a chip whose surface must be near atomically clean. The
key principle is that the device is defined by the junction resistance,
which scales with the area of the tunnel barrier, so a few nanometres of
misplacement or a few particles of dust change the qubit's frequency.
Every stage, from cleaning to oxidation, exists to control that one
resistance.

## Prerequisites

- Cleanroom discipline and a working knowledge of the room class
- Photolithography and electron-beam lithography
- Thin-film deposition: evaporation, sputtering, and lift-off
- Microwave measurement and the readout of a qubit frequency

## Materials & Tools

- An electron-beam lithography system, or a deep-ultraviolity stepper
- A sputter system and an electron-beam evaporator
- A reactive oxygen or argon plasma cleaner, and a hot plate
- Resist, developer, and solvents: resist remover and acetone
- A dilution refrigerator, a vector network analyser, and a probe station

## Procedure

### Prepare the substrate

1. Choose the substrate: sapphire for a low-loss microwave environment, or
   silicon with a buried oxide for a smaller footprint.
2. Clean with solvents in the order that removes the least material
   first, then use the plasma cleaner, which takes off the last few
   nanometres of organic residue.
3. Deposit the ground plane and the lower capacitor plate, typically 100
   nm to 200 nm of aluminium or niobium, and measure the film's sheet
   resistance and critical temperature before going further.

### Write the junction

1. Lay down the resist stack with the undercut layer that becomes the
   junction barrier.
2. Write the junction and the leads with the electron-beam lithography at
   an accelerating voltage of 80 kV to 100 kV.
3. Develop, rinse, and inspect the resist in the scanning electron
   microscope before evaporating, because a defect here cannot be undone.
4. Evaporate the aluminium in two steps with an oxidation hold in between
   to form the tunnel barrier, then lift off in solvent and measure the
   junction resistance at the wafer edge with a four-probe station.

### Form the capacitor and the readout

1. Deposit the dielectric spacer and the upper capacitor plate, define
   the gap that sets the coupling capacitance, and pattern the readout
   resonator and the Purcell filter if one is used.
2. Measure the room-temperature resistance of every junction on the chip,
   reject the outliers, and then measure the resonance frequencies at low
   temperature to compare them with the design values.

### Package and measure

1. Bond the chip into the sample holder and connect the resonator lines to
   the board that carries the bias and the amplifiers.
2. Cool the assembly and check that no resonance has moved by more than a
   few megahertz from the design value.
3. Run a spectroscopy sweep to find the qubit transition, then measure the
   relaxation and the dephasing times and record them against the
   fabrication run number.

## Safety Notes

- Electron-beam and deep-ultraviolity exposure is a radiation hazard, so
  work only with appropriate training, supervision, and equipment, and
  prove the interlocks before every run.
- Developing and lifting off in solvents such as acetone harms skin and
  eyes and fills a room with flammable vapour; work in a fume hood with
  the sash low.
- Plasma, hot plates, and heated evaporators burn skin and can start
  fires; treat every hot surface as hot at all times.
- Hydrofluoric acid is used to etch native oxide from silicon and can kill
  by systemic poisoning after a very small exposure; it needs dedicated
  training, a calcium gluconate antidote on hand, and a glass-free
  protocol.
- The cryogenic stage is a confined space with real asphyxiation and
  over-pressure risks; never seal a cold volume without a relief path.
- Metal and particulate waste from the tools is a respiratory hazard, so
  do the cleaning in a hood and wash before leaving.

## Verification

- **Status:** draft
- **Tested by:** —
- **Date:** —

## Sources

- NIST Quantum Initiative Reference (public domain)
