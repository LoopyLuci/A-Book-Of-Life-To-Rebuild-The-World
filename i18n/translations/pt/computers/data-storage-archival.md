# Data Storage, Filesystems and Archival

> **Domain:** computers | **Difficulty:** apprentice | **Safety:** green

*Reference material only. Verify this information against primary sources
and qualified professionals before acting on it. This entry is not a sole
source of information.*

## Overview

Storage is a ladder of trade-offs between speed, capacity, and how long a
record survives. A filesystem turns a block device into named files with
permissions, and above it a backup and an archive keep the data when the
machine dies. The key principle is that a copy is not a backup until it
has been read back, so the measure of a storage system is not how much it
holds but how much of it can be restored.

## Prerequisites

- Command line use and a text editor
- Basic file and directory concepts
- An understanding of what a checksum function does
- A spare disk or a virtual disk image to experiment on

## Materials & Tools

- Several disks of different sizes, or virtual disk images
- Checksum tool, archive tool, and a backup utility
- A filesystem that logs writes, such as an ext4 or btrfs volume
- A second, separate machine or network target for the off-site copy
- Antistatic kit, drive caddy, and a label maker for the disks
- A written ledger listing each disk, its contents, and its checksum
- Test files of known size to measure real throughput

## Procedure

### Choose and prepare the medium

1. Test every disk before trusting it by writing and reading back a file
   across the whole surface, then record the result on the label.
2. Choose a filesystem and mount options that suit the role, and turn on
   journalling or a checksummed mode where the medium allows it.
3. Write the partition table and the filesystem, then confirm that the
   sizes reported match the sizes on the label.

### Lay out the data

1. Follow the filesystem hierarchy for the system directories: /etc for
   configuration, /var for variable data, /home for user files, and /usr
   for read-only programs.
2. Separate the data that changes often from the data that never changes,
   so caches and backups can be handled on different schedules.
3. Record a checksum for every file and store the list with the data, so a
   later read can prove the bytes are still the ones you stored.

### Copy and verify

1. Take a full copy first, then schedule the increments, and keep the
   copies on different media from the original.
2. Follow the rule of three copies on two kinds of media, with one copy
   held somewhere else.
3. After each copy, read it back and compare the checksums, then record
   the result and the date in the ledger.

### Archive for the long term

1. Choose a format that can be read without the tool that wrote it, and
   prefer plain uncompressed files when the content matters most.
2. Fix the permissions and ownership inside the archive so it restores
   onto a new machine without guesswork.
3. Test a full restore into a clean directory, compare it with the
   original using checksums, and repeat the test on a schedule.

## Safety Notes

- A partition table written to the wrong disk destroys data without
  warning. Back up first, work on a spare disk to learn the procedure,
  and label every drive with its identifier.
- A redundant array is not a backup. A failed controller, a deleted file,
  or malware takes every copy with it, so keep one copy offline.
- The write cache in a drive lies about durability unless it is flushed.
  Enable the flush of the write cache, and back up after any unclean
  shutdown.
- Drives are fragile: never move a spinning disk while it runs, use the
  antistatic kit, and keep the drives separated and ventilated.
- Never use the only copy as the source of a destructive operation, and
  never format a device by its partition number without checking the
  serial number in the system log.
- Assume silent corruption in stored media and check the fixity of the
  archive on a schedule, not once at the start.
- Keep free space on every volume; a full filesystem can corrupt a
  database and can stop an archive from being written at all.

## Verification

- **Status:** draft
- **Tested by:** —
- **Date:** —

## Sources

- Linux Filesystem Hierarchy Standard (public domain)
