# Wet and Dry Etching

> **Domain:** silicon | **Difficulty:** master | **Safety:** red

*Reference material only. Verify this information against primary sources
and qualified professionals before acting on it. This entry is not a sole
source of information.*

## Overview

Etching removes material selectively so that the resist pattern is
transferred into the film underneath. Two numbers decide whether the feature
survives: selectivity, the etch rate of the layer divided by that of the
mask, and anisotropy, the ratio of vertical to lateral removal. Wet etching
is cheap and isotropic, while dry plasma etching is directional and precise,
so the choice follows the geometry rather than convenience.

## Prerequisites

- Photolithography and Mask Making (resist patterns and mask making)
- Thin-Film Deposition for hard masks and anti-reflective coatings
- Wafer cleaning and reliable adhesion of the mask to the surface
- A read of the tool's own etch-rate and selectivity tables

## Materials & Tools

- Wet bench: heated tanks, temperature control, and a spin rinse dryer
- Etchants: hydrofluoric acid, nitric acid, acetic acid, potassium
  hydroxide, tetramethylammonium hydroxide, and buffered oxide etch
- RIE or ICP etcher with an RF generator at 13.56 MHz, matchbox, and pump
- Process gases: CF4, CHF3, SF6, Cl2, and O2, with a scrubbed exhaust
- Ellipsometer, profilometer, and optical microscope for measurement
- PTFE and polyethylene containers, wafer tweezers, and a face shield

## Procedure

### Plan the selectivity

1. Set the target depth and the critical dimension for the layer.
2. Look up the etch rate of the film and of the mask in your own tool and
   chemistry; published rates do not transfer between machines.
3. Require a selectivity of at least 10:1 for a 100 nm film under a 1 um
   resist, and add a hard mask when the resist will not survive the etch.
4. Plan for loading: expect the etch rate to fall as the open area grows,
   so cut a trial wafer carrying both a small and a large pattern.

### Wet etch

1. Clean the wafer, dry it, and apply the resist or the hard mask.
2. Etch silicon in hydrofluoric, nitric, and acetic acid at 60-80 °C for
   20-60 s, or etch in potassium hydroxide at 80 °C for anisotropic removal
   with a selectivity over 100:1 against silicon dioxide.
3. Rinse in deionized water and dry with nitrogen.
4. Compensate for the undercut by oversizing the mask by the etch depth on
   each side, and preserve the (111) plane by masking the corners with a tab
   at least 1.41 times the intended size.

### Dry etch

1. Load the wafer into the etcher, pump down, and condition the chamber
   with an oxygen and fluorocarbon clean.
2. Set the gas flow, the pressure (about 10-50 mTorr for RIE and 1-10
    mTorr for ICP), the source power (300-600 W for silicon), and the bias
    power for the target film.
3. Etch to the target depth and stop on an endpoint signal: an optical
    interference endpoint, or the drop in the silicon emission line.
4. Measure the depth and the sidewall profile on a witness wafer, check
    for notching at the base of a wide feature, and record the rate and the
    selectivity for the next run.

## Safety Notes

- **Red hazard:** Hydrofluoric acid is lethal by skin contact and by
  inhalation, and it attacks bone. Handle it only with appropriate
  training, supervision, and equipment, with calcium gluconate gel at the
  bench and a buddy system in place.
- **Red hazard:** Never store or carry hydrofluoric acid in glass; it
  attacks the glass and leaks through.
- The hydrofluoric, nitric, and acetic mixture releases nitrogen dioxide;
  work in a fume hood and never inhale the vapour.
- Plasma etching gases are toxic and asphyxiating: the chlorine chemistry
  makes hydrogen chloride and the fluorine chemistry makes hydrogen fluoride.
- The radio-frequency source and the plasma are lethal to touch; keep the
  interlocks and the exhaust scrubber running whenever gas flows.
- Etchant baths must be labelled with the composition and the date, and a
  bath that has seen silicon must never be returned to a glass clean.

## Verification

- **Status:** draft
- **Tested by:** —
- **Date:** —

## Sources

- NIST Semiconductor Reference (public domain)
