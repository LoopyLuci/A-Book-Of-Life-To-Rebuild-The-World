# Cryptography Implementation

> **Domain:** computers | **Difficulty:** journeyman | **Safety:** yellow

*Reference material only. Verify this information against primary sources
and qualified professionals before acting on it. This entry is not a sole
source of information.*

## Overview

Cryptography is the part of computing where a small mistake stays hidden
until it matters. A cipher that works on the test data can still be
unsafe because the nonce repeated, the key came from a password, or the
comparison was not constant time. The key principle is that the algorithm
is the easy part: correct use of a standard primitive with sound key
handling is worth far more than a clever scheme of your own.

## Prerequisites

- Embedded C Programming, or equivalent fluency in C
- Modular arithmetic and the idea of a one-way function
- Basic networking, so you know where a key travels
- Record keeping disciplined enough to never improvise a primitive

## Materials & Tools

- An audited cryptographic library with documented primitives
- A cryptographically secure random source with a self test
- A hardware token or key store, if the platform provides one
- Password hashing tool with a tunable cost parameter
- Reference test vectors from the standard for each primitive in use
- Two machines for a key exchange test, and a packet capture for review
- A ledger of key identifiers, rotation dates, and owners

## Procedure

### Classify the data

1. Decide what each piece of data is: public, needing confidentiality,
   needing integrity only, or needing a verifiable signature.
2. Map each requirement onto one primitive and write the choice down
   before any code is written.
3. Set the key lifetime and the rotation interval from the risk and the
   cost of re-keying.

### Manage the keys

1. Generate every key with the system's secure random source, never with
   a general purpose random number generator.
2. Derive keys from passwords with a memory-hard function such as
   Argon2id, or with PBKDF2-HMAC-SHA256 at a cost of at least 600000
   iterations, and give every password a random salt of at least 16 bytes.
3. Keep long-term keys away from the code and from the backups they
   protect, and wrap them with a key held in a passphrase or a token.

### Encrypt and authenticate

1. Use an authenticated mode such as AES-GCM or ChaCha20-Poly1305, and
   generate a fresh random nonce of 12 bytes for every message under a
   given key.
2. Bind the context into the authenticated data, so a message cannot be
   moved from one context to another without being detected.
3. Compare the tags in constant time and reject any message that fails,
   before acting on any part of the plaintext.

### Verify and maintain

1. Run the reference test vectors from the standard for every primitive
   and record the results.
2. Test the failure paths: a wrong key, a truncated message, a repeated
   nonce, and an expired certificate must all be rejected.
3. Rotate the keys on schedule, revoke what must be revoked, and keep an
   audit trail of every use.

## Safety Notes

- The hazard here is false security. A misused or weak cipher gives the
  same confidence as a strong one while protecting nothing, so use
  libraries and primitives reviewed by others and never invent one.
- Only do this work with appropriate training, supervision, and
  equipment, and have designs that handle authentication or personal data
  reviewed by qualified people.
- Keys hard-coded in source, firmware, or an image can be extracted from
  the device, so treat any key in a binary as public.
- Keys stored on the same medium as the data they protect protect
  nothing against theft of that medium.
- Randomness from a weak source makes every derived key guessable, and
  the failure is silent.
- Constant-time comparison matters: a byte-by-byte early exit leaks the
  correct value one byte at a time.
- Passwords must not be stored reversibly, must not be logged, and must
  not use a fast hash such as MD5 or SHA-256 without a work factor.
- Never disable certificate or host verification to make a connection
  succeed; that is exactly how a connection gets intercepted.
- Keep key material out of logs, crash dumps, swap, and backups unless
  those stores are protected as carefully as the keys themselves.

## Verification

- **Status:** draft
- **Tested by:** —
- **Date:** —

## Sources

- NIST Cryptographic Standards (public domain)
