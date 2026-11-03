# AC Circuit Analysis and Impedance

> **Domain:** computers | **Difficulty:** apprentice | **Safety:** green

*Reference material only. Verify this information against primary sources
and qualified professionals before acting on it. This entry is not a sole
source of information.*

## Overview

On alternating current the voltage and the current no longer rise and
fall together, so the simple ratio of voltage over current is no
longer a useful number. The key principle is to replace each element
by its impedance, a complex number with a resistance part and a
reactance part, and then solve exactly the same circuit equations as in
DC. Reactance is set by the frequency, which is why a circuit that
behaves one way at steady state can be completely different at 50 Hz.

## Prerequisites

- DC Circuit Analysis for Kirchhoff's laws and the series and parallel
  rules
- Complex numbers in rectangular and polar form
- The sine and cosine functions, phase, and phase difference
- Basic differentiation and integration, for the reactive elements
- The relationship between the RMS, the peak, and the peak-to-peak
  values

## Materials & Tools

- A function generator and an oscilloscope
- A bench supply and a digital multimeter with a capacitance range
- Resistors, capacitors, and inductors from the E12 and E24 series
- A decade box, or a set of values for the resonance and filter work
- Copper wire and a former for making a test inductor
- An isolation transformer for any work connected to the mains

## Procedure

### Convert the circuit to phasors

1. Replace each resistance by R and each capacitor and inductor by its
   reactance: X_L = 2 x pi x f x L and X_C = 1 / (2 x pi x f x C).
2. Write the impedance of each element in rectangular form: Z_R = R,
   Z_L = j X_L, and Z_C = -j X_C.
3. Add the impedances in series and combine the branches in parallel
   with the same rules used for DC, keeping the j terms separate, then
   convert the result to polar form: the magnitude is the square root
   of R^2 plus X^2 and the angle is the arctangent of X over R.

### Solve the AC network

1. Apply Kirchhoff's laws to the impedance network and solve for the
   phasor currents and voltages.
2. Convert the phasor answers back to the time domain, remembering that
   the RMS value of a sine is the peak divided by 1.414.
3. Check the result against the power: the real power is P = V x I x
   cos(phi), the reactive power is Q = V x I x sin(phi), and the
   apparent power is S = V x I in volt-amperes.

### Find the resonance

1. Set the reactances equal and solve for the resonant frequency
   f0 = 1 / (2 x pi x sqrt(L x C)).
2. Measure the half-power frequencies and compute the quality factor
   Q = f0 / (f2 - f1), and check it against the expression for
   sqrt(L / C) divided by the series resistance.
3. Note that at resonance the circuit current is at its maximum and the
   voltage across the capacitor can be Q times the supply voltage.

### Design a filter

1. Set the cutoff frequency from the specification and compute the
   resistance for a simple RC low-pass filter, R = 1 / (2 x pi x f x
   C), and build it.
2. Measure the response at 0.1, 1, and 10 times the cutoff frequency
   and check that the output has fallen by 20 dB per decade.
3. Confirm the phase shift at the cutoff, which is 45 degrees for a
   first-order filter, and add a second stage if the attenuation is not
   steep enough.

## Safety Notes

- Mains voltage kills. Treat any circuit connected to the supply as
  lethal, and work on it only with appropriate training, supervision,
  and equipment, using an isolation transformer.
- The current that stops a heart is small: about 0.5 mA is the
  threshold of perception, 10 mA is the let-go threshold, 30 mA can
  stop the breathing, and 50 mA can cause ventricular fibrillation.
- A charged capacitor keeps its energy after the supply is off,
  because the meter impedance is far too high to discharge it; use a
  discharge resistor and prove the voltage with a meter before touching
  a node.
- A resonant circuit can produce a high voltage across the capacitor,
  and a flyback or a boost converter can put hundreds of volts on a
  node that looks like a low-voltage one.
- Keep the function generator output and the bench supply outputs
  isolated from each other, and never connect a signal source across a
  supply output.
- Check the voltage and the ripple current ratings of the capacitors,
  and remember that the voltage across a capacitor in a resonant
  circuit can be much higher than the supply voltage.

## Verification

- **Status:** draft
- **Tested by:** —
- **Date:** —

## Sources

- OpenStax University Physics (CC BY)
