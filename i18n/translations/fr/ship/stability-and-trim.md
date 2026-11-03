# Stability, Trim and Righting Moments

> **Domain:** ship | **Difficulty:** journeyman | **Safety:** yellow

*Reference material only. Verify this information against primary sources
and qualified professionals before acting on it. This entry is not a sole
source of information.*

## Overview

A hull that floats is not the same as a hull that survives a gust, a wave, or
a moving cargo. Stability is the vessel's ability to return to the upright,
and the key principle is that everything hangs from one number: the righting
arm GZ, the horizontal distance between the vertical through the centre of
gravity and the vertical through the centre of buoyancy at a given heel
angle. If GZ is positive the vessel comes back; if it is negative she
capsizes. Trim and list are the same geometry seen in two directions, so one
schedule of weights and moments answers all three questions.

## Prerequisites

- Lines Plan and Hydrostatics for the hydrostatic data
- A weight and moment schedule, kept current
- Moments, centroids, and the lever rule
- The IMO International Code on Stability for the criteria used here

## Materials & Tools

- Hydrostatic tables, or a spreadsheet holding the ship's hydrostatic data
- Weight and moment schedule, in duplicate and on paper
- Ballast weights, marked with their mass
- Inclinometer, or a simple pendulum hung from a fixed point
- Draft marks, a lead line, and a hydrometer for the water density
- Plotting paper, a scale rule, and dividers
- Free-surface correction data for the slack tanks

## Procedure

### Set the loading condition

1. List every weight aboard with its mass and its position: the hull and
   structure, the machinery, the fuel, the stores, the crew, the
   passengers, and the cargo.
2. Compute the displacement as the sum of the masses; 1 m3 of seawater at
   1025 kg/m3 displaces 1025 kg, and fresh water at 1000 kg/m3 displaces
   1000 kg.
3. Find the centre of gravity as the mass-weighted mean of the positions,
   giving the vertical KG and the longitudinal LCG, and compare the LCG
   with the limits in the stability booklet; for a typical cargo ship it
   must stay between 0.45L and 0.55L aft of the forward perpendicular.

### Find the metacentric height

1. Read the displacement and the mean draft from the hydrostatic table at
   the computed displacement, and take the vertical centre of buoyancy KB
   and the metacentric radius BM from the same table; BM equals the
   transverse second moment of the waterplane area divided by the
   displaced volume.
2. Compute the metacentric height as GM = KB + BM - KG.
3. Compare the result with the minimum in the International Code, which is
   0.15 m for the transverse condition of ships of 24 m and more in length,
   and keep a margin above that minimum for a real sea.

### Correct for free surface

1. Identify every tank that is neither full nor empty, including the
   bilges, the sumps, and any tank that can be lined up with the sea chest.
2. Compute the free-surface moment for each tank; for a rectangular tank
   it is the length times the breadth cubed divided by 12, so a 2 m by 3 m
   tank gives 4.50 m4.
3. Sum the free-surface moments, multiply by the liquid density, divide
   by the displacement, and subtract the correction from GM; one slack
   tank can remove more of the righting arm than the whole vessel's own
   metacentric height.

### Build the righting arm curve

1. Compute GZ at heel angles of 0, 10, 20, 30, 40, 50, 60, 70, and 80
   degrees, using the free-surface-corrected condition each time.
2. Plot GZ against the angle and read off the maximum righting arm, the
   angle at which it occurs, and the angle of vanishing stability.
3. Check the criteria for a cargo ship of 24 m or more: GZ of at least
   0.20 m at 30 degrees; an area under the curve of at least 0.055 m rad
   to 30 degrees, at least 0.090 m rad to 40 degrees, and at least
   0.030 m rad between 30 and 40 degrees; GZ of at least 0.30 m at
   40 degrees; and an angle of vanishing stability of at least 50 degrees.
4. Repeat for the worst condition in the loading manual, usually full
   cargo with the fuel tanks at their working level and not empty.

### Correct a list in service

1. Measure the heel with an inclinometer and find the angle at which the
   vessel is steady; a steady list is the balance of a heeling moment and
   the restoring moment.
2. Find the cause: a shifted or unsecured cargo, water in a bilge, a slack
   tank, a fouled or damaged propeller, or a line caught under the hull.
3. Compute the transverse shift of the centre of gravity needed to bring
   her upright as D x GM x tan(heel) divided by the mass moved, where D is
   the displacement.
4. Move ballast or shift cargo by that distance, toward the side that
   reduces the heel, re-check the curve for the new condition, and record
   the change in the weight and moment schedule before the vessel sails
   again.

## Safety Notes

- A partly filled tank is as unstable as free liquid: the free-surface
  effect can cancel the whole righting arm and turn a safe vessel into a
  capsize, so drain and secure every slack tank.
- An open hatch, a missing cover, or a loose locker is the same hazard in
  miniature; keep the hull closed down in a seaway.
- Check the stability before every weight change: loading, discharge,
  bunkering, and taking on fresh water all move the centre of gravity.
- Lashing and lifting change the stability as well as the load, and a
  weight carried outboard or hanging over the side is a heeling arm.
- A vessel can be stable upright and still be tender, so keep the righting
  arm in reserve and never push the heel past the point where GZ falls
  toward zero.
- Check the flooded condition and not only the intact one; the free
  surface of floodwater inside the hull is usually what sinks a damaged
  vessel.
- Use ballast that cannot move; water in a tank that shifts during a roll
  is not ballast.

## Verification

- **Status:** draft
- **Tested by:** —
- **Date:** —

## Sources

- US Navy Stability Manual (public domain)
