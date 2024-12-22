locals {
  default_lan = { default = { name = "Default", id = var.default_network_id } }
  lans_untrusted = {
    for k, v in var.networks : k => v
    if v.type == "untrusted" || v.type == null
  }
  lans_isolated = {
    for k, v in var.networks : k => v
    if v.type == "isolated"
  }
  lans_trusted = {
    for k, v in var.networks : k => v
    if v.type == "trusted"
  }
  lans_reservation = {
    for k, v in var.networks : k => v
    if v.type == "reservation"
  }
  lans_remote = {
    for k, v in var.networks : k => v
    if v.type == "remote"
  }
  lans_physical = merge(local.lans_untrusted, local.lans_isolated, local.lans_trusted)
  lans_all      = merge(local.lans_untrusted, local.lans_isolated, local.lans_trusted, local.lans_reservation, local.lans_remote, local.default_lan)
}

resource "unifi_network" "lan_default" {
  name    = "Default"
  purpose = "corporate"

  subnet        = "10.${local.default_lan.default.id}.0.0/16"
  domain_name   = var.domain_name
  multicast_dns = true

  dhcp_enabled    = true
  dhcp_start      = "10.${local.default_lan.default.id}.128.2"
  dhcp_stop       = "10.${local.default_lan.default.id}.255.254"
  dhcp_v6_enabled = true
  dhcp_v6_start   = "::2"
  dhcp_v6_stop    = "::7d1"

  ipv6_interface_type    = "static"
  ipv6_static_subnet     = cidrsubnet(var.ipv6_pd, 8, local.default_lan.default.id)
  ipv6_pd_interface      = "wan"
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

resource "unifi_network" "lan" {
  for_each = local.lans_physical

  name    = each.value.name
  purpose = each.value.purpose != null ? each.value.purpose : "corporate"

  subnet        = "10.${each.value.id}.0.0/16"
  domain_name   = var.domain_name
  multicast_dns = each.value.multicast_dns != null ? each.value.multicast_dns : false
  vlan_id       = (1000 + each.value.id)

  dhcp_enabled    = each.value.disable_dhcp != null ? !each.value.disable_dhcp : true
  dhcp_start      = "10.${each.value.id}.128.2"
  dhcp_stop       = "10.${each.value.id}.255.254"
  dhcp_v6_enabled = each.value.disable_dhcp != null ? !each.value.disable_dhcp : true
  dhcp_v6_start   = "::2"
  dhcp_v6_stop    = "::7d1"

  ipv6_interface_type    = each.value.disable_ipv6 == true ? "none" : "static"
  ipv6_static_subnet     = each.value.disable_ipv6 == true ? null : cidrsubnet(var.ipv6_pd, 8, each.value.id)
  ipv6_pd_start          = "::2"
  ipv6_pd_stop           = "::7d1"
  ipv6_ra_enable         = each.value.disable_ipv6_ra != null ? !each.value.disable_ipv6_ra : true
  ipv6_ra_priority       = "high"
  ipv6_ra_valid_lifetime = 0

  dhcp_dns         = each.value.dns
  dhcp_v6_dns      = each.value.dns_v6
  dhcp_v6_dns_auto = each.value.dns_v6 == null

  lifecycle {
    ## Changes to DHCPv6 settings are not currently reflected in the controller.
    ##
    ignore_changes = [dhcp_v6_enabled]
  }
}

resource "unifi_network" "lan_reservation" {
  for_each = local.lans_reservation

  name    = "_${each.value.name}"
  purpose = "corporate"

  subnet      = "10.${each.value.id}.0.0/${each.value.mask}"
  domain_name = var.domain_name
  vlan_id     = (1000 + each.value.id)

  dhcp_enabled    = false
  dhcp_v6_enabled = false
  dhcp_v6_start   = "::2"
  dhcp_v6_stop    = "::7d1"

  ipv6_interface_type = "static"
  ipv6_static_subnet  = cidrsubnet(var.ipv6_pd, 8, each.value.id)
  ipv6_ra_enable      = false
  ipv6_ra_priority    = "high"
  ipv6_pd_start       = "::2"
  ipv6_pd_stop        = "::7d1"
}

resource "unifi_port_profile" "lan" {
  for_each = local.lans_physical

  name                  = each.value.name
  native_networkconf_id = unifi_network.lan[each.key].id
  poe_mode              = "auto"

  lifecycle {
    ignore_changes = [forward]
  }
}

resource "unifi_port_profile" "disabled" {
  name                  = "Disabled"
  poe_mode              = "off"
  forward               = "disabled"
  port_security_enabled = true
}
