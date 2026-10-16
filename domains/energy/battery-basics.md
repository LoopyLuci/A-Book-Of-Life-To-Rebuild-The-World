# Battery Basics

> **Domain:** energy | **Difficulty:** journeyman | **Safety:** red

## Overview

Batteries store electrical energy chemically. Lead-acid is the most
rebuildable chemistry; lithium-ion is denser but harder to make from scratch.

## Prerequisites

- [Metal Smelting](../materials/metal-smelting.md)
- [Chemistry](chemistry.md)

## Materials & Tools

- Lead plates (grid + active material)
- Sulfuric acid (30% H₂SO₄)
- Case (plastic or hard rubber)
- Separators (porous rubber, glass mat)
- Terminals

## Procedure

### Lead-Acid Cell (2 V per cell)

1. Cast lead grids; paste with lead oxide (positive) and sponge lead (negative).
2. Stack alternating plates with separators.
3. Weld straps to terminals.
4. Fill with 30% sulfuric acid.
5. **Formation charge:** slow charge for 24 hours to convert pastes.

### 6 Cells = 12 V Battery

- 6 cells in series → 12 V nominal.
- Capacity: Ah = plate area × number of plates.

### Charging

1. **Bulk:** constant current to 14.4 V.
2. **Absorption:** constant voltage 14.4 V until current drops to 3% of capacity.
3. **Float:** 13.6 V to maintain.

### Maintenance

- Top up with distilled water monthly.
- Equalize every 1–3 months (15.5 V for 2 hours).
- Never discharge below 50% (12.1 V).
- Keep terminals clean; grease them.

### Other Chemistries

- **NiFe (Edison):** 1.2 V/cell; nearly indestructible; low efficiency.
- **NiCd:** 1.2 V/cell; toxic cadmium.
- **LiFePO₄:** 3.2 V/cell; safe; requires BMS.

## Safety Notes

- **Red hazard:** Sulfuric acid burns. Lead is neurotoxic.
  Wear gloves, goggles, apron. Work outdoors.
- **Explosive hydrogen** during charging — ventilate.
- Never short terminals; never reverse polarity.
- Dispose of lead and acid properly.

## Verification

- **Status:** peer-reviewed
- **Date:** 2026-05-01

## Sources

- US DOE Battery Handbook (public domain)
- US Army Battery Manual (public domain)
