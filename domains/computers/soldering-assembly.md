# Soldering and Through-Hole Assembly

> **Domain:** computers | **Difficulty:** novice | **Safety:** yellow

*Reference material only. Verify this information against primary sources
and qualified professionals before acting on it. This entry is not a sole
source of information.*

## Overview

Soldering is a controlled chemical join: the solder melts, wets the
copper, and forms a bond that is stronger than either metal alone. The
key principle is that a good joint is made by heat the work can
absorb, so the iron touches the pad and the lead and not the solder,
and the solder is carried in by the heat rather than dropped onto it.
A cold, dull, balled joint is a joint that will fail later and out of
sight, and it costs more than making it properly the first time.

## Prerequisites

- None

## Materials & Tools

- A temperature-controlled soldering iron of 25 to 60 W, with a nichrome
  or ceramic tip, and a stand with a sponge
- Solder wire of 0.5 to 0.8 mm diameter: 63/37 tin-lead for the classic
  183 °C eutectic, or SAC305 lead-free at 217 °C
- Flux: a rosin pen for general work or a no-clean gel, and separate
  flux for desoldering
- A desoldering pump, desoldering braid, and brass wool for the tip
- Side cutters, needle-nose pliers, a printed circuit board holder, and
  a loupe
- 90% isopropyl alcohol and a lint-free swab for cleaning
- A wrist strap and a grounded mat, and a fume extraction fan
- Heat-shrink tubing, and a multimeter for the continuity checks

## Procedure

### Prepare the iron and the work

1. Set the temperature for the alloy in use: about 320 to 350 °C for a
   leaded joint, and 370 to 400 °C for lead-free work on the larger
   pads, and let the tip warm fully.
2. Wipe the tip with a damp sponge and tin it with a little solder so
   that the heat goes into the work instead of into the tip.
3. Clean the pad and the lead with isopropyl alcohol, and fit the
   component so the lead sits fully in the hole with no strain on the
   joint.

### Make the joint

1. Heat the pad and the lead together for two or three seconds and
   keep the iron still; the solder should flow onto the pad and up the
   lead, not form a ball on the iron tip.
2. Feed the solder into the heated joint, not onto the iron, and stop
   feeding as soon as the fillet forms and the solder runs down the
   lead.
3. Take the iron away along the direction of the lead so that the
   solder does not stick to the tip, hold the component still for two
   or three seconds while the joint cools, and clean and re-tin the
   tip before moving to the next joint.

### Inspect the joint

1. Check the fillet under magnification: the surface must be smooth and
   concave, with a contact angle of 90 degrees or less, and there must
   be no ball, no crack, and no void in the fillet.
2. Check the wetting of the lead: for a through-hole joint on a 0.6 mm
   lead, at least 75% of the lead length should be wetted and the hole
   filled, which is the acceptance level for a dedicated-service
   product.
3. Flex the board gently and check for a cracked joint, then measure
   the continuity from the pad to the component lead on every joint
   that matters.

### Rework and desolder

1. For a through-hole part, apply flux to the joint, heat the pad and
   the lead together, and pull the lead with the iron against the pad
   until it releases; add fresh solder to the joint to keep it wet.
2. For a pad that will not release, wick the joint with desoldering
   braid and a hot iron, or use a desoldering pump, then clean the pad
   with isopropyl alcohol.
3. Pad the board flat, tinned copper side up, on a heat-resistant
   surface, keep the iron moving so that the laminate does not scorch,
   and re-tin any pad that has been drawn down before refitting the
   part.

## Safety Notes

- The iron tip sits at 250 to 400 °C and molten solder sticks to skin
  and burns through it. Use a stand, rest the iron on a heat-resistant
  surface, and never leave it in the holder unattended.
- Flux smoke and solder vapour are irritants and can cause asthma with
  repeated exposure. Work with local fume extraction or in the open
  air, and never solder in a sealed room.
- Lead and lead-containing solder are cumulative poisons. Wash your
  hands after soldering, do not eat or drink in the work area, and
  keep the solder out of reach of children.
- Isopropyl alcohol and the tip cleaners are flammable; keep them away
  from the hot iron and away from any open flame.
- The desoldering pump and the hot braid spit molten solder; point
  them away from your face and wear eye protection.
- Work on mains-connected boards only with the supply unplugged and
  discharged, and never touch a live board with a grounded tool such
  as an oscilloscope earth clip.
- Solder spatter and flux splatter burn; wear eye protection and keep
  the bench clear.

## Verification

- **Status:** draft
- **Tested by:** —
- **Date:** —

## Sources

- NIST Soldering Guidance (public domain)
