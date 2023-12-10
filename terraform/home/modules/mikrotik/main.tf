resource "routeros_system_logging" "log_remote" {
  action = "remote"
  prefix = "${var.name}:"
  topics = ["bgp", "info", "error", "warning", "critical"]
}

resource "routeros_system_logging" "log_memory" {
  action = "memory"
  topics = ["bgp"]
}

resource "routeros_interface_bridge" "bridge" {
  name           = "bridge"
  auto_mac       = false
  vlan_filtering = false
  comment        = "defconf"
}

resource "routeros_interface_bridge_settings" "settings" {
  use_ip_firewall = false
}
