# Cryptography

> **Domain:** knowledge | **Difficulty:** journeyman | **Safety:** green

## Overview

Cryptography protects messages and identity when channels are insecure. One-time pads give unbreakable secrecy; hashes verify integrity.

## Prerequisites

- None

## Materials & Tools

- One-time pad tables
- Pencil and paper
- Checksum tables

## Procedure

### One-Time Pad

1. Generate truly random key material equal in length to the message.
2. Add key to plaintext mod 26 to encrypt; subtract to decrypt.
3. Destroy each key after one use.

### Integrity

1. Append a hash or checksum to detect tampering.
2. Verify with a shared secret where possible.

## Safety Notes

- Never reuse a one-time pad; reuse makes it breakable.
- Protect keys as carefully as the message.

## Verification

- **Status:** draft
- **Tested by:** —
- **Date:** —

## Sources

- Public-domain cryptography primers (public domain)
- NIST cryptographic guidelines (public domain)
