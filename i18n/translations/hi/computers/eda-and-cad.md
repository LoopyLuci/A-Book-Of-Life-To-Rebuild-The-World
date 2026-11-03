# Electronic Design Automation and CAD

> **Domain:** computers | **Difficulty:** journeyman | **Safety:** green

*Reference material only. Verify this information against primary sources
and qualified professionals before acting on it. This entry is not a sole
source of information.*

## Overview

Electronic design automation turns an idea into files a factory, a machine
shop, or a solder bench can act on without re-drawing anything. The key
principle is that the schematic is the single source of truth and everything
else, the netlist, the board layout, the drill files, and the bill of
materials, is derived from it. Keeping that whole chain inside one
versioned toolchain is what makes a design reproducible months later.

## Prerequisites

- Reading a circuit diagram and understanding schematic symbols
- The difference between a netlist, a footprint, and a drill file
- Version control basics, including commits and branching
- The difference between a component datasheet and a catalogue listing

## Materials & Tools

- KiCad 9 or later, with its symbol, footprint, and 3D model libraries
- A text editor and a spreadsheet for the bill of materials
- A PCB fabricator, or a local etching and drilling setup
- The fabricator's design rules: minimum trace width, spacing, and vias
- A multimeter, and an oscilloscope for designs with fast edges

## Procedure

### Set up the project

1. Create one project folder per board and commit it before the first board
   file exists.
2. Build a symbol library that carries the fields the fabricator needs:
   manufacturer part number, value, footprint reference, and tolerance.
3. Write a design-rules note in the project folder listing the fabricator's
   minimum trace width, spacing, and via limits, and fix the sheet size,
   the grid, and the units so every sheet is identical.

### Capture the schematic

1. Draw one sheet per functional block and use hierarchical sheets so a
   block can be reused without being redrawn.
2. Place every power rail and every ground symbol explicitly, then run the
   electrical rules checker and treat every warning as a defect until it
   has been explained.
3. Assign a footprint to every symbol, check each one against the real
   datasheet, then annotate the schematic and confirm that the reference
   designators are unique.

### Lay out the board

1. Place the connectors and the mounting holes first and fix them; the
   mechanical outline drives everything after that.
2. Pour the ground plane on an outer layer and keep it unbroken wherever
   the design allows.
3. Route the clock, the differential pairs, and the analogue inputs first,
   then the rest, and keep the analogue section away from the switching
   nodes.
4. Place the decoupling capacitors at the supply pins, run the design
   rules check with the fabricator's ruleset, and inspect the 3D view for
   parts that clash with the enclosure.

### Release the outputs

1. Generate the drill, pick-and-place, and fabrication outputs and the
   bill of materials from the same saved project, then compare the
   assembly drawing against the board file line by line.
2. Record the release in the changelog with the commit hash, the date, and
   the fabricator's part numbers, and file the released archives read-only
   beside the source.

## Safety Notes

- The CAD file is not the only artifact that matters: check every
  footprint against the datasheet, because a reversed or mis-pinned part
  fails on the board and not in the software.
- Etching and drilling a board uses acids and creates toxic waste; do that
  work only with appropriate training, supervision, and equipment.
- A soldering iron and a hot air station burn skin and start fires; use
  fume extraction and keep the tools in their stands.
- Mains-powered equipment beside a wet bench is a shock hazard; keep the
  power off and the bench dry.
- Never let a tool silently rewrite a released design; work on a branch
  and review the diff before merging.
- A board revision that is not recorded in the changelog will be built
  twice, and the second one will differ.

## Verification

- **Status:** draft
- **Tested by:** —
- **Date:** —

## Sources

- KiCad Documentation (GPL)
