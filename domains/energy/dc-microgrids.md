# DC Microgrids

> **Domain:** energy | **Difficulty:** journeyman | **Safety:** red

*Reference material only. Verify this information against primary sources
and qualified professionals before acting on it. This entry is not a sole
source of information.*

## Overview

A small DC microgrid links solar panels, batteries, and loads on a common bus,
usually 12, 24, or 48 V. It avoids the losses of converting to mains voltage for
every lamp and phone charger, but it demands correct wire sizing, fusing, and
grounding. A clean design keeps critical loads alive and makes faults easy to
isolate.

## Prerequisites

- Solar PV installation basics
- Electrical safety and multimeter skills
- Battery charging knowledge

## Materials & Tools

- PV panels and mounting hardware
- Charge controller rated for the array
- Battery bank with overcurrent protection
- DC busbars, fuses, and circuit breakers
- Correctly sized copper cable and lugs
- Grounding rod and bonding conductors
- Distribution box and labels
- Multimeter, clamp meter, and insulated tools

## Procedure

### 1. Define loads and voltage

1. List every load with watts, hours per day, and whether it is critical.
2. Add the daily watt-hours and size the battery for at least two cloudy days.
3. Choose a bus voltage that keeps currents manageable: higher voltage for
   longer runs and larger loads.
4. Keep critical loads on a separate circuit from optional loads.

### 2. Design protection

1. Fuse each source and each branch circuit at or below the cable ampacity.
2. Use DC-rated breakers and fuses; AC parts can arc and fail to interrupt DC.
3. Bond equipment frames and battery negatives according to the chosen
   grounding scheme.
4. Label every conductor, fuse, and switch with its source and destination.

### 3. Install and commission

1. Mount panels with clearance for cooling and access.
2. Connect the charge controller to the battery first, then the array, following
   the manufacturer's sequence.
3. Torque lugs to spec and check for voltage drop under load.
4. Test each circuit with a multimeter before connecting loads; confirm polarity
   and insulation.

### 4. Operate and maintain

1. Record daily generation, battery voltage, and load use.
2. Inspect terminals for heat, corrosion, and loose connections monthly.
3. Equalize or balance batteries only as the manufacturer allows.
4. Disconnect the array before working on the battery or controller.

## Safety Notes

- **Red hazard:** Batteries can deliver enormous short-circuit current and
  release hydrogen. Wear eye protection and remove metal jewellery.
- DC arcs do not self-extinguish like AC arcs; use DC-rated protection.
- Do not mix battery chemistries, ages, or capacities in one bank.
- Grid-tied or generator-connected systems require a qualified electrician and
  approved transfer equipment.

## Verification

- **Status:** draft

## Sources

- NEC Article 712 DC Microgrids
- IEC 62548 Photovoltaic Array Design
- Sandia National Laboratories DC Microgrid Guidance
