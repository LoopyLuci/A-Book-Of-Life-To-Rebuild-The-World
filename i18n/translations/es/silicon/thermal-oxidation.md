# Thermal Oxidation Furnaces

> **Domain:** silicon | **Difficulty:** journeyman | **Safety:** red

*Reference material only. Verify this information against primary sources
and qualified professionals before acting on it. This entry is not a sole
source of information.*

## Overview

A layer of silicon dioxide grown on silicon is the workhorse of
fabrication: it insulates, it masks etching, and it forms the gate
dielectric of every MOSFET. Growth follows the Deal-Grove curve. The key
principle: the thickness is set by time and temperature, not by how long
the surface takes to look finished.

## Prerequisites

- Cleanroom Protocols, for gowning and handling of polished wafers
- Diffusion furnace operation and gas handling
- Photolithography basics, for mask alignment
- Ellipsometry and the meaning of a thickness reading

## Materials & Tools

- A diffusion furnace with a quartz or fused silica tube, 900 to 1,200
  degrees C
- Steam and dry oxygen gas delivery with mass flow controllers
- A gold diffused aluminium or platinum coated quartz boat
- Polished silicon wafers, 100 orientation
- An ellipsometer for oxide thickness
- A heated probe station for capacitance-voltage measurement
- Buffered hydrofluoric acid for stripping, or an oxide etch
- A nitrogen purge cabinet and a wet bench for cleaning
- A continuous temperature recorder for the run log

## Procedure

### Load and Heat

1. Clean the wafers and the boat, because contamination on the boat
   transfers onto the wafer.
2. Load the wafers into the boat with the spacing needed for uniform gas
   flow across the load.
3. Ramp the furnace slowly so the boat is not shocked, soak at the target
   temperature until the tube settles, and keep the tube sealed against
   the outside air.

### Grow the Oxide

1. Flow oxygen for a dry oxidation, or steam for a wet oxidation, at the
   set rate.
2. Hold at 900 to 1,100 degrees C for the time the Deal-Grove curve gives
   for the target thickness.
3. Expect roughly ten times faster growth in steam than in dry oxygen
   above 1,000 degrees C; a dry hour at 1,000 degrees C gives about 0.22
   micrometres, while a wet hour gives about 1.0 micrometre.

### Measure and Strip

1. Measure the thickness by ellipsometry on a monitor wafer, and confirm
   it with a capacitance-voltage measurement of thickness and charge.
2. Check the uniformity across the wafer, from centre to edge.
3. Strip the oxide in a buffered hydrofluoric acid dip when the wafer must
   be reused, rinse in deionised water, dry with nitrogen, and record the
   run conditions beside the measured thickness.

### Keep the Furnace Honest

1. Log the temperature, the time, and the gas flow for every run, and
   store the log with the wafer record.
2. Keep the overtemperature interlock active at all times, because an
   overtemperature can fuse wafers to the boat.
3. Check the furnace calibration against a reference thermometer each
   quarter, and recalibrate the gas flow controllers before each process
   qualification.

## Safety Notes

- Furnace tubes run above 1,000 degrees C, so use heat resistant gloves
  and a face shield.
- Hydrogen chloride gas is toxic and corrosive; it needs a scrubbed
  exhaust and a working emergency shower.
- Hydrogen forms an explosive mixture with air, so purge the system
  thoroughly before opening it.
- Hydrofluoric acid used for stripping is exceptionally dangerous and
  requires specific training and calcium gluconate gel on site.
- Quartz tubes are fragile and shatter when shocked, so cool before
  handling.
- An overtemperature can fuse wafers to the boat, so keep the
  overtemperature interlock active at all times.

## Verification

- **Status:** draft
- **Tested by:** —
- **Date:** —

## Sources

- NIST Semiconductor Reference (public domain)
