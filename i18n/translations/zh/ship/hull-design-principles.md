# Hull Design Principles

> **Domain:** ship | **Difficulty:** apprentice | **Safety:** green

*Reference material only. Verify this information against primary sources
and qualified professionals before acting on it. This entry is not a sole
source of information.*

## Overview

A hull is a compromise between the volume it must carry, the drag it makes
in the water, and the way it behaves in a rough sea. The key principle is
that the design starts from weight, not from length: the displacement is
whatever the vessel weighs, and the shape of the underwater body then
decides what that weight costs to move. Fullness and beam buy stability and
cargo space and pay for them in drag, so every choice is a trade-off that
has to be counted.

## Prerequisites

- Archimedes and the meaning of displacement
- Basic trigonometry for form coefficients and offsets
- Reading a scale drawing and using dividers and a spline
- The vocabulary of the sea: draft, freeboard, beam, and trim

## Materials & Tools

- Scale drawing paper, a drawing board, dividers, and a spline
- Planimeter, or a grid method for measuring areas on the drawing
- Hydrostatic data for seawater at 1025 kg/m3 and for fresh water at
  1000 kg/m3
- Reference tables for the block, prismatic, and waterplane coefficients
- Resistance data and an estimator for propeller revolutions
- Weight and moment schedule, and a draft-marking template

## Procedure

### Set the requirements

1. List the payload, the crew, the fuel, and the reserve; the total of
   these is the deadweight.
2. Add the lightship weight for the structure, the machinery, and the
   outfit, then divide the total by the water density to get the volume the
   hull must displace below the waterline.
3. Choose the length overall and the displacement from the cargo, and keep
   the length to beam ratio between 4:1 and 6:1 for general-purpose
   craft.

### Choose the form

1. Compute the block coefficient as the displaced volume divided by L x B x
   T, where T is the draft, and target 0.4 to 0.6 for a displacement hull.
2. Aim for a prismatic coefficient of 0.55 to 0.75 and a waterplane
   coefficient of 0.6 to 0.8, and remember that a fuller form, up to about
   0.8, carries more but makes more drag.
3. Weigh the trade: more beam and more fullness raise the initial
   righting moment and the cargo volume, and cost resistance and motion
   in a seaway.

### Lay out the lines

1. Draw the buttocks, the transverse sections, at about four stations per
   hull length, and draw the waterlines at the design draft, the loaded
   draft, and two above them.
2. Set the baseline, the keel, the stem and stern posts, the deck edge,
   and the sheer, using the 10-90-10 rule for the ends, with 10% of the
   length forward and aft of the perpendiculars and 90% between them.
3. Fair the sections with a spline and check that the curvature of each
   line is continuous and that the sections run fair against each other.

### Estimate the power

1. Estimate the friction resistance as 0.5 x rho x V^2 x S x C_f, with
    C_f of 0.075 divided by the square of (log10(L) - 2) for a smooth
    hull at a Reynolds number above 1e7.
2. Add the residual resistance, allowing 15% to 40% of the total for a
    displacement hull at moderate speed.
3. Estimate the shaft power as resistance times speed divided by the
    overall efficiency, 0.35 to 0.50 for a small diesel with a propeller,
    and convert it to propeller revolutions per minute.

## Safety Notes

- This is a desk exercise, but the numbers it produces decide flotation:
  check the stability and the freeboard with the cargo aboard, not with
  the lightship condition.
- Never work alone on a hull that is afloat; use a ladder and a harness,
  and keep a lifejacket within reach.
- Cold water and drowning are the real hazards aboard, and a capsize in a
  confined space ends quickly.
- Keep the freeboard high enough that the deck edge stays dry in a
  following sea.
- Re-check the stability after every weight change, including a change of
  crew or of stores.
- Do not approve a displacement or a draft without a margin; the density
  of seawater changes with temperature and salinity.

## Verification

- **Status:** draft
- **Tested by:** —
- **Date:** —

## Sources

- US Navy Hull Design Principles (public domain)
