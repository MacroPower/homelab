# BGP on UDM Pro

## References

https://www.map59.com/ubiquiti-udm-running-bgp/
https://pastebin.com/APqwtmtf

## Configuration

`/etc/frr/bgpd.conf`:

```
! -*- bgp -*-
!
hostname unifi.home.macro.network
password ${bgp_password}
frr defaults traditional
log file stdout
!
router bgp 64512
 no bgp ebgp-requires-policy
 bgp router-id 10.0.0.1
 maximum-paths 1
 !
 ! Peer group for Cilium BGP
 neighbor CBGP peer-group
 neighbor CBGP remote-as 64512
 neighbor CBGP activate
 neighbor CBGP soft-reconfiguration inbound
 neighbor CBGP timers 15 45
 neighbor CBGP timers connect 15
 !
 ! Neighbors for Cilium BGP
 neighbor 10.10.10.6 peer-group CBGP
 neighbor 10.10.10.13 peer-group CBGP
 neighbor 10.10.10.14 peer-group CBGP
 neighbor 10.10.10.15 peer-group CBGP
 !
 address-family ipv4 unicast
  redistribute connected
  !
  neighbor CBGP activate
  neighbor CBGP route-map ALLOW-ALL in
  neighbor CBGP route-map ALLOW-ALL out
  neighbor CBGP next-hop-self
 exit-address-family
 !
 address-family ipv6 unicast
  redistribute connected
  !
  neighbor CBGP activate
  neighbor CBGP route-map ALLOW-ALL in
  neighbor CBGP route-map ALLOW-ALL out
  neighbor CBGP next-hop-self
 exit-address-family
 !
route-map ALLOW-ALL permit 10
!
line vty
!
```

### Helpful Commands

```
service frr status
service frr restart
ls -l /etc/frr
cat /etc/frr/bgpd.conf
```
