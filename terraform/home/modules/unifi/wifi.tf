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
  for_each = {
    for k, v in merge(local.lans, local.lans_unrestricted) : k => v
    if lookup(v, "wifi", false)
  }

  name       = "UNIFI-WH-${each.value.name}"
  passphrase = random_password.default_password.result
  security   = "wpapsk"

  network_id    = unifi_network.lan[each.key].id
  ap_group_ids  = [data.unifi_ap_group.default.id]
  user_group_id = data.unifi_user_group.default.id

  lifecycle {
    ignore_changes = [passphrase]
  }
}

resource "unifi_wlan" "wlan_guest" {
  name       = "UNIFI-WH-Guest"
  passphrase = random_password.default_password.result
  security   = "wpapsk"

  l2_isolation = true

  network_id    = unifi_network.lan["guest"].id
  ap_group_ids  = [data.unifi_ap_group.default.id]
  user_group_id = data.unifi_user_group.default.id

  lifecycle {
    ignore_changes = [passphrase]
  }
}
