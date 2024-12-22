resource "unifi_firewall_group" "lan_ipv4" {
  for_each = local.lans_all

  name = "${each.value.name} (IPv4)"
  type = "address-group"

  members = [
    "10.${each.value.id}.0.0/16",
  ]
}

resource "unifi_firewall_group" "lan_ipv4_all" {
  name = "LAN (IPv4)"
  type = "address-group"

  members = ["10.0.0.0/8"]
}

resource "unifi_firewall_group" "lan_ipv4_exceptions" {
  for_each = { for k, v in var.firewall_exceptions : k => v if v.ipv4 != null }

  name = "${each.value.name} (IPv4)"
  type = "address-group"

  members = [
    "${each.value.ipv4}",
  ]
}

resource "unifi_firewall_group" "lan_ipv6" {
  for_each = local.lans_all

  name = "${each.value.name} (IPv6)"
  type = "ipv6-address-group"

  members = [
    cidrsubnet(var.ipv6_pd, 8, each.value.id),
  ]
}

resource "unifi_firewall_group" "lan_ipv6_all" {
  name = "LAN (IPv6)"
  type = "ipv6-address-group"

  members = ["fe80::/10", "${var.ipv6_pd}"]
}

resource "unifi_firewall_group" "lan_ipv6_exceptions" {
  for_each = { for k, v in var.firewall_exceptions : k => v if v.ipv6 != null }

  name = "${each.value.name} (IPv6)"
  type = "ipv6-address-group"

  members = [
    "${each.value.ipv6}",
  ]
}

resource "unifi_firewall_rule" "allow_related_established_ipv4" {
  name       = "Allow related and established traffic"
  action     = "accept"
  ruleset    = "LAN_IN"
  protocol   = "all"
  rule_index = 21000

  src_firewall_group_ids = [unifi_firewall_group.lan_ipv4_all.id]
  dst_firewall_group_ids = [unifi_firewall_group.lan_ipv4_all.id]

  state_established = true
  state_related     = true
}

resource "unifi_firewall_rule" "allow_related_established_ipv6" {
  name        = "Allow related and established traffic"
  action      = "accept"
  ruleset     = "LANv6_IN"
  protocol_v6 = "all"
  rule_index  = 26000

  src_firewall_group_ids = [unifi_firewall_group.lan_ipv6_all.id]
  dst_firewall_group_ids = [unifi_firewall_group.lan_ipv6_all.id]

  state_established = true
  state_related     = true
}

resource "unifi_firewall_rule" "allow_self_ipv4" {
  for_each = merge(local.lans_untrusted, local.lans_reservation)

  name       = "Allow traffic from ${each.value.name} to self"
  action     = "accept"
  ruleset    = "LAN_IN"
  protocol   = "all"
  rule_index = 21100 + each.value.id

  src_firewall_group_ids = [unifi_firewall_group.lan_ipv4[each.key].id]
  dst_firewall_group_ids = [unifi_firewall_group.lan_ipv4[each.key].id]
}

resource "unifi_firewall_rule" "allow_self_ipv6" {
  for_each = merge(local.lans_untrusted, local.lans_reservation)

  name        = "Allow traffic from ${each.value.name} to self"
  action      = "accept"
  ruleset     = "LANv6_IN"
  protocol_v6 = "all"
  rule_index  = 26100 + each.value.id

  src_firewall_group_ids = [unifi_firewall_group.lan_ipv6[each.key].id]
  dst_firewall_group_ids = [unifi_firewall_group.lan_ipv6[each.key].id]
}

resource "unifi_firewall_rule" "allow_traffic_ipv4" {
  for_each = merge(local.default_lan, local.lans_trusted)

  name       = "Allow traffic from ${each.value.name}"
  action     = "accept"
  ruleset    = "LAN_IN"
  protocol   = "all"
  rule_index = 21500 + each.value.id

  src_firewall_group_ids = [unifi_firewall_group.lan_ipv4[each.key].id]
}

