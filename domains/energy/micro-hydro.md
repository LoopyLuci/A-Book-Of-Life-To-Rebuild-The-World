# Micro-Hydro

> **Domain:** energy | **Difficulty:** journeyman | **Safety:** yellow

## Overview

Micro-hydro (up to 100 kW) provides continuous power where a stream drops
in elevation. It is more reliable than wind or solar.

## Prerequisites

- [Mills](../materials/mills.md)
- [Electrical Wiring](electrical-wiring.md)

## Materials & Tools

- Intake weir
- Penstock (pipe)
- Turbine (Pelton, Turgo, or crossflow)
- Generator
- Tailrace
- Wiring

## Procedure

### Site Assessment

1. Measure **head** (vertical drop) with a level and staff.
2. Measure **flow** with a weir or float method.
3. Power (W) ≈ head (m) × flow (L/s) × 5 (at 50% efficiency).

### Intake & Penstock

1. Build a small weir to divert part of the stream.
2. Settling basin to remove sediment.
3. Penstock: PVC, HDPE, or steel, sized for low friction.
4. Anchor every 3 m on slopes.

### Turbine Selection

- **Pelton:** high head (>20 m), low flow.
- **Turgo:** medium head (5–30 m), medium flow.
- **Crossflow:** low head (2–10 m), high flow.

### Generator

1. Direct-coupled PMG for battery charging.
2. Induction motor as generator for grid-tie.
3. Voltage regulation via electronic load controller.

### Electrical

1. Rectify AC → DC for battery charging.
2. Or use an induction generator and sync to grid.

## Safety Notes

- **Yellow hazard:** Water under pressure cuts flesh. Never open a live penstock.
- Drowning risk in weirs and tailraces.
- Electrical hazards from wet environments; use GFCI.
- Fish passage may be required by law in some jurisdictions.

## Verification

- **Status:** peer-reviewed
- **Date:** 2026-04-25

## Sources

- US DOE Micro-Hydro Guide (public domain)
- Practical Action Micro-Hydro (public domain)
