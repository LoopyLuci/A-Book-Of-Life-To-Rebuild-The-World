# PCB Design and Fabrication

> **Domain:** computers | **Difficulty:** apprentice | **Safety:** yellow

*Reference material only. Verify this information against primary sources
and qualified professionals before acting on it. This entry is not a sole
source of information.*

## Overview

A printed circuit board is a mechanical drawing, a wiring diagram, and a
stack of dielectric layers, and it works only when all three agree. The
key principle is that the layout is constrained by manufacturing, so
every rule broken in the editor comes back as a board that is
expensive, slow, or rejected. Define the stack-up, respect the design
rules of the fabricator, keep the ground plane continuous, and check
the outputs against the drawing before the panels are cut.

## Prerequisites

- Schematic capture and the ability to read a netlist
- The pin data of every component in the library
- An understanding of the layers of a board, and of the surface and
  through-hole technologies
- The design rules of the fabricator, expressed in the units of the
  design tool
- The ability to read a Gerber file and an Excellon drill file

## Materials & Tools

- A schematic and layout editor with a metric and an imperial grid
- A component library with the footprints from the manufacturer
  datasheets
- The IPC-2221 design rules and the IPC-2152 current-carrying tables
- FR-4 laminate with a glass transition temperature of at least 130 °C
  and a UL94 V-0 rating
- Copper thickness of 35 µm for 1 oz or 70 µm for 2 oz
- A Gerber exporter, an Excellon drill exporter, and a CAM viewer
- A stencilled assembly drawing and a bill of materials
- A continuity and insulation test set, and a bench supply with a
  current limit for the first power-up

## Procedure

### Capture the schematic

1. Draw the schematic with correct pin numbers and names, check every
   symbol against the datasheet rather than against another drawing,
   then run the electrical rules check and resolve every unconnected
   pin, every missing power flag, and every net that has only one
   connection.
2. Produce the netlist and freeze it against a revision number before
   any layout work starts.

### Set the stack-up and the rules

1. Choose the layer count and the construction: for a four-layer board,
   a signal layer, a solid ground plane, a power plane, and a second
   signal layer, with a total thickness of 1.6 mm.
2. Load the design rules for the fabricator and the board house, a
   minimum track of 0.25 mm and a minimum gap of 0.2 mm for outer
   copper on 1.6 mm FR-4 with 1 oz copper, set the net classes, and use
   the current capacity table to widen every track that carries more
   than about 2 A.

### Lay out the board

1. Place the connectors and the mounting holes first, on the board
   outline, and keep the fixings clear of the copper.
2. Place the decoupling capacitors at the supply pins, within 5 mm of
   the pin they serve, then route the signals so that the ground plane
   stays unbroken and the return path under the signal has no split.
3. Add the silkscreen, the polarity marks, the pin numbers, and the
   board reference, then run the design rule check and confirm that
   the copper stays 0.5 mm inside the routed edge.

### Prepare the fabrication outputs

1. Export the Gerber files for the copper, the solder mask, the
   silkscreen, and the outline, and the Excellon drill file, and name
   the files with the revision.
2. Read the Gerber and the drill files back into the CAM viewer and
   layer them against each other, checking that the drill hits the
   pad, that the mask opens the pad, and that the outline matches the
   drawing.
3. Write the fabrication drawing with the stack-up, the copper weight,
   the surface finish, the solder mask colour, the tolerances, the
   electrical test requirement, and the impedance requirement if the
   board has controlled-impedance nets, then send the outputs to the
   fabricator and ask for the manufacturability report before the
   panels are cut.

### Assemble and test

1. Bake the boards if the assembly process needs it, apply the solder
   paste through a stencil or hand-solder the through-hole parts with
   the technique in the soldering entry, and reflow the board at the
   profile the paste requires: a lead-free paste with a peak near
   245 °C and a soak of 60 to 90 seconds above 150 °C.
2. Inspect the joints, power the board up for the first time from a
   current-limited supply with the limit set to about 200 mA while you
   watch the current, and check the rails against the design; if the
   current limit trips, find the short before applying power again.

## Safety Notes

- Etching and the fabrication chemistry are the hazard: the etchant,
  the stripper, and the developer are corrosive and some are toxic.
  Work with eye protection, gloves, and a chemical assessment, and
  dispose of the waste through a proper route.
- Soldering on the board releases flux fumes and, on a leaded process,
  lead; use the fume extraction, wash your hands, and keep food out of
  the workshop.
- A solder mask and a silkscreen layer are not insulation for mains
  voltage. A board that connects to the mains must meet the creepage
  and clearance requirements of IPC-2221, and the assembly must use a
  rated fuse, a switch, and an insulated enclosure.
- Test boards from a current-limited supply with the limit set low for
  the first power-up, and never probe a board that is energised from
  the mains with a grounded instrument.
- Reflow ovens and hot plates reach 250 °C; they burn, they fume, and
  they ignite solvents, so keep the area clear and ventilated.
- The board is sharp: the cut edges of the laminate and the exposed
  copper of a broken board cut fingers, so deburr the edges and wash
  off the flux residue.
- Do not rely on the fabricator's assembly for the safety-critical
  parts; check the polarity of the mains-side components and the
  ratings of the fuses yourself.

## Verification

- **Status:** draft
- **Tested by:** —
- **Date:** —

## Sources

- IPC Design Standards (public domain)
