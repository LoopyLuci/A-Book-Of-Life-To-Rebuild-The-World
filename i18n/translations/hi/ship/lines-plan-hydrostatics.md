# Lines Plan and Hydrostatics

> **Domain:** ship | **Difficulty:** journeyman | **Safety:** green

*Reference material only. Verify this information against primary sources
and qualified professionals before acting on it. This entry is not a sole
source of information.*

## Overview

The lines plan is the drawing that defines the hull's shape, and
hydrostatics turns that drawing into the numbers that decide how the
vessel floats, how she trims, and how she stands up in a wave. The key
principle is that displacement equals weight, so every change to the cargo
has to be re-entered in the weight schedule and re-checked against the
same integrals. A lines plan that is not tabulated is only a drawing; a
tabulated one is the instrument that the loading computer and the dry dock
both rely on.

## Prerequisites

- Hull Design Principles for form coefficients and the resistance trade-off
- Simpson's rule and the trapezoidal rule for area integration
- Basic geometry: moments, centroids, and the lever rule
- Weights, displacement, and the vocabulary of trim and list

## Materials & Tools

- Scale drawing sheets, a drawing board, dividers, and a spline
- Station offset tables, giving the offsets at the buttock and waterline
  intersections
- Planimeter or a grid-digitising method for area measurement
- Hydrostatic calculation software, or a spreadsheet for the displacement
  and stability tables
- Seawater density of 1025 kg/m3, or 1000 kg/m3 for fresh water, with a
  free-surface correction for slack tanks
- Scales, a lead line, an electronic sounder, and a draft-marking template

## Procedure

### Build the lines plan

1. Set the buttocks, the transverse sections, at a spacing of L/10 to
   L/20, and draw the baseline, the keel, the stem and stern posts, and the
   sheer.
2. Draw the waterlines at each draft of interest with an even spacing, so
   that every buttock and waterline intersection is a known point.
3. Transfer the half-breadths into the station tables, check that the
   sections are fair, and produce the profile, the half-breadth plan, and
   the body plan.

### Compute the hydrostatics

1. Integrate the sectional areas below each waterline with Simpson's rule
   at the buttock spacing to get the displaced volume.
2. Compute the displacement as the volume times the water density; 1 m3 of
   seawater at 1025 kg/m3 is about 1.025 tonnes.
3. Compute the block coefficient as the volume divided by L x B x T, the
   prismatic and waterplane coefficients in the same way, and the wetted
   surface from the waterline lengths.

### Locate the centres and build the tables

1. Find the longitudinal centre of flotation from the first moment of the
   waterplane area, and the longitudinal centre of buoyancy from the first
   moment of the underwater volume.
2. Locate the centre of gravity from the weight and moment schedule, and
   keep the longitudinal centre of gravity between 0.45 and 0.55 of the
   length aft of the forward perpendicular.
3. Build the displacement table for a range of drafts, giving the
   displacement, the trim, the centre of buoyancy, and the waterplane area
   at each one.

### Use it in the water

1. Apply the free-surface correction for any partly filled tank, and
    re-check the righting arm before accepting the condition.
2. Mark the draft scales on the stem and the stern in metres, with
    numerals at least 100 mm high, and read the draft at the middle of the
    mark.
3. Compare the measured draft with the calculated draft, corrected for the
    actual water density; the difference is the trim error and a check on
    the weight schedule.

## Safety Notes

- A partly filled tank is as unstable as free liquid, and the free-surface
  effect can cancel most of the righting arm.
- Keep the weight and moment schedule current, because every unrecorded
  item moves the centre of gravity.
- Check the stability with the cargo aboard and the fuel at its working
  level, not with the lightship condition.
- Verify the draft against the marks before loading; a misread draft causes
  overloading or a grounding.
- Use a lead line or an electronic sounder rather than judging the depth
  by eye.
- Read the draft on the marked vertical surface, since paint build-up
  changes the reading over the years.

## Verification

- **Status:** draft
- **Tested by:** —
- **Date:** —

## Sources

- US Navy Hydrostatics Text (public domain)
