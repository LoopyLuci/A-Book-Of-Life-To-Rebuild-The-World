# Post-Quantum Cryptography

> **Domain:** quantum | **Difficulty:** journeyman | **Safety:** yellow

*Reference material only. Verify this information against primary sources
and qualified professionals before acting on it. This entry is not a sole
source of information.*

## Overview

Post-quantum cryptography is the set of public-key schemes designed to
survive an adversary with a quantum computer, and moving off RSA and
elliptic-curve keys is the largest cryptographic change since the public
key itself. The key principle is that the security of the new schemes
rests on lattice, hash, or code problems rather than on factoring or the
elliptic-curve discrete logarithm, so the old keys have to be replaced and
not merely padded. The signatures are far larger and the key sizes
differ, so the migration is an engineering problem as much as a
mathematical one.

## Prerequisites

- Public-key cryptography, key agreement, and digital signatures
- Symmetric primitives, AES-256 and SHA-256, and their security margins
- The lattice problems Module-LWE and Module-SIS
- Hash-based signatures and the Merkle tree construction

## Materials & Tools

- A cryptographic library with the standardised algorithms, such as liboqs,
  Botan, or OpenSSL 3.5
- A hardware security module or a key management system for the key store
- The published test vectors from the standards, for known-answer tests
- A capture tool and a TLS test harness for the migration check
- An inventory of every public key in the organisation, with its owner
- An internal or external certificate authority that can issue the new
  certificates

## Procedure

### Choose the algorithms

1. Use the standardised key encapsulation mechanism ML-KEM, from FIPS 203,
   for key establishment, and prefer ML-KEM-768, which sits at NIST
   security category 3.
2. Use ML-DSA, from FIPS 204, for general-purpose signatures, in the 44,
   65, or 87 variants; the 65 variant also sits at category 3.
3. Use SLH-DSA, from FIPS 205, when a hash-based signature with a very
   small public key of 32 bytes is needed, and use the stateful LMS and
   XMSS schemes only where the one-time-signature state can be backed up
   correctly.

### Size the deployment

1. Compare the sizes against the alternatives: an RSA-2048 signature is
   256 bytes, an ML-DSA-44 signature is 2420 bytes, and an ML-KEM-768
   encapsulation key is 1184 bytes.
2. Check the bandwidth and the storage of the target links, and watch the
   effect on constrained firmware, where a 5 kilobyte signature may not fit
   in the flash and the update path.
3. Benchmark key generation, encapsulation, decapsulation, and signing on
   the target platform, because the processor cost matters as much as the
   size.

### Deploy a hybrid key exchange

1. Run the classical and the post-quantum algorithm side by side and
   combine the two shared secrets with a key derivation function such as
   HKDF, rather than concatenating them raw.
2. Negotiate the hybrid group in the TLS configuration, using the group
   name that pairs X25519 with ML-KEM-768, and confirm which one the
   library and the peers actually support.
3. Verify that both peers agree on the group and fail the handshake closed
   if they do not, because a silent downgrade defeats the purpose.

### Plan and maintain the migration

1. Inventory every certificate, every key pair, and every signed firmware
   image, and replace the RSA and elliptic-curve key exchange first,
   because the harvest-now-decrypt-later risk is the immediate one.
2. Replace the signing keys next, starting with the certificate
   authorities and with firmware signing, and roll over so that the old
   and the new certificates are trusted at the same time.
3. Store the new private keys in the same hardware security module, back
   up and test the restore of any signing state, and remove the RSA key
   paths once nothing uses them.

## Safety Notes

- This is a yellow-level task because the loss of a private key is a
  security incident, and because the transition itself is a period of
  mixed algorithms that an attacker can try to exploit.
- Never deploy a post-quantum scheme from an unvetted implementation, and
  use the standardised algorithms with the published test vectors.
- Never reuse a hash-based signing state, because a repeated signature
  exposes the private key and the whole chain behind it.
- Keep the key material in a hardware security module, and never in the
  application, a log, or a configuration file.
- Plan against the downgrade attack: an adversary who can force a
  fallback to RSA has defeated the migration, so the policy must refuse the
  old groups rather than merely prefer the new ones.
- Keep a rollback path and a tested restore of the signing state, because
  a failed rotation is worse than a late one.
- This entry gives engineering guidance only and is not legal advice;
  compliance and contractual requirements belong to the responsible owner.

## Verification

- **Status:** draft
- **Tested by:** —
- **Date:** —

## Sources

- NIST Post-Quantum Cryptography Standards (public domain)
