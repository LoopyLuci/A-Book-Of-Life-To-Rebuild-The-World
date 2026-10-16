# Electrical Wiring

> **Domain:** energy | **Difficulty:** apprentice | **Safety:** red

## Overview

Wiring distributes electricity safely. Rules: correct wire gauge for current,
proper grounding, overcurrent protection, and secure connections.

## Prerequisites

- [Metal Smelting](../materials/metal-smelting.md)

## Materials & Tools

- Copper wire (various gauges)
- Insulation (rubber, cloth, plastic)
- Breakers or fuses
- Outlets, switches
- Conduit
- Multimeter

## Procedure

### Wire Gauge

| Current (A) | Copper Gauge (AWG) |
|-------------|-------------------|
| 10 | 16 |
| 15 | 14 |
| 20 | 12 |
| 30 | 10 |
| 50 | 6 |
| 100 | 2 |

Rule: voltage drop <3% over the run.

### Basic Circuit

1. Source → fuse/breaker → switch → load → return to source.
2. Ground the source (rod into earth).
3. Neutral and ground are separate at the panel; tied only at one point.

### Making Connections

1. Strip insulation 1 cm.
2. Twist wires (for solid) or crimp (for stranded).
3. Solder for permanent; wire nut for serviceable.
4. Wrap with electrical tape or heat-shrink.

### Installing a Breaker

1. Size to wire gauge (see table).
2. Connect hot wire to breaker; neutral to bus bar.
3. Ground wire to ground bar.
4. Test with a multimeter before energizing.

### Grounding

1. Copper rod 2.5 m into moist earth.
2. Bond to panel ground bar.
3. All metal enclosures must be grounded.

### Low-Voltage DC

- 12 V systems: fuse at 1.25× max current.
- Voltage drop over distance: use larger wire.
- Keep polarity consistent (red +, black −).

## Safety Notes

- **Red hazard:** Electrocution kills. De-energize before working.
- Test with a multimeter; never trust a switch.
- Lockout/tagout for shared systems.
- GFCI for wet locations.
- Do not overload circuits — fires start in walls.

## Verification

- **Status:** peer-reviewed
- **Date:** 2026-05-04

## Sources

- US National Electrical Code principles (public domain)
- US Army Electrical Manual (public domain)
