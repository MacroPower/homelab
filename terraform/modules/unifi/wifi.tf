locals {
  wifi_prefix = "UNIFI-W${var.site_code}"

  wifi_nets = {
    for k, v in merge(local.lans, local.lans_unrestricted) : k => v
    if v.wifi == true
  }
}

data "unifi_ap_group" "default" {
  name = "All APs"
}

data "unifi_user_group" "default" {
  name = "Default"
}

resource "random_password" "default_password" {
  length = 16
}

resource "unifi_wlan" "wlan" {
  for_each = local.wifi_nets

  name       = length(local.wifi_nets) > 1 ? "${local.wifi_prefix}-${each.value.name}" : local.wifi_prefix
  passphrase = random_password.default_password.result
  security   = "wpapsk"

  network_id    = unifi_network.lan[each.key].id
  ap_group_ids  = [data.unifi_ap_group.default.id]
  user_group_id = data.unifi_user_group.default.id

  uapsd             = each.value.wifi_profile != "compatability"
  pmf_mode          = each.value.wifi_profile != "compatability" ? "optional" : "disabled"
  wlan_band         = each.value.wifi_profile != "compatability" ? "5g" : "both"
  multicast_enhance = true

  lifecycle {
    ignore_changes = [passphrase]
  }
}

resource "unifi_wlan" "wlan_guest" {
  name       = "${local.wifi_prefix}-Guest"
  passphrase = random_password.default_password.result
  security   = "wpapsk"

  l2_isolation = true

  network_id    = unifi_network.lan["guest"].id
  ap_group_ids  = [data.unifi_ap_group.default.id]
  user_group_id = data.unifi_user_group.default.id

  uapsd             = var.networks["guest"].wifi_profile != "compatability"
  pmf_mode          = var.networks["guest"].wifi_profile != "compatability" ? "optional" : "disabled"
  wlan_band         = var.networks["guest"].wifi_profile != "compatability" ? "5g" : "both"
  multicast_enhance = true

  lifecycle {
    ignore_changes = [passphrase]
  }
}
