# Hull Structural Design Rules

> **Domain:** ship | **Difficulty:** master | **Safety:** yellow

*Reference material only. Verify this information against primary sources
and qualified professionals before acting on it. This entry is not a sole
source of information.*

## Overview

A classification rule is a book of tables that tells a small yard what
scantlings to use for a hull of a given length, draft, and form, so that
the yard does not have to carry out the full structural analysis itself.
The key principle is that strength is checked the same way every time:
the combined still-water and wave bending moment is divided by an
allowable stress to give a required section modulus, and the section that
was chosen must provide it. The numbers given here are the usual order of
magnitude; the rulebook in hand is the controlling document and its tables
override anything written here.

## Prerequisites

- Lines Plan and Hydrostatics for the offsets and the hydrostatic data
- The loading condition and the resulting displacement and draft
- Steel grades, yield strengths, and mill certificates
- Bending, section modulus, and the elastic neutral axis
- The hull lines and the intended scantling arrangement

## Materials & Tools

- The rulebook for the intended class, tonnage, and construction type
- Steel plate with mill certificates showing the grade and the yield
- Templates, a straightedge, a tape, and a set of chalk lines
- Section modulus and shear force tables for the chosen sections
- A rule yard's gauge for plate thickness and a hole gauge
- The loading manual and the calculations booklet for the surveyor
- Alignment templates for the frame and the girder spacing

## Procedure

### Fix the design condition

1. Establish the length overall, the moulded breadth B, the depth D, and
   the loaded draft from the lines plan and the loading condition.
2. Compute the displacement and confirm that the design falls inside the
   rule's range; the class rules cover steel hulls from about 20 m upward,
   with separate sections for small craft and for aluminium.
3. List the rule's load cases: the still-water condition, the hogging and
   the sagging condition, and the checks on local loads and on the
   stiffeners.

### Work out the bending moments

1. Integrate the weight distribution to get the still-water bending
   moment; for a uniform distribution over the whole length it is
   D x g x L divided by 8, and a real ship with its machinery amidships
   reaches 0.06 to 0.08 of D x g x L.
2. Add the wave bending moment, which the rules express as a coefficient
   times D x g x L, from about 0.03 for a long ship to about 0.08 for a
   short one, and add the two to get the total moment.
3. Divide the total moment by the allowable stress to get the required
   section modulus; the class rules usually limit the extreme fibre to
   0.55 to 0.6 of the specified yield, so 129 to 141 MPa for grade A steel
   with a yield of 235 MPa.
4. Compute the modulus of the proposed section as Z = I divided by c, with
   I the second moment of the area about the neutral axis and c the
   distance to the outer fibre, and compare the two.

### Check the scantlings

1. Take the frame spacing from the rule's spacing table, commonly 600 to
   800 mm on small craft, and never exceed the stated maximum.
2. Select the plate thickness and the frame section modulus from the rule
   tables for the length and the draft, and never drop below the rule's
   minimum scantling even when the calculation would allow it.
3. Check the local stiffening: the panel aspect ratio of the plating
   between the frames should not exceed about 2:1, and the free ends of
   the stiffeners need an end bracket or a doubler plate.
4. Check the subdivision: the number of transverse watertight bulkheads,
   the limits on their positions, and the height of the double bottom.

### Prove the class

1. Assemble the survey set: the plans, the calculation booklet, the
   material certificates, the welding and the non-destructive testing
   records, and the plates for the surveyor to measure.
2. Measure the structure against the plans: the plate thicknesses, the
   frame spacing, the bilge radius, the alignment of the bulkheads, and
   the boundary between the plating and the profile.
3. Correct every deficiency and re-inspect; an undersized scantling is
   fixed by doubling the plating or by adding a doubler, not by arguing.
4. Keep the freeboard and the load line in step with the design, and
   survey the vessel for the load line when the rules require it.

## Safety Notes

- Structural failure is sudden and total: a hull with an undersized frame
  gives no warning before it opens up.
- The rule is a floor and not a ceiling; where the design departs from
  the rule, say so in the calculations and have it checked.
- Work aloft on staging and inside a hull in a confined space; test the
  atmosphere and work to a permit.
- Hot work on a partly plated hull is a fire waiting for air: keep a fire
  watch on the vessel and in the void spaces.
- Plate edges and stacked plate are a cutting and a falling hazard; keep
  the edges guarded and the stacks chocked.
- Check the stability with the fuel, the stores, and the permanent
  ballast in place, because a rule calculation that leaves them out is
  not the vessel that sails.
- Never accept a certificate without reading the heat number, and never
  weld over an unidentified plate.

## Verification

- **Status:** draft
- **Tested by:** —
- **Date:** —

## Sources

- Classification Society Rules (public domain)
