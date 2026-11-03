# Cryogenics and Dilution Refrigeration

> **Domain:** quantum | **Difficulty:** master | **Safety:** red

*Reference material only. Verify this information against primary sources
and qualified professionals before acting on it. This entry is not a sole
source of information.*

## Overview

A dilution refrigerator cools a sample to a few millikelvin by mixing
superfluid and normal helium, and it holds that temperature only if the
whole heat-load budget is met. The key principle is that every cable,
every wire, and every surface is a leak in the insulation, so the design
is mostly a matter of counting heat in microwatts and then removing it.
The sample is the smallest part of the system; the plumbing, the
filtering, and the shielding decide whether the measurement is possible.

## Prerequisites

- Cryogenic engineering basics and the phase diagram of helium
- Superfluidity and the dilution of helium-3 in helium-4
- Microwave engineering and the design of attenuator and filter chains
- Vacuum practice, leak checking, and safe cryogen handling

## Materials & Tools

- A dilution refrigerator with a mixing chamber and a still
- A cryogenic transfer line and a vacuum pump set with a cold trap
- Vacuum-rated coaxial cable, SMA and SMP connectors, and heat sinks
- A chain of microwave attenuators and a low-pass filter per signal line
- A superconducting magnet, a thermometer set, and a shielded room

## Procedure

### Plan the heat load

1. List every line that crosses from room temperature down to the mixing
   chamber and count them.
2. Compute the conductive leak through each cable from the material's
   thermal conductivity, with Q = k A dT over L, and note that one
   unattenuated coaxial line can carry more than a milliwatt to the 4 K
   stage.
3. Compute the radiation load through each shield with
   Q = sigma A (T_hot to the fourth minus T_cold to the fourth), where
   sigma is 5.67e-8 W per square metre per kelvin to the fourth.
4. Add the drive cooling from the amplifiers, compare the total with the
   cooling power at the mixing chamber, typically 10 to 100 microwatts at
   10 mK, and leave a margin of at least 30 percent.

### Prepare the wiring

1. Terminate every coaxial line with an attenuator at the 50 K stage, the
   4 K stage, the still, and the mixing chamber, about 10 dB per stage.
2. Add a low-pass filter at the 4 K stage for every signal line, with a
   cutoff near 5 GHz, and a much lower cutoff of 700 MHz or less on every
   DC bias line.
3. Anchor each line to the stages with copper or aluminium braid so the
   heat stops there.
4. Vacuum-test the whole line and the feedthrough, and never close the
   vacuum space on a cold line that has not been leak checked.

### Cool and verify

1. Pulse the helium and the vacuum pumps in the prescribed order and
   never interrupt a warm-up that has already produced a vacuum.
2. Watch the stage temperatures and the helium level, and record the
   settling time and the final base temperature.
3. Close the radiation shields only after the base temperature is stable,
   then transfer the sample and confirm that the temperature at the
   sample holder matches the thermometer.
4. Log the base temperature, the stage temperatures, and the microwave
   noise floor together for every cooldown.

## Safety Notes

- Liquid helium expands enormously on warming and can rupture a sealed
  volume, so every cold volume needs a relief path and relief devices
  must never be blocked or plugged.
- Liquid helium and liquid nitrogen cause cold burns and can displace the
  oxygen in a room; work in a well-ventilated area with a room monitor and
  never work alone with a cryogen.
- A cryogenic transfer line that has been opened can inject liquid helium
  into a vacuum line and cause an implosion; never vent a cold line to
  atmosphere without following the procedure for it.
- Oxygen condensing on a cold surface makes it brittle and every
  cryogenic fitting a fragment hazard; use the correct metal seals and
  never tighten a cold joint.
- A superconducting magnet stores energy and can quench without warning,
  releasing a large field and boiling the cryogen; set the ramp limits and
  never leave it energised unsupervised.
- A vacuum failure or pump oil backstreaming can contaminate a cold stage
  and destroy the experiment with no visible warning.

## Verification

- **Status:** draft
- **Tested by:** —
- **Date:** —

## Sources

- NIST Cryogenics Guidance (public domain)
