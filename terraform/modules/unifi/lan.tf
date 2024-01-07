locals {
  default_lan = { default = { name = "Default", id = var.default_network_id } }
  lans = {
    for k, v in var.networks : k => v
    if v.type == "restricted" || v.type == null
  }
  lans_unrestricted = {
    for k, v in var.networks : k => v
    if v.type == "unrestricted"
  }
  lans_reservation = {
    for k, v in var.networks : k => v
    if v.type == "reservation"
  }
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

resource "unifi_network" "lan" {
  for_each = merge(local.lans, local.lans_unrestricted)

  name    = each.value.name
  purpose = each.value.purpose != null ? each.value.purpose : "corporate"

  subnet        = "10.${each.value.id}.0.0/16"
  domain_name   = var.domain_name
  multicast_dns = each.value.multicast_dns != null ? each.value.multicast_dns : false
  vlan_id       = (1000 + each.value.id)

  dhcp_enabled    = true
  dhcp_start      = "10.${each.value.id}.128.2"
  dhcp_stop       = "10.${each.value.id}.255.254"
  dhcp_v6_enabled = true
  dhcp_v6_start   = "::2"
  dhcp_v6_stop    = "::7d1"

  ipv6_interface_type    = each.value.disable_ipv6 == true ? "none" : "pd"
  ipv6_pd_interface      = "wan"
  ipv6_pd_start          = "::2"
  ipv6_pd_stop           = "::7d1"
  ipv6_ra_enable         = true
  ipv6_ra_priority       = "high"
  ipv6_ra_valid_lifetime = 0
  # Hex doesn't play nice with padding
  ipv6_pd_prefixid = length(format("%x", each.value.id)) > 1 ? format("%x", each.value.id) : format("0%x", each.value.id)

  dhcp_dns    = each.value.dns
  dhcp_v6_dns = each.value.dns_v6

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

  ipv6_interface_type = "pd"
  ipv6_pd_interface   = "wan"
  ipv6_pd_prefixid    = format("%x", each.value.id)
  ipv6_ra_enable      = false
  ipv6_pd_start       = "::2"
  ipv6_pd_stop        = "::7d1"
}

resource "unifi_port_profile" "lan" {
  for_each = merge(local.lans, local.lans_unrestricted)

  name                  = each.value.name
  native_networkconf_id = unifi_network.lan[each.key].id
  poe_mode              = "auto"

  lifecycle {
    ignore_changes = [forward]
  }
}

resource "unifi_firewall_rule" "allow_related_established" {
  for_each = merge(local.default_lan, local.lans_unrestricted)

  name       = "Allow related and established to ${each.value.name}"
  action     = "accept"
  ruleset    = "LAN_IN"
  protocol   = "all"
  rule_index = 20000 + each.value.id

  dst_network_id = merge({ default = unifi_network.lan_default }, unifi_network.lan)[each.key].id

  state_established = true
  state_related     = true
}

resource "unifi_firewall_rule" "allow_traffic" {
  for_each = merge(local.default_lan, local.lans_unrestricted)

  name       = "Allow traffic from ${each.value.name}"
  action     = "accept"
  ruleset    = "LAN_IN"
  protocol   = "all"
  rule_index = 21000 + each.value.id

  src_network_id = merge({ default = unifi_network.lan_default }, unifi_network.lan)[each.key].id
}

resource "unifi_firewall_rule" "drop_traffic" {
  for_each = merge(local.lans, local.lans_unrestricted)

  name       = "Drop traffic to ${each.value.name}"
  action     = "drop"
  ruleset    = "LAN_IN"
  protocol   = "all"
  rule_index = 22000 + each.value.id

  dst_network_id = unifi_network.lan[each.key].id
}

resource "unifi_port_profile" "disabled" {
  name                  = "Disabled"
  poe_mode              = "off"
  forward               = "disabled"
  port_security_enabled = true
}
