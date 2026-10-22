# Power Supplies and Regulation

> **Domain:** computers | **Difficulty:** apprentice | **Safety:** yellow

*Reference material only. Verify this information against primary sources
and qualified professionals before acting on it. This entry is not a sole
source of information.*

## Overview

Every piece of electronics needs a source of power that holds inside its
limits while the load changes and the mains does not. Two approaches cover
almost everything: a linear regulator, which is simple and quiet but
throws away the difference between the input and the output voltage as
heat, and a switching converter, which moves power at high frequency and
wastes far less but makes noise on the output and on the mains lead. The
key principle is to size the supply from the heat and the noise the load
can tolerate, not from the rating printed on the case.

## Prerequisites

- DC Circuit Analysis
- AC Circuit Analysis and Impedance
- Reading a semiconductor datasheet
- Soldering and multimeter use

## Materials & Tools

- Step-down transformer, 230 V to 12 V, 25 VA
- Bridge rectifier rated 4 A, or four 1 A, 50 V diodes
- Electrolytic capacitors, 1000 uF at 25 V, 10 uF, and 100 nF
- Linear regulators: 7805, 7812, and one adjustable LM317
- Switching controller with inductor, Schottky diode, and ceramic input
  and output capacitors
- Oscilloscope with a 10X probe, a multimeter, and a resistive load bank
- Heat sink, thermal compound, and a clip-on or infrared thermometer
- Fuse, switch, thermal cut-out, and an earthed chassis

## Procedure

### Size the supply

1. List every load with the voltage it needs, the current it draws there,
   and the tolerance it can live with.
2. Add the currents and multiply by 1.25 to set the supply rating, then
   write down the noise limit, for example under 10 mV of ripple.
3. Compute the heat of a linear stage as (V_in - V_out) x I; 12 V to 5 V
   at 1 A dissipates 7 W and sets the size of the heat sink.

### Build a linear supply

1. Reduce the mains to 12 V AC with the transformer, sized at 1.25 times
   the DC power the load needs.
2. Rectify with the bridge and smooth with the reservoir capacitor; the
   ripple frequency is twice the mains frequency, so 100 Hz at 50 Hz mains.
3. Regulate with the 7805, leaving at least 2 V of headroom above 5 V, and
   place the 100 nF bypass within 10 mm of the regulator pins.

### Build a switching supply

1. Pick the topology: buck to step down, boost to step up, and buck-boost
   when the input may sit on either side of the output.
2. Choose the switching frequency, commonly 50 to 500 kHz, and size the
   inductor so the ripple stays inside the load's tolerance.
3. Keep the input capacitor, the switch, the diode, and the inductor in
   one small loop, because that loop area sets the radiated noise.

### Protect and verify

1. Fit a fuse at about twice the working current, a switch, and a thermal
   cut-out in series with the transformer primary.
2. Check the output with the scope using a spring ground, and confirm the
   ripple is under the limit set in the first stage.
3. Load the output from 10 to 100 percent and record the voltage change
   and the efficiency, then compare both with the datasheet limits.

## Safety Notes

- Mains voltage can kill and can start fires. Work on a mains supply only
  with appropriate training, supervision, and equipment, and keep it
  isolated from the bench while the chassis is open.
- Treat every point of a rectifier output and every heat sink as live; the
  reservoir capacitor can hold a lethal charge for minutes after switch-off.
- Provide at least 2 mm of creepage and clearance across basic insulation
  at mains potential, and 3 mm where reinforced insulation is required.
- Earth the exposed metal of the chassis and never defeat the protective
  earth to make a test pass.
- A reversed electrolytic or a shorted output capacitor can vent and
  burn; check the polarity marks and the voltage ratings before soldering.
- Keep the linear regulator's dissipation below its rating with a heat
  sink and a thermal cut-out, because it has no internal shutdown.
- Never clip an earth-referenced scope ground to a live high-voltage
  switching node; the ground lead is shorted to earth.

## Verification

- **Status:** draft
- **Tested by:** —
- **Date:** —

## Sources

- OpenStax University Physics (CC-BY)
