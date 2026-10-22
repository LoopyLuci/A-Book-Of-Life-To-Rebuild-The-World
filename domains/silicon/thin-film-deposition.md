# Thin-Film Deposition (PVD and CVD)

> **Domain:** silicon | **Difficulty:** master | **Safety:** red

*Reference material only. Verify this information against primary sources
and qualified professionals before acting on it. This entry is not a sole
source of information.*

## Overview

Deposition lays down the conductor, insulator, and semiconductor films that
make up a device. Four properties matter and each is set by a different
control: thickness and uniformity come from the rate and the geometry,
conformality from the process pressure, and film stress from the energy of
the arriving species. The key principle is that a film is only as good as
its measurement, so a deposition run without a thickness monitor and a
resistance check is an unverified run.

## Prerequisites

- Vacuum fundamentals: pumps, gauges, leak rates, and outgassing
- Thermal oxidation knowledge for the insulating films
- Cleanroom Protocols and Contamination Control
- Wafer cleaning before every deposition

## Materials & Tools

- Evaporation system: electron-beam or resistance hearth, quartz crystal
  monitor, shutter, and substrate rotation
- Sputter system: DC or RF magnetron targets, argon, and a pre-sputter
  shield
- Thermal CVD: quartz tube furnace, gas panel with mass flow controllers,
  and a nitrogen purge
- Plasma CVD: RF or ICP source at 13.56 MHz and a heated chuck
- Substrate heater, wafer chuck, and a stage thermocouple
- Profilometer, ellipsometer, four-point sheet resistance meter, and a
  wafer-curvature fixture for stress

## Procedure

### Choose the method

1. Pick evaporation for simple metals and for lift-off, where a
   line-of-sight deposit is an advantage.
2. Pick sputtering for refractory metals such as tungsten, molybdenum,
   tantalum, and titanium, and for better coverage of the sidewalls.
3. Pick chemical vapour deposition when conformality and film density
   matter, as for oxide and nitride dielectrics.
4. Set the targets: thickness uniformity within 3% across a 200 mm wafer,
   and film stress below about 200 MPa so that the wafer does not bow.

### Run the deposition

1. Load the wafer, start the rotation, and pump to 10^-6 mbar for
   evaporation or 10^-7 mbar for sputtering.
2. Pre-evaporate or pre-sputter the source with the shutter closed for 5 to
   10 minutes to drive off the outgassing from the crucible or the target.
3. Set the crystal monitor and deposit at the target rate: 0.2 to 1.0 nm/s
   for sputtering, and 700-800 °C for thermal CVD.
4. Stop the flow, purge with nitrogen, and cool before venting, so that the
   film does not flake or crack as the pressure changes.

### Characterise the film

1. Measure the thickness on a step with the profilometer, or by
   ellipsometry for a transparent film.
2. Measure the sheet resistance of a metal film with a four-point probe
    and compare it with the resistivity implied by the material.
3. Measure the film stress from the wafer bow and correct it at the
    design stage.
4. Record the run per wafer: pressure, flow, power, temperature,
    thickness, and resistance.

## Safety Notes

- **Red hazard:** Silane and dichlorosilane are pyrophoric and toxic; they
  ignite on contact with air. Handle them only in a facility with a proper
  gas cabinet, a scrubber, and trained operators.
- **Red hazard:** Hydrogen and ammonia are asphyxiants. Purge the chamber
  before venting and never vent a hot tube into air.
- The electron-beam evaporation source runs at 6-10 kV and generates
  X-rays; keep the source shield closed and the interlock in service.
- The radio-frequency source at 13.56 MHz creates strong electric and
  magnetic fields; keep ferromagnetic tools away and never defeat the
  interlocks.
- Gas cylinders must be chained, capped, and connected through the
  regulator only; use a cross-connected manifold and leak-test the lines.
- Sources and CVD tubes at 700-800 °C cause severe burns; allow the
  cool-down time and never seal a hot chamber.

## Verification

- **Status:** draft
- **Tested by:** —
- **Date:** —

## Sources

- NIST Semiconductor Reference (public domain)
