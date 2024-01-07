locals {
  active_lans = merge(local.lans, local.lans_unrestricted, local.default_lan)
}

resource "unifi_firewall_group" "lan_ipv4" {
  for_each = local.active_lans

  name = "${each.value.name} (IPv4)"
  type = "address-group"

  members = [
    "10.${each.value.id}.0.0/16",
  ]
}

resource "unifi_firewall_group" "lan_ipv6" {
  for_each = local.active_lans

  name = "${each.value.name} (IPv6)"
  type = "ipv6-address-group"

  members = [
    "${var.ipv6_pd}${format("%02x", each.value.id)}::/64",
  ]
}

resource "unifi_firewall_rule" "allow_related_established_ipv4" {
  for_each = merge(local.default_lan, local.lans_unrestricted)

  name       = "Allow related and established to ${each.value.name}"
  action     = "accept"
  ruleset    = "LAN_IN"
  protocol   = "all"
  rule_index = 21000 + each.value.id

  dst_firewall_group_ids = [unifi_firewall_group.lan_ipv4[each.key].id]

  state_established = true
  state_related     = true
}

resource "unifi_firewall_rule" "allow_related_established_ipv6" {
  for_each = merge(local.default_lan, local.lans_unrestricted)

  name        = "Allow related and established to ${each.value.name}"
  action      = "accept"
  ruleset     = "LANv6_IN"
  protocol_v6 = "all"
  rule_index  = 25000 + each.value.id

  dst_firewall_group_ids = [unifi_firewall_group.lan_ipv6[each.key].id]

  state_established = true
  state_related     = true
}

resource "unifi_firewall_rule" "allow_traffic_ipv4" {
  for_each = merge(local.default_lan, local.lans_unrestricted)

  name       = "Allow traffic from ${each.value.name}"
  action     = "accept"
  ruleset    = "LAN_IN"
  protocol   = "all"
  rule_index = 21500 + each.value.id

  src_firewall_group_ids = [unifi_firewall_group.lan_ipv4[each.key].id]
}

resource "unifi_firewall_rule" "allow_traffic_ipv6" {
  for_each = merge(local.default_lan, local.lans_unrestricted)

  name        = "Allow traffic from ${each.value.name}"
  action      = "accept"
  ruleset     = "LANv6_IN"
  protocol_v6 = "all"
  rule_index  = 25500 + each.value.id

  src_firewall_group_ids = [unifi_firewall_group.lan_ipv6[each.key].id]
}

resource "unifi_firewall_rule" "drop_traffic_ipv4" {
  for_each = merge(local.lans, local.lans_unrestricted)

  name       = "Drop traffic to ${each.value.name}"
  action     = "drop"
  ruleset    = "LAN_IN"
  protocol   = "all"
  rule_index = 22000 + each.value.id

  dst_firewall_group_ids = [unifi_firewall_group.lan_ipv4[each.key].id]
}

resource "unifi_firewall_rule" "drop_traffic_ipv6" {
  for_each = merge(local.lans, local.lans_unrestricted)

  name        = "Drop traffic to ${each.value.name}"
  action      = "drop"
  ruleset     = "LANv6_IN"
  protocol_v6 = "all"
  rule_index  = 26000 + each.value.id

  dst_firewall_group_ids = [unifi_firewall_group.lan_ipv6[each.key].id]
}
