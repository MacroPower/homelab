resource "unifi_network" "lan_default" {
  name    = "Default"
  purpose = "corporate"

  subnet        = "192.168.0.0/18"
  domain_name   = var.domain_name
  multicast_dns = true

  dhcp_enabled  = true
  dhcp_start    = "192.168.10.2"
  dhcp_stop     = "192.168.19.254"
  dhcp_v6_start = "::2"
  dhcp_v6_stop  = "::7d1"

  ipv6_interface_type    = "pd"
  ipv6_pd_interface      = "wan"
  ipv6_pd_start          = "::2"
  ipv6_pd_stop           = "::7d1"
  ipv6_ra_enable         = true
  ipv6_ra_priority       = "high"
  ipv6_ra_valid_lifetime = 0
}

locals {
  lan_16 = {
    main = {
      name = "Main"
      id   = 0
    }
    guest = {
      name = "Guest"
      id   = 5
    }
    storage_management = {
      name = "Storage Management"
      id   = 9
    }
    storage = {
      name = "Storage"
      id   = 10
    }
    security = {
      name = "Security"
      id   = 15
    }
    iot = {
      name = "IoT"
      id   = 20
    }
    k8s_node_management = {
      name = "K8s Node Management"
      id   = 49
    }
    k8s_nodes = {
      name = "K8s Nodes"
      id   = 50
    }
  }
}

resource "unifi_network" "lan_16" {
  for_each = local.lan_16

  name     = each.value.name
  purpose  = "corporate"

  subnet        = "10.${each.value.id}.0.0/16"
  domain_name   = var.domain_name
  multicast_dns = true
  vlan_id       = (1000 + each.value.id)

  dhcp_enabled  = true
  dhcp_start    = "10.${each.value.id}.10.2"
  dhcp_stop     = "10.${each.value.id}.19.254"
  dhcp_v6_start = "::2"
  dhcp_v6_stop  = "::7d1"

  ipv6_interface_type    = "pd"
  ipv6_pd_interface      = "wan"
  ipv6_pd_start          = "::2"
  ipv6_pd_stop           = "::7d1"
  ipv6_ra_enable         = true
  ipv6_ra_priority       = "high"
  ipv6_ra_valid_lifetime = 0
}
