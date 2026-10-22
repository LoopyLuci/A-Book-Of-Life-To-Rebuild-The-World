# Hardware and Software Testing

> **Domain:** computers | **Difficulty:** apprentice | **Safety:** green

*Reference material only. Verify this information against primary sources
and qualified professionals before acting on it. This entry is not a sole
source of information.*

## Overview

Testing is how a claim about a system becomes evidence that somebody else
can check. The key principle is that a test is worth exactly what its
independent oracle is worth: an assertion that repeats the code under test
proves nothing. Good suites fail when the code is wrong, keep failing
until it is fixed, and are cheap enough to run on every change.

## Prerequisites

- The requirements the system must meet, written down
- A defect log and a way to reproduce each fault
- Basic programming and the ability to read a test report

## Materials & Tools

- A test runner for the language in use, and a version control system
- An environment that can be rebuilt from nothing, such as a container
  image or a provisioning script
- Interface and load generators for the hardware case
- A logic analyser, a multimeter, and a thermal camera for power work
- A coverage tool, and test data held in version control

## Procedure

### Write the test

1. Write the acceptance criterion as a single checkable statement before
   you write any code.
2. Choose the level: unit for a calculation, integration for a boundary,
   system for a whole workflow, and acceptance for the user's goal.
3. Make the test deterministic by fixing time, randomness, and ordering,
   and by injecting those instead of mocking them.
4. Give every test one clear failure message that names the expected value
   and the observed value, then confirm the test can fail by changing the
   code and watching it turn red.

### Build the suite

1. Put many fast unit tests at the base, fewer integration tests above
   them, and a small number of slow end-to-end tests on top.
2. Give each test its own fixtures so the order never matters, then
   randomise the order to prove that it does not.
3. Keep the hardware-in-the-loop tests behind a tag so a bench run does
   not slow the daily loop.
4. Store the test data and the expected results in version control next
   to the code that reads them.

### Measure and act

1. Measure line, branch, and requirement coverage, and treat a coverage
   number as a pointer to untested code rather than as a target.
2. Track the number of defects each test finds and the time each test
   takes, and fix the slow ones before they slow everyone down.
3. Run the suite on every change and treat a red build as the only signal
   that matters.
4. Keep a defect log with the reproduction steps, the version, and the
   date, and never close a defect without a test that would have caught
   it.

## Safety Notes

- Tests are not a licence to run hardware beyond its ratings; the test
  bench has the same current, voltage, and temperature limits as the
  product.
- A test that energises an actuator must have a defined safe state and a
  physical way to stop it.
- Fault-injection tests on mains or battery circuits can start fires, so
  use a current-limited source and a supervised test area.
- Keep test data free of real credentials, personal data, and live keys;
  use synthetic records.
- A test skipped today is a defect with a delayed report, so track skips
  the same way as failures.
- Do not let the mock in a test become a second, untested implementation
  of the thing you are checking.

## Verification

- **Status:** draft
- **Tested by:** —
- **Date:** —

## Sources

- ISTQB Testing Guidance (public domain)
