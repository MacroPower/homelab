output "port_profile" {
  value = {
    for k, v in unifi_port_profile.lan : k => {
      id = v.id
    }
  }
}

output "default_network_id" {
  value = unifi_network.lan_default.id
}
