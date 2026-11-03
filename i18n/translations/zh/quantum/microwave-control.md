# Microwave Control Electronics

> **Domain:** quantum | **Difficulty:** master | **Safety:** yellow

*Reference material only. Verify this information against primary sources
and qualified professionals before acting on it. This entry is not a sole
source of information.*

## Overview

Everything a qubit is asked to do arrives as a shaped microwave pulse. The
key principle is that a pulse is defined by its envelope, its phase, and
its timing to the nanosecond, so the control electronics must hold phase
and frequency stable while the amplitude is swept through a hundredfold.
Anything that jitters in the electronics shows up directly as an error in
the qubit.

## Prerequisites

- Microwave engineering: propagation, mixing, and impedance
- Digital signal processing and IQ modulation
- Clocking, jitter, and phase-locked loops
- RF grounding, shielding, and safety practice

## Materials & Tools

- An arbitrary waveform generator with at least two channels
- IQ mixers and a low-pass filter set for each channel
- A local oscillator with a phase-locked loop and a low-noise reference
- Coaxial cable, attenuators, and DC blocks
- A power meter and a spectrum analyser for setting the levels

## Procedure

### Plan the pulse set

1. List every operation the device needs: a pi pulse, a readout pulse, a
   Ramsey echo, a virtual Z rotation, and the reset tone.
2. Compute the amplitude for each pulse from the Rabi oscillation
   frequency and the pulse length, using the rule that a pulse area of pi
   radians gives full inversion.
3. Choose a pulse length that is a whole number of drive cycles so the
   envelope leaves no residual detuning at the end, and write down the
   calibration numbers for every pulse and store them with the
   experiment.

### Build the signal path

1. Generate the baseband envelope at a sample rate of at least twice the
   highest frequency component in that envelope.
2. Mix it with a local oscillator at the qubit frequency to form the
   single-sideband signal.
3. Filter each channel to remove the unwanted sideband and the carrier
   leakage, and measure the rejection on the analyser.
4. Set the level at the qubit with a calibrated attenuator, typically
   between 10 microwatts and 1 milliwatt, and measure it at the qubit and
   not at the generator.
5. Keep the cables short, use phase-matched cable where the timing
   matters, and secure every cable so it cannot move between runs.

### Synchronise and verify

1. Derive every channel from one master reference clock and record that
   reference in the data with every run.
2. Measure the jitter of the trigger path and keep it below 1 percent of
   the shortest pulse.
3. Characterise the phase noise of the local oscillator and correlate it
   with the dephasing seen on the qubit.
4. Run a Rabi sweep and a Ramsey sequence at the start of every session
   and check the frequency and the amplitude against the log, then save
   the raw envelope samples beside the results.

## Safety Notes

- A microwave amplifier can deliver tens of milliwatts into a device that
  dies at a microwatt, so always start at the lowest output and step up
  while watching the reflected power.
- Transmitted power at 5 GHz causes burns and heats tissue internally;
  never point an antenna at a person and treat the output connector as
  live.
- A loose connector or a damaged cable will arc and can start a fire, so
  use torque-limited connectors and check every cable under load.
- A grounding error puts RF on the cable shield, which then finds a path
  through the rack and can damage the instrument.
- DC blocks and bias tees must be rated for the frequency; an ordinary DC
  block will arc across at microwave power.
- Never change a cable on a powered amplifier; some amplifiers need a
  specific termination before they will start.

## Verification

- **Status:** draft
- **Tested by:** —
- **Date:** —

## Sources

- NIST Quantum Initiative Reference (public domain)
