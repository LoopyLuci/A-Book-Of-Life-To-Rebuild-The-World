# Networking Protocols

> **Domain:** computers | **Difficulty:** journeyman | **Safety:** green

*Reference material only. Verify this information against primary sources
and qualified professionals before acting on it. This entry is not a sole
source of information.*

## Overview

Networking is a stack of layers, each adding a service on the one below:
addresses and routing, reliable delivery, names, and the application
conversation on top. Knowing which layer owns a fault makes diagnosis
mechanical instead of guesswork, because each layer has its own packets,
its own state machine, and its own tools. The key principle is that the
layers only promise what is theirs: an internet packet arrives or it does
not, and nothing above may assume delivery, order, or timing.

## Prerequisites

- DC Circuit Analysis, for the signal-level view of a link
- Basic networking vocabulary: address, port, protocol, and subnet
- Command line use and a text editor
- Reading a packet capture

## Materials & Tools

- Two or more machines on a shared switch, plus a spare machine as a peer
- Packet capture tool, protocol analyser, and a terminal program
- Cable tester and a loopback plug for the physical layer
- Router or soft router for the gateway and the routing tests
- A nameserver for the name lookups and a DHCP server on the test segment
- A configuration sheet and a written record of every change made

## Procedure

### Map the stack

1. Draw the seven layers of the model and write down the protocol, the
   address, and the port that belong to each layer you will meet.
2. Capture one request and identify the frames, packets, and segments
   inside it, naming the protocol used at each layer.
3. Note the address in each header: the media address, the internet
   address, and the transport port.

### Move packets

1. Give each test host an address and a prefix length, then confirm
   reachability with an address and route lookup.
2. Read the routing table on the router, add a static route for a test
   network, and trace the path to it.
3. Measure the round trip time and the loss to a neighbouring host, then
   repeat with the largest packet that passes without fragmenting.

### Connect and transfer

1. Open a reliable connection and watch the three-way handshake and the
   four-way close in the capture.
2. Transfer a file and compare the throughput with the bandwidth-delay
   product, checking the congestion window and the receive buffer.
3. Break the link during the transfer, watch both ends recover, and check
   the timeout and the connection state afterwards.

### Name and configure

1. Resolve a name to an address and read the answer, then look up the
   address for a name and compare the two records.
2. Watch the four-step lease exchange on the test segment and check the
   address, mask, gateway, and lease time the client received.
3. Confirm that a host with no working nameserver can still reach an
   address directly, and record the difference in the logs.

## Safety Notes

- Keep test networks isolated from any link that reaches the public
  internet. An exposed lab host is a liability for everyone behind it.
- A wrong subnet mask, a wrong default route, or a mistaken firewall rule
  can cut the whole site off the network at once. Keep console access to
  the router and write down the previous setting before changing it.
- Never operate an open resolver or a public domain name server on a small
  site; it will be used to amplify attacks against other people.
- A rogue DHCP server on the segment can hand out a false gateway and
  capture traffic. Only run DHCP on a network you control.
- Credentials sent over a plaintext protocol are readable by anyone on
  the path. Use an encrypted transport for logins and administration.
- Power over network cabling puts 48 volts DC on the pairs. Check the
  power budget before connecting a device, and never patch a live line
  into unknown equipment.
- Lines that leave the building need surge and lightning protection; a
  surge on a copper drop destroys the equipment at both ends.

## Verification

- **Status:** draft
- **Tested by:** —
- **Date:** —

## Sources

- IETF RFC Series (public domain)
