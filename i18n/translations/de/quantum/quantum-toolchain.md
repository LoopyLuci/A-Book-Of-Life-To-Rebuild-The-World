# Quantum Hardware Toolchain and Fabrication

> **Domain:** quantum | **Difficulty:** master | **Safety:** red

*Reference material only. Verify this information against primary sources
and qualified professionals before acting on it. This entry is not a sole
source of information.*

## Overview

A quantum processor is an engineered object that works only if the whole
toolchain works: the metals deposited on the wafer, the lithography that
defines the junctions, the packaging that seals it, and the wiring that
carries control signals down to 10 millikelvin. The key principle is that
the yield is set by the narrowest and most unforgiving step, which is
usually the sub-2-nanometre tunnel barrier and the patterning that defines
it. Fabrication is therefore a discipline of measurement and iteration:
every step is characterised, and a defect is found by inspecting rather
than by hoping.

## Prerequisites

- Cleanroom practice, gowning, and particulate control
- Photolithography chemistry: resists, developers, and hard masks
- Thin-film deposition and etching, and how they change the surface
- Cryogenic measurement: wiring, filtering, and thermal anchoring
- Josephson junction physics and the target qubit design

## Materials & Tools

- A cleanroom with class 1000 and class 100 areas, and a wet bench
- A mask aligner, a spin coater, a hot plate, and a fume hood
- An electron-beam lithography column with its resist supply
- Sputter and evaporation systems with argon and a rotation stage
- A reactive ion etcher with fluorocarbon and chlorine chemistries
- Bulk and patterned resistance standards, and a cryogenic probe station
- A wire-bond pull tester, a die bonder, and a wire bonder

## Procedure

### Plan the process

1. Fix the qubit design, the metal stack, and the target feature sizes
   before buying any mask, because a junction pattern below 100 nm
   forecloses optical lithography.
2. Draw the masks so that the alignment marks are visible at every layer,
   include a cross on the wafer edge for the die scribe, and decide which
   layers need electron-beam patterning rather than 193 nm printing.

### Deposit the films

1. Clean the wafer, then sputter the adhesion layers, typically titanium
   or chromium at 5 to 10 nm, and the superconducting layer, aluminium or
   niobium, at 20 to 100 nm.
2. Deposit the junction stack without breaking vacuum, since a 1 to 2 nm
   tunnel barrier cannot survive exposure to air; use an in-situ oxidation
   step or a controlled argon and oxygen plasma.
3. Measure the sheet resistance and the critical current of a test
   structure, and reject the wafer if the resistance is out of band,
   because that indicates a thickness or a roughness problem.

### Pattern the features

1. Spin the resist to the thickness the process needs, 1 to 5 micrometres
   for the optical steps and 0.1 to 0.5 micrometre for the electron-beam
   steps.
2. Expose with the mask aligner at 193 nm for the wide layers, develop,
   and check the critical dimension with an inspection tool.
3. Write the fine features by electron beam with a hydrogen
   silsesquioxane resist and a dose of 2000 to 5000 microcoulomb per
   square centimetre, then etch the metal and strip the resist with an
   oxygen plasma.

### Package, wire, and measure

1. Dice the wafer, die-attach the chip with epoxy or a gold eutectic below
   150 °C, and wire-bond with 25 to 50 micrometre gold wire, pull-testing
   a sample to 2 to 4 grams of force.
2. Terminate the lines with filtered and attenuated coax and anchor them
   at 50 K, at 4 K, and at the mixing chamber, because an unanchored line
   becomes a heat leak of milliwatts per kelvin.
3. Cool slowly, watch for a temperature runaway, and measure the
   transition frequency and the linewidth; a shift of more than 50 MHz means
   the process drifted and the batch must be characterised.

## Safety Notes

- This is a red-level task because of the chemicals, the vacuum, the
  cryogenics, and the high voltage. Work in this area needs appropriate
  training, supervision, and equipment, and never alone.
- Hydrofluoric acid is the deadliest reagent in a cleanroom: it dissolves
  bone and can cause fatal systemic poisoning. Use it only with calcium
  gluconate gel at hand and a trained responder present, and never on
  skin.
- Strong oxidising acids and the resist strippers are toxic and
  carcinogenic; work in a fume hood with the sash down, and know the
  positions of the emergency shower and eyewash.
- Electron-beam lithography generates X-rays at the column. Keep the
  chamber closed, verify the shielding, and confirm that the X-ray and
  shutter interlocks work before opening it.
- Arsine and phosphine are used for doping and are lethal at low
  concentrations; use the gas cabinet, the scrubber, and the detector.
- Cryogenic helium displaces oxygen. Ventilate the room, use an oxygen
  monitor, and treat vent or relief work as confined-space work.
- High voltage at the ion pump, the electron-beam column, and the detector
  supplies is lethal, and a capacitor bank can discharge into a tool.
- The chamber and the hot platen are hazards in their own right: an
  imploding window and a burn are both realistic outcomes.
- Never break the vacuum on a chamber that holds a hazardous gas residue
  without following the full pump-down procedure.

## Verification

- **Status:** draft
- **Tested by:** —
- **Date:** —

## Sources

- NIST Quantum Initiative Reference (public domain)
