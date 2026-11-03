# Integrated Circuit Design Flow

> **Domain:** silicon | **Difficulty:** master | **Safety:** yellow

*Reference material only. Verify this information against primary sources
and qualified professionals before acting on it. This entry is not a sole
source of information.*

## Overview

An integrated circuit travels from a written specification to a GDSII layout
that a foundry can mask. The key principle is that every stage is a
verification gate: nothing advances until the previous stage is proven,
because the cost of a defect rises steeply with each step, from a recompile
to a respin of the whole chip. The design is therefore mostly an argument
about evidence, and the artefact that survives is the archive of what was
checked, when, and with which tool version.

## Prerequisites

- Digital design and Boolean logic
- Timing analysis: setup, hold, clock skew, and the critical path
- Verilog or VHDL, and the simulator and synthesis tools named below
- A technology design kit: standard cells, LEF and GDEF, GDSII layers,
  and Liberty timing
- Version control with branching and peer review

## Materials & Tools

- Specification and verification plan documents
- RTL sources, a testbench, and a simulator with a waveform viewer
- Synthesis tool with a standard-cell library and a Liberty timing file
- Place-and-route tool with the design kit, plus static timing analysis
- Signoff tools: lint, CDC, DRC, LVS, and IR drop and electromigration
  checks
- Git repository, an issue tracker, and a cost model covering wafer cost,
  die area, dies per wafer, and the one-time mask and design cost

## Procedure

### Specify and write RTL

1. Write the specification: the interface, the clock, the throughput, the
   latency budget, the power ceiling, the die area ceiling, and the cost
   ceiling.
2. Write the verification plan before the RTL, covering the assertions, the
   corner cases, and the coverage targets.
3. Freeze the specification and record it, so that a later change shows up
   as a change rather than as drift.
4. Write the RTL, simulate the testbench to a passing regression, and run
   lint for width mismatches, incomplete assignments, and multiple drivers.

### Synthesise and place

1. Set the clock constraints, with the period and the uncertainty, and run
   synthesis against the target area and timing.
2. Read the critical path report and the power estimate: dynamic power is
   roughly C x V^2 x f plus leakage.
3. Plan the floorplan before the tool does it, placing the memories, the
   analog blocks, and the I/O ring, and leaving room for the power grid.
4. Run placement, then clock tree insertion, then routing, and check the
   skew and the routing congestion after each stage.

### Sign off and tape out

1. Run static timing at the slow and fast corners, for setup and for hold.
2. Run DRC for spacing, density, and antenna rules, LVS against the
    schematic, and the IR drop and electromigration checks.
3. Close every violation, then run a multi-corner Monte Carlo to expose
    the rare timing failures.
4. Export the GDSII, generate the mask set, archive it with a checksum
    and the tool versions used, and split the order between two foundries
    to hedge the schedule.

## Safety Notes

- The hazards here are project hazards: an unreviewed tape-out wastes the
  whole mask set and the money behind it.
- Lock down the source and any third-party intellectual property, and keep
  the design files in an access-controlled store; export control rules
  apply to them.
- Use reproducible builds: record the tool versions, the scripts, and the
  licence state so that the archive can be rebuilt exactly.
- Verify third-party IP before use, because a subtle bug in a hard macro
  is expensive and hard to find.
- Have a second person check the signoff checklist against the
  specification before the order is placed.
- Archive the GDSII and the mask set; losing them means paying for the
  mask again.

## Verification

- **Status:** draft
- **Tested by:** —
- **Date:** —

## Sources

- NIST Semiconductor Reference (public domain)
