# Yield, Defects and Wafer Metrology

> **Domain:** silicon | **Difficulty:** master | **Safety:** yellow

*Reference material only. Verify this information against primary sources
and qualified professionals before acting on it. This entry is not a sole
source of information.*

## Overview

Yield is the fraction of die on a wafer that works, and it is the number
that decides whether a product is affordable. The key principle is that
yield is limited by the largest defect population, so the work is to find
that population and remove its source rather than to inspect more often.
Metrology supplies the evidence: every measurement must map back to a die
coordinate, so that a defect can be traced to a tool, a chamber, or a
material lot.

## Prerequisites

- Cleanroom Protocols and Contamination Control
- Process control for etching and deposition, so results can be traced
- Photolithography and Mask Making for the critical dimension definitions
- Statistics: normal distribution, control charts, and sampling

## Materials & Tools

- Optical defect inspection: brightfield and darkfield, with sub-micron
  sensitivity
- Electron-beam defect inspection and review system with defect
  classification
- Inline metrology: CD-SEM, overlay tool, ellipsometer, and profilometer
- Wafer prober, probe cards, and parametric test software
- Statistical process control software and a bin-map database
- Yield model spreadsheet or script, and an archive of defect coordinates

## Procedure

### Find and classify the defects

1. Classify each defect by type: particle, film contamination, scratch,
   missing material, or a pattern defect.
2. Inspect with brightfield for large defects and with darkfield for
   particles below 0.2 um.
3. Record every defect with its die coordinate, and repeat the inspection on
   the same wafer to separate true defects from tool noise.
4. Map the defects and hunt for repeaters: a defect that always lands in
   the same place points at one chamber, one nozzle, or one material lot.

### Measure the process

1. Measure the critical dimension at 5 to 9 points per wafer on the
   critical layer and check it against the tolerance.
2. Measure the layer-to-layer overlay and the film thicknesses at the same
   sample points.
3. Measure the electrical parameters: threshold voltage, leakage current,
   and sheet resistance, using a probe card.

### Model the yield and control it

1. Compute the die yield from the defect density as yield = (1 - A x D)^2,
   where A is the defect density per square centimetre and D is the die
   area in square centimetres.
2. Fit the model, extrapolate to the target yield, and set the defect
   limit for the process from that number.
3. Build the bin map: one die location to one failure code, so that
    spatial patterns in the failures can be read directly.
4. Put the key parameters on a control chart, set the limits at three
    sigma, and react to any point that goes out of control instead of
    waiting for the average to drift.
5. Shorten the loop: measure every lot, and keep the yield learning curve
    of Y = Y0 + A / (n + B) current as the process matures.

## Safety Notes

- Inspection and electron-beam tools operate at a high accelerating
  voltage; keep the enclosures closed and obey the radiation labels.
- Wafer probing can punch through thin oxide; use a probe force of 10 to
  30 g and a probe card matched to the pad pitch.
- A hot piranha mix of sulfuric acid and hydrogen peroxide reacts violently
  with organics and reaches over 100 °C; never seal it and never mix it
  with a solvent.
- A tool opened mid-cycle can damage the stage and the wafer; follow the
  lockout procedure before touching anything.
- Ozone and perchloric clean recipes are hazardous and belong to trained
  operators only.
- Record every deviation from the process window: a silent change to a
  recipe is the most common cause of a yield excursion.

## Verification

- **Status:** draft
- **Tested by:** —
- **Date:** —

## Sources

- NIST Semiconductor Reference (public domain)
