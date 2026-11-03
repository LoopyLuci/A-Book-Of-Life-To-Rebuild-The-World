# Dopant Diffusion and Ion Implantation

> **Domain:** silicon | **Difficulty:** master | **Safety:** red

*Reference material only. Verify this information against primary sources
and qualified professionals before acting on it. This entry is not a sole
source of information.*

## Overview

Doping creates the n-type and p-type regions that make every junction in
a chip. Diffusion moves dopants in with heat, while implantation fires
them in with a beam of ions. The key principle: it is the depth of the
junction, not the dose alone, that sets how fast the finished device
works.

## Prerequisites

- Thermal Oxidation, since oxides and masks control the diffusion
- Access to a diffusion furnace and, for implantation, an implanter
- Circuit analysis to the level of reading a diode current-voltage curve

## Materials & Tools

- A diffusion furnace with a quartz tube and zone control
- Solid dopant sources: boron nitride wafers, or doped epitaxial wafers
- Borosilicate glass preforms for solid source diffusion
- An ion implanter, 20 to 200 keV, or access to one
- A rapid thermal processor for implant activation
- A four point probe for sheet resistance and a resistivity monitor
- An angle lane instrument or SIMS for junction depth
- Oxidised wafers, photoresist, a mask, and an aligner
- Wafer tweezers, a cassette, and a temperature monitor

## Procedure

### Plan the Doping

1. Set the target sheet resistance and the target junction depth from the
   design.
2. Choose between a predeposition diffusion, a drive-in diffusion, and an
   implant, then calculate the dose for the chosen depth.
3. Prepare the masking oxide or nitride, and check the mask thickness,
   because a thin mask leaks dopant sideways.

### Diffuse the Dopant

1. Set the solid source at its control temperature and stabilise it for
   30 minutes, then push the wafer into the source zone for the
   predeposition time.
2. For a drive-in, switch to the inert ambient and raise the temperature
   to 1,000 to 1,100 degrees C for 30 to 60 minutes, then cool the wafer in
   the same ambient.
3. Measure the sheet resistance on a monitor wafer from the same run, and
   rehearse the whole recipe on a test wafer before touching production
   wafers.

### Implant the Dopant

1. Select the ion species, energy, dose, and a beam tilt of about 7
   degrees to avoid channeling.
2. Scan the beam across the wafer to keep the current low and the wafer
   below 100 degrees C, and set the dose for the chosen energy and
   species.
3. Confirm the beam alignment with the interlock checks, then activate
   the dopant with a rapid thermal anneal at 900 to 1,050 degrees C for
   10 to 30 seconds.

### Verify the Junction

1. Measure the sheet resistance with the four point probe.
2. Measure the junction depth by angle lane analysis or by SIMS, and
   check that the profile matches the expected box-like or Gaussian
   shape.
3. Measure the reverse leakage current of a test diode, and record the
   implant energy, dose, tilt, and anneal for every lot.

## Safety Notes

- Implanters and annealers run at lethal voltages and at high voltage
  beam energies; work on them only with appropriate training,
  supervision, and equipment.
- Some implants leave the wafers radioactive, so follow the local
  monitoring and handling rules.
- Phosphorus and boron sources are toxic and must be handled in a fume
  hood.
- Furnace tubes run above 1,000 degrees C, so use tongs and a face shield.
- Volatile dopant precursors and toxic gases need a scrubbed exhaust.
- A beam alignment error can dose someone outside the chamber, so treat
  every interlock as real and never bypass it.

## Verification

- **Status:** draft
- **Tested by:** —
- **Date:** —

## Sources

- NIST Semiconductor Reference (public domain)
