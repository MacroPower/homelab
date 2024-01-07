resource "unifi_network" "wan_primary" {
  name    = "Primary (WAN1)"
  purpose = "wan"

  wan_networkgroup           = "WAN"
  wan_type                   = "dhcp"
  wan_type_v6                = "dhcpv6"
  wan_dhcp_v6_pd_size        = var.ipv6_pd_mask
  wan_egress_qos             = 0
  dhcp_lease                 = 0
  dhcp_v6_dns_auto           = false
  dhcp_v6_lease              = 0
  ipv6_ra_preferred_lifetime = 0
  ipv6_ra_valid_lifetime     = 0
}
