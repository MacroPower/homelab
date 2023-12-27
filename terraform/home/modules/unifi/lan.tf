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
  ipv6_pd_prefixid       = "00"
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
  lans = {
    main = {
      name = "Main"
      id   = 1
    }
    guest = {
      name    = "Guest"
      id      = 5
      purpose = "guest"
    }
    lab_management = {
      name = "Lab Management"
      id   = 9
    }
    lab = {
      name = "Lab"
      id   = 10
    }
    iot = {
      name = "IoT"
      id   = 20
    }
  }
}

resource "unifi_network" "lan" {
  for_each = local.lans

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
  ipv6_pd_start          = "::2"
  ipv6_pd_stop           = "::7d1"
  ipv6_ra_enable         = true
  ipv6_ra_priority       = "high"
  ipv6_ra_valid_lifetime = 0
  # Hex doesn't play nice with padding
  ipv6_pd_prefixid = length(format("%x", each.value.id)) > 1 ? format("%x", each.value.id) : format("0%x", each.value.id)

  lifecycle {
    ## Changes to DHCPv6 settings are not currently reflected in the controller.
    ##
    ignore_changes = [dhcp_v6_enabled]
  }
}

resource "unifi_port_profile" "lan" {
  for_each = local.lans

  name                  = each.value.name
  native_networkconf_id = unifi_network.lan[each.key].id
  poe_mode              = "auto"

  lifecycle {
    ignore_changes = [forward]
  }
}

resource "unifi_network" "lan_k8s_services" {
  name    = "K8s Services"
  purpose = "corporate"

  subnet      = "10.112.0.0/12"
  domain_name = var.domain_name
  vlan_id     = 1112

  dhcp_enabled    = false
  dhcp_v6_enabled = false

  ipv6_interface_type = "pd"
  ipv6_pd_interface   = "wan"
  ipv6_pd_prefixid    = format("%x", 112)
  ipv6_ra_enable      = false
  ipv6_pd_start       = "::2"
  ipv6_pd_stop        = "::7d1"
}

resource "unifi_network" "lan_k8s_pods" {
  name    = "K8s Pods"
  purpose = "corporate"

  subnet      = "10.128.0.0/14"
  domain_name = var.domain_name
  vlan_id     = 1128

  dhcp_enabled    = false
  dhcp_v6_enabled = false

  ipv6_interface_type = "pd"
  ipv6_pd_interface   = "wan"
  ipv6_pd_prefixid    = format("%x", 128)
  ipv6_ra_enable      = false
  ipv6_pd_start       = "::2"
  ipv6_pd_stop        = "::7d1"
}