resource "unifi_firewall_rule" "allow_traffic_ipv6" {
  for_each = merge(local.default_lan, local.lans_trusted)

  name        = "Allow traffic from ${each.value.name}"
  action      = "accept"
  ruleset     = "LANv6_IN"
  protocol_v6 = "all"
  rule_index  = 26500 + each.value.id

  src_firewall_group_ids = [unifi_firewall_group.lan_ipv6[each.key].id]
}

resource "unifi_firewall_rule" "allow_traffic_exception_ipv4" {
  for_each = { for k, v in var.firewall_exceptions : k => v if v.ipv4 != null }

  name       = "Allow traffic to ${each.value.name}"
  action     = "accept"
  ruleset    = "LAN_IN"
  protocol   = "all"
  rule_index = 22000 + each.value.id

  src_firewall_group_ids = [unifi_firewall_group.lan_ipv4_all.id]
  dst_firewall_group_ids = [unifi_firewall_group.lan_ipv4_exceptions[each.key].id]
}

resource "unifi_firewall_rule" "allow_traffic_exception_ipv6" {
  for_each = { for k, v in var.firewall_exceptions : k => v if v.ipv6 != null }

  name        = "Allow traffic to ${each.value.name}"
  action      = "accept"
  ruleset     = "LANv6_IN"
  protocol_v6 = "all"
  rule_index  = 27000 + each.value.id

  src_firewall_group_ids = [unifi_firewall_group.lan_ipv6_all.id]
  dst_firewall_group_ids = [unifi_firewall_group.lan_ipv6_exceptions[each.key].id]
}

locals {
  vlan_allow_ingress = flatten([
    for k1, v in local.lans_all : [
      for idx, k2 in (lookup(v, "allow_ingress", null) != null ? v.allow_ingress : []) : {
        key      = "${k1}-${k2}"
        id       = idx
        to_net   = merge(local.lans_all[k1], { key = k1 })
        from_net = merge(local.lans_all[k2], { key = k2 })
      }
    ]
  ])
}

resource "unifi_firewall_rule" "allow_traffic_ingress_ipv4" {
  for_each = tomap({ for v in local.vlan_allow_ingress : v.key => v })

  name       = "Allow ingress to ${each.value.to_net.name} from ${each.value.from_net.name}"
  action     = "accept"
  ruleset    = "LAN_IN"
  protocol   = "all"
  rule_index = 22500 + (each.value.to_net.id * 10) + each.value.id

  src_firewall_group_ids = [unifi_firewall_group.lan_ipv4[each.value.from_net.key].id]
  dst_firewall_group_ids = [unifi_firewall_group.lan_ipv4[each.value.to_net.key].id]
}

resource "unifi_firewall_rule" "allow_traffic_ingress_ipv6" {
  for_each = tomap({ for v in local.vlan_allow_ingress : v.key => v })

  name        = "Allow ingress to ${each.value.to_net.name} from ${each.value.from_net.name}"
  action      = "accept"
  ruleset     = "LANv6_IN"
  protocol_v6 = "all"
  rule_index  = 27500 + (each.value.to_net.id * 10) + each.value.id

  src_firewall_group_ids = [unifi_firewall_group.lan_ipv6[each.value.from_net.key].id]
  dst_firewall_group_ids = [unifi_firewall_group.lan_ipv6[each.value.to_net.key].id]
}

resource "unifi_firewall_rule" "deny_default_ipv4" {
  name       = "Deny default"
  action     = "drop"
  ruleset    = "LAN_IN"
  protocol   = "all"
  rule_index = 24999

  dst_firewall_group_ids = [unifi_firewall_group.lan_ipv4_all.id]
}

resource "unifi_firewall_rule" "deny_default_ipv6" {
  name        = "Deny default"
  action      = "drop"
  ruleset     = "LANv6_IN"
  protocol_v6 = "all"
  rule_index  = 29999

  dst_firewall_group_ids = [unifi_firewall_group.lan_ipv6_all.id]
}
