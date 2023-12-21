resource "unifi_network" "lan_default" {
  name    = "Default"
  purpose = "corporate"

  subnet        = "10.0.0.0/16"
  domain_name   = var.domain_name
  multicast_dns = true

  dhcp_enabled    = true
  dhcp_start      = "10.0.128.2"
  dhcp_stop       = "10.0.255.254"
  dhcp_v6_enabled = true
  dhcp_v6_start   = "::2"
  dhcp_v6_stop    = "::7d1"

  ipv6_interface_type    = "pd"
  ipv6_pd_interface      = "wan"
  ipv6_pd_prefixid       = "1"
  ipv6_pd_start          = "::2"
  ipv6_pd_stop           = "::7d1"
  ipv6_ra_enable         = true
  ipv6_ra_priority       = "high"
  ipv6_ra_valid_lifetime = 0

  lifecycle {
    ## Changes to DHCPv6 settings are not currently reflected in the controller.
    ##
    ignore_changes = [dhcp_v6_enabled]
  }
}

locals {
  lan_16 = {
    guest = {
      name    = "Guest"
      id      = 5
      purpose = "guest"
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

  name    = each.value.name
  purpose = lookup(each.value, "purpose", "corporate")

  subnet        = "10.${each.value.id}.0.0/16"
  domain_name   = var.domain_name
  multicast_dns = true
  vlan_id       = (1000 + each.value.id)

  dhcp_enabled    = true
  dhcp_start      = "10.${each.value.id}.128.2"
  dhcp_stop       = "10.${each.value.id}.255.254"
  dhcp_v6_enabled = true
  dhcp_v6_start   = "::2"
  dhcp_v6_stop    = "::7d1"

  ipv6_interface_type    = "pd"
  ipv6_pd_interface      = "wan"
  ipv6_pd_prefixid       = each.value.id + 1
  ipv6_pd_start          = "::2"
  ipv6_pd_stop           = "::7d1"
  ipv6_ra_enable         = true
  ipv6_ra_priority       = "high"
  ipv6_ra_valid_lifetime = 0

  lifecycle {
    ## Changes to DHCPv6 settings are not currently reflected in the controller.
    ##
    ignore_changes = [dhcp_v6_enabled]
  }
}
