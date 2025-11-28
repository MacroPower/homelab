# HCloud Wireguard

```toml
[Interface]
Address = 2a01:4f8:c010:945c:ac1e::1/120,10.42.1.1/24
ListenPort = 51820
PrivateKey = [REDACTED]
MTU = 1450
PostUp = nft add rule inet filter forward oifname "%i" accept || true
PreDown =
PostDown =
Table = auto

# Name: unifi.cin.macro.network
[Peer]
PublicKey = [REDACTED]
PresharedKey = [REDACTED]
IPAllocation = 10.42.1.11/32
AllowedIPs = 0.0.0.0/0,::/0
ExtraAllowedIPs = 10.10.0.0/16
PersistentKeepalive = 15
```

NOTE: Unifi considers Wireguard traffic to be WAN/Internet traffic, even though it may use a private IP range. Thus you will need to add a firewall rule in "Internet IN" to allow incoming traffic.

To ensure changes are applied, run:

```sh
wg-quick down wg0 && wg-quick up wg0
```
