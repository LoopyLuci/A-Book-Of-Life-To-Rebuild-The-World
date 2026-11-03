# Photolithography and Mask Making

> **Domain:** silicon | **Difficulty:** master | **Safety:** red

*Reference material only. Verify this information against primary sources
and qualified professionals before acting on it. This entry is not a sole
source of information.*

## Overview

Photolithography transfers a drawn pattern onto a wafer, and each mask layer
is one exposure of one resist. The smallest printable feature is set by the
diffraction limit, 0.61 * wavelength / numerical aperture, so a shorter
wavelength and a wider lens give finer geometry. The key principle is that
the reticle is only a drawing: focus, dose, and resist chemistry set the
actual critical dimension, so every layer is measured before the next one is
laid down.

## Prerequisites

- Wafer cleaning and oxidation (see Silicon Compounds, Silicates and
  Silicones)
- Photoresist handling and fume-hood discipline
- Optics basics: focal length, numerical aperture, and resolution
- Access to a cleanroom area with a light-controlled exposure bay

## Materials & Tools

- Exposure tool: stepper or mask aligner, i-line 365 nm or ArF 193 nm
- Reticle: chrome on quartz, 1x or 4x reduction, with a pellicle
- Photoresist, HMDS adhesion promoter, and anti-reflective coating
- Developer: 0.26 N tetramethylammonium hydroxide, plus an isopropanol rinse
- Spin coater, hot plate, developer track, and fume hood
- Mask inspection microscope, CD-SEM, and overlay measurement tool
- Calibration log sheet with one row per layer

## Procedure

### Plan the layer

1. Define each layer's critical dimension, its tolerance, and its depth.
2. Draw the layout to the design rules for minimum width, minimum space,
   and extension.
3. Set the resist thickness to at least three times the step height so the
   printed profile survives development.
4. Pick the wavelength for the feature size: 365 nm i-line at a 0.55
   aperture gives 0.40 um, and 193 nm ArF at the same aperture gives
   0.21 um.

### Prepare the reticle and the wafer

1. Write the pattern to a resist-coated quartz blank with an electron-beam
   writer, or cut a 1x mask by photoreduction.
2. Inspect the mask for opaque and clear defects; a defect smaller than the
   mask defect limit is printed onto every die in the field.
3. Dehydrate the wafer at 150-200 °C, apply HMDS, then spin-coat the resist
   to the target thickness, about 1.4 um at 4000 rpm for a 1.2 um resist.
4. Soft-bake at 90-110 °C for 60-90 s; the bake sets the remaining solvent
   and therefore the resist sensitivity.

### Align, expose, and measure

1. Align the reticle to the previous layer using the alignment marks, and
   match the mark to within a fraction of the critical dimension.
2. Set focus and dose from a focus-exposure matrix and keep the dose
    within about 10% of the process nominal.
3. Develop in 0.26 N tetramethylammonium hydroxide for about 60 s, rinse
    with isopropanol, and dry.
4. Measure the critical dimension on a step with a CD-SEM, hold it to
    within 5% of nominal by correcting the dose, and check the layer
    overlay against a third of the smallest CD.

## Safety Notes

- UV lamps emit hazardous UV-C and UV-B; never look at the lamp and keep
  the interlocks on the exposure housing closed.
- Developer and remover are corrosive and the solvents are flammable; work
  in a fume hood with nitrile gloves and a face shield.
- Resist is a flammable solid in bulk; collect the waste in a labelled
  container and never mix solvent waste with oxidiser waste.
- The electron-beam writer and the mask exposure tool run at high voltage
  and generate X-rays; only trained operators work inside the enclosure.
- Hot plates and bake ovens at 150 °C cause burns; use dry tools and let
  the wafer cool before handling it barehanded.
- A large-area exposure of thick resist can ignite the wafer; keep the
  nitrogen purge fitted and never leave an exposure running unattended.

## Verification

- **Status:** draft
- **Tested by:** —
- **Date:** —

## Sources

- NIST Semiconductor Reference (public domain)
