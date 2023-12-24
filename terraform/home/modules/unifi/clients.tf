locals {
  device_types = {
    storage_management = {
      profile = unifi_port_profile.lan["lab_management"].id
    }
    k8s_node_management = {
      profile = unifi_port_profile.lan["lab_management"].id
    }
    truenas = {
      profile = unifi_port_profile.lan["lab"].id
      dev_id  = 4995
    }
    unraid = {
      profile = unifi_port_profile.lan["lab"].id
      dev_id  = 5126
    }
    turing_pi = {
      # TODO: Move to management vlan once supported on tpi
      profile = unifi_port_profile.lan["lab"].id
    }
    k8s_node_rpi = {
      profile = unifi_port_profile.lan["lab"].id
      dev_id  = 4134
    }
    k8s_node_supermicro = {
      profile = unifi_port_profile.lan["lab"].id
    }
    wattbox = {
      profile = unifi_port_profile.lan["iot"].id
      dev_id  = 2838
    }
    hue_bridge = {
      profile = unifi_port_profile.lan["iot"].id
    }
    mixer = {
      profile = unifi_port_profile.lan["iot"].id
    }
  }

  clients = {
    "store01mgmt" = {
      mac     = "7c:c2:55:19:41:d2"
      ipv4    = "10.9.0.1"
      profile = local.device_types.storage_management.profile
    }
    "store01" = {
      mac     = "00:07:43:74:34:20"
      ipv4    = "10.10.0.1"
      profile = local.device_types.truenas.profile
      dev_id  = local.device_types.truenas.dev_id
    }
    "unraid" = {
      mac     = "00:02:c9:56:81:64"
      ipv4    = "10.10.0.10"
      profile = local.device_types.unraid.profile
      dev_id  = local.device_types.unraid.dev_id
    }
    "turingpi01" = {
      mac     = "02:00:b0:42:35:57"
      ipv4    = "10.10.100.1"
      profile = local.device_types.turing_pi.profile
    }
    "turingpi02" = {
      mac     = "02:00:0d:ac:31:ea"
      ipv4    = "10.10.100.2"
      profile = local.device_types.turing_pi.profile
    }
    "turingpi03" = {
      mac     = "02:00:af:86:75:87"
      ipv4    = "10.10.100.3"
      profile = local.device_types.turing_pi.profile
    }
    "knode13mgmt" = {
      mac     = "3c:ec:ef:cd:f6:de"
      ipv4    = "10.9.10.13"
      profile = local.device_types.k8s_node_management.profile
    }
    "knode14mgmt" = {
      mac     = "3c:ec:ef:cd:f7:a6"
      ipv4    = "10.9.10.14"
      profile = local.device_types.k8s_node_management.profile
    }
    "knode15mgmt" = {
      mac     = "3c:ec:ef:cd:f7:a7"
      ipv4    = "10.9.10.15"
      profile = local.device_types.k8s_node_management.profile
    }
    "knode01" = {
      mac     = "e4:5f:01:6e:db:a8"
      ipv4    = "10.10.10.1"
      profile = local.device_types.k8s_node_rpi.profile
      dev_id  = local.device_types.k8s_node_rpi.dev_id
    }
    "knode02" = {
      mac     = "e4:5f:01:6e:ce:7e"
      ipv4    = "10.10.10.2"
      profile = local.device_types.k8s_node_rpi.profile
      dev_id  = local.device_types.k8s_node_rpi.dev_id
    }
    "knode03" = {
      mac     = "e4:5f:01:6e:d0:58"
      ipv4    = "10.10.10.3"
      profile = local.device_types.k8s_node_rpi.profile
      dev_id  = local.device_types.k8s_node_rpi.dev_id
    }
    "knode13" = {
      mac     = "00:02:c9:56:fe:52"
      ipv4    = "10.10.10.13"
      profile = local.device_types.k8s_node_supermicro.profile
    }
    "knode14" = {
      mac     = "00:02:c9:56:d1:a4"
      ipv4    = "10.10.10.14"
      profile = local.device_types.k8s_node_supermicro.profile
    }
    "knode15" = {
      mac     = "00:02:c9:53:0a:86"
      ipv4    = "10.10.10.15"
      profile = local.device_types.k8s_node_supermicro.profile
    }
    "wattbox0101" = {
      mac     = "14:3f:c3:03:62:5d"
      profile = local.device_types.wattbox.profile
      dev_id  = local.device_types.wattbox.dev_id
    }
    "wattbox0201" = {
      mac     = "d4:6a:91:cf:a4:7c"
      profile = local.device_types.wattbox.profile
      dev_id  = local.device_types.wattbox.dev_id
    }
    "huebridge01" = {
      mac     = "00:17:88:77:3e:3c"
      profile = local.device_types.hue_bridge.profile
    }
    "motu828es" = {
      mac     = "00:01:f2:00:d1:63"
      profile = local.device_types.mixer.profile
    }
  }
}

resource "unifi_user" "clients" {
  for_each = local.clients

  mac  = each.value.mac
  name = each.key
  note = "Managed by Terraform"

  fixed_ip         = lookup(each.value, "ipv4", null)
  network_id       = lookup(each.value, "vlan", null)
  local_dns_record = lookup(each.value, "ipv4", null) != null ? format("%s.%s", each.key, var.domain_name) : null
  dev_id_override  = lookup(each.value, "dev_id", null)
}
