# Propellers, Screws and Thrust

> **Domain:** ship | **Difficulty:** journeyman | **Safety:** yellow

*Reference material only. Verify this information against primary sources
and qualified professionals before acting on it. This entry is not a sole
source of information.*

## Overview

The propeller converts the engine's rotation into a force, and the whole
steering and power system depends on how that force is aimed. The key
principle is the match between the pitch of the propeller, the speed of the
vessel, and the sense of rotation of the shaft: a propeller is a wing that
works in water, and it works only at the advance it was designed for. A
screw fitted to the wrong engine will be efficient on paper and useless
in the water.

## Prerequisites

- Fluid mechanics at a basic level: pressure, velocity, lift and drag
- The screw convention: right-hand, viewed from astern, and what the
  hand does and does not do with the rotation
- Hull resistance and the power the vessel needs
- Engine speed, the reduction gear, and the shaft speed
- Steering gear, the rudder, and the thruster

## Materials & Tools

- The shaft, the stern tube, the boss, and the key or the spline
- The propeller, and the template for its pitch and its rake
- Thickness gauge, straightedge, and a feeler gauge
- A shaft alignment tool and a dial indicator
- A hydraulic puller for the propeller and a soft mallet
- Sacrificial anodes and the hull coating at the stern
- The engine and the gearbox data, and the propeller's own open-water
  diagram

## Procedure

### Fix the propeller's size

1. Choose the diameter from the power and the hull; a service propeller
   sits between 50 and 120 kW per square metre of disc area, which is the
   power divided by the diameter squared.
2. Set the pitch ratio, the pitch at the two-thirds radius point over the
   diameter: about 0.8 to 1.0 for a general cargo ship at moderate speed,
   1.2 to 1.5 for a fast vessel, and 0.6 to 0.8 for a tug or a trawler
   that works at low speed with high thrust.
3. Check the tip speed: the circumferential speed is pi x D x n, and for
   a conventional screw keep it below about 75 m/s, because above that the
   blade tips begin to cavitate badly.
4. Check the clearances: the propeller tip must clear the hull by 0.05 to
   0.10 of the propeller diameter, and the rudder must be placed so that
   it does not force the propeller to cavitate.

### Match the screw to the vessel

1. Compute the advance speed as Va = (1 - s) x n x D, where s is the slip;
   a single screw is designed for a slip of about 10 to 20 percent at the
   design speed.
2. Compute the advance ratio J = Va / (n D), typically 0.35 to 0.50 for a
   single screw and higher for a multi-screw vessel.
3. Read the thrust and torque coefficients from this propeller's own
   open-water diagram at that advance ratio and pitch ratio; never use
   another propeller's numbers.
4. Compute the thrust as K_T x rho x n squared x D to the fourth, and the
   torque as K_Q x rho x n squared x D to the fifth, with rho = 1025
   kg/m3 for seawater and n in revolutions per second.
5. Check the power: the delivered power is 2 x pi x n x Q in watts, and it
   must stay about 3 percent below the shaft power to leave room for the
   losses.

### Verify the installation

1. Check the alignment of the shaft line and the propeller axis, and
   check the pitch angle at the two-thirds radius point; a few degrees of
   pitch error costs a large part of the efficiency.
2. Check the condition: a good working propeller is smooth and firm, and
   a fouled or pitted one is worth several percent.
3. Watch for cavitation: the noise and the vibration at one particular
   speed, and the sheet of white water under the stern in a hard turn.
4. Keep the shaft and the hull clean of fouling and check the anodes,
   which protect the shaft, the boss, and the hull at the stern.

### Steer and stop

1. Size the rudder: for a single screw the rudder area is usually 2 to 3
   percent of the underwater hull surface, and it sits behind the
   propeller.
2. Place the rudder's leading edge aft of the propeller's forward tip by
   about 10 to 20 percent of the propeller diameter, so the rudder does
   not cause the propeller to cavitate.
3. Balance the rudder so that it holds at the stops and does not flutter
   at speed, and let the stock carry the whole side load.
4. Provide a way to stop and to go astern: a controllable pitch propeller
   reverses the thrust, while a fixed pitch screw needs the engine
   reversed, which leaves the rudder without grip.

## Safety Notes

- The propeller removes a limb; treat the shaft and the screw as live at
  all times, and never start an engine with a diver in the water.
- Lifting a propeller is heavy work: a 2 m bronze propeller weighs several
  hundred kilograms, and the blades gouge easily, so lift on the boss.
- Bronze dust is a hazard, and some marine bronzes contain beryllium,
  which is toxic; extract at the source and wear gloves.
- A bronze propeller on a steel shaft is a galvanic couple that will eat
  the shaft; keep the coupling clean and use the proper key or spline.
- Cavitation damage to the blades removes the efficiency that was paid
  for, and a bent blade throws the thrust off-centre and vibrates the
  shaft.
- A stern tube seal failure floods the ship, so keep the seal and the
  stuffing box in good order.
- Never start the engine with a line trailing in the water, and check the
  clearance around the screw before every start.

## Verification

- **Status:** draft
- **Tested by:** —
- **Date:** —

## Sources

- NIST Ship Propulsion Reference (public domain)
