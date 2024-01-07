output "port_profile" {
  value = {
    for k, v in merge(unifi_port_profile.lan, {disabled = unifi_port_profile.disabled}) : k => {
      id = v.id
    }
  }
}

output "default_network_id" {
  value = unifi_network.lan_default.id
}
