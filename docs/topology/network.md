# Network Topology

## Subnetting

I've chosen a setup that prioritizes simplicity of dual-stack networking.

IPv4 Subnets are all /16s, which are cut from a class-a private address range. The IPv6 prefixes are all /64, which are cut from a /56 prefix delegation. This means that there are 256 available subnets for both IPv4 and IPv6, which we can line up nicely using subnet IDs 0-255. In this case, the ID matches the second IPv4 octet, and the IPv6 prefix ID (off by 1). It is not possible to cut the IPv6 prefix any smaller than a /64, so there is not much point in cutting the IPv4 subnets any smaller than a /16 as we can only have a maximum of 256 subnets anyway.

The upside to this is, for a homelab, this means we have a "good enough" number of subnets, and we basically never have to worry about running out of addresses, since each subnet can contain up to 65,534 dual-stack hosts.

The DHCPv4 range is the second half of the subnet (effectively a /17). The first half of the subnet is reserved for static IPs, but in general I tend to avoid static IPs in favor of using DNS. The DHCPv6 range is basically just arbitrary, and there is no static IPv6 assignment. Instead, addresses are returned via DNS to clients that support IPv6, since those clients are provided with an IPv6 DNS server via DHCPv6.

## VLANs

In my network, VLANs and subnets always have a 1:1 mapping. VLANs use the same ID as the subnet, plus 1000, for simplicity. For example, subnet 5 would have VLAN 1005. The exception is the default VLAN, which is set to 1, and maps to subnet 0.

In most cases, VLANs are configured such that they have Internet connectivity, and can communicate with other devices on the same VLAN, but cannot access devices on any other VLAN.

Exceptions:

- The Default VLAN, which is configured to allow communication to (but not from) all other VLANs.
- The Guest VLAN, which uses Unifi's guest isolation, i.e. only allows Internet access.

```
┌───────────┐                 ┌───────────┐
│           │────────────────▶│           │
│  Default  │                 │    IoT    │
│           │ X ◁─────────────│           │
└───────────┘                 └───────────┘
    │  X                           │  X
    │  △                           │  △
    │  │                           │  │
    │  │                           ▽  │
    │  │                           X  │
    │  │                      ┌───────────┐
    │  └──────────────────────│           │
    │                         │    Lab    │
    └────────────────────────▶│           │
                              └───────────┘
```
