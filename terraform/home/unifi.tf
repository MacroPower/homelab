
locals {
  unifi_extra_device_types = {
    storage_management = {
      profile = "lab_management"
    }
    k8s_node_management = {
      profile = "lab_management"
    }
    truenas = {
      profile = "lab"
    }
    unraid = {
      profile = "lab"
    }
    turing_pi = {
      profile = "lab"
    }
    k8s_node_rpi = {
      profile = "lab"
      dev_id  = module.unifi_common.device_types.rpi.dev_id
    }
    k8s_node_supermicro = {
      profile = "lab"
    }
    wattbox = {
      profile = "iot"
    }
    hue_bridge = {
      profile = "iot"
    }
    mixer = {
      profile = "iot"
    }
    mac_mini = {
      profile = "main"
    }
    nanoleaf = {
      profile = "iot"
    }
  }
}

module "unifi_device_types" {
  source  = "cloudposse/config/yaml//modules/deepmerge"
  version = "0.2.0"
  maps = [
    module.unifi_common.device_types,
    local.unifi_extra_device_types,
  ]
}

locals {
  unifi_device_types = module.unifi_device_types.merged

  unifi_clients = {
    "nas01mgmt" = {
      mac     = "7c:c2:55:19:41:d2"
      ipv4    = "10.9.1.1"
      profile = local.unifi_device_types.storage_management.profile
    }
    "nas01" = {
      mac    = "00:07:43:74:34:20"
      ipv4   = "10.10.1.1"
      dev_id = local.unifi_device_types.truenas.dev_id
    }
    "nas01net" = {
      mac     = "00:07:43:74:34:27"
      profile = local.unifi_device_types.truenas.profile
      dev_id  = local.unifi_device_types.truenas.dev_id
    }
    "unraid" = {
      mac     = "00:02:c9:56:81:64"
      ipv4    = "10.10.0.10"
      profile = local.unifi_device_types.unraid.profile
      dev_id  = local.unifi_device_types.unraid.dev_id
    }
    "turingpi01" = {
      mac     = "02:00:b0:42:35:57"
      ipv4    = "10.10.100.1"
      profile = local.unifi_device_types.turing_pi.profile
    }
    "turingpi02" = {
      mac     = "02:00:0d:ac:31:ea"
      ipv4    = "10.10.100.2"
      profile = local.unifi_device_types.turing_pi.profile
    }
    "turingpi03" = {
      mac     = "02:00:af:86:75:87"
      ipv4    = "10.10.100.3"
      profile = local.unifi_device_types.turing_pi.profile
    }
    "knode13mgmt" = {
      mac     = "3c:ec:ef:cd:f6:de"
      ipv4    = "10.9.10.13"
      profile = local.unifi_device_types.k8s_node_management.profile
    }
    "knode14mgmt" = {
      mac     = "3c:ec:ef:cd:f7:a6"
      ipv4    = "10.9.10.14"
      profile = local.unifi_device_types.k8s_node_management.profile
    }
    "knode15mgmt" = {
      mac     = "3c:ec:ef:cd:f7:a7"
      ipv4    = "10.9.10.15"
      profile = local.unifi_device_types.k8s_node_management.profile
    }
    "kube" = {
      mac  = "00:00:10:10:20:01"
      ipv4 = "10.10.20.1"
    }
    "knode01" = {
      mac     = "e4:5f:01:6e:db:a8"
      ipv4    = "10.10.10.1"
      profile = local.unifi_device_types.k8s_node_rpi.profile
      dev_id  = local.unifi_device_types.k8s_node_rpi.dev_id
    }
    "knode02" = {
      mac     = "e4:5f:01:6e:ce:7e"
      ipv4    = "10.10.10.2"
      profile = local.unifi_device_types.k8s_node_rpi.profile
      dev_id  = local.unifi_device_types.k8s_node_rpi.dev_id
    }
    "knode03" = {
      mac     = "e4:5f:01:6e:d0:58"
      ipv4    = "10.10.10.3"
      profile = local.unifi_device_types.k8s_node_rpi.profile
      dev_id  = local.unifi_device_types.k8s_node_rpi.dev_id
    }
    "knode13" = {
      mac     = "00:02:c9:56:fe:52"
      ipv4    = "10.10.10.13"
      profile = local.unifi_device_types.k8s_node_supermicro.profile
    }
    "knode14" = {
      mac     = "00:02:c9:56:d1:a4"
      ipv4    = "10.10.10.14"
      profile = local.unifi_device_types.k8s_node_supermicro.profile
    }
    "knode15" = {
      mac     = "00:02:c9:53:0a:86"
      ipv4    = "10.10.10.15"
      profile = local.unifi_device_types.k8s_node_supermicro.profile
    }
    "wattbox0101" = {
      mac     = "14:3f:c3:03:62:5d"
      profile = local.unifi_device_types.wattbox.profile
      dev_id  = local.unifi_device_types.wattbox.dev_id
    }
    "wattbox0201" = {
      mac     = "d4:6a:91:cf:a4:7c"
      profile = local.unifi_device_types.wattbox.profile
      dev_id  = local.unifi_device_types.wattbox.dev_id
    }
    "wattbox0202" = {
      mac     = "14:3f:c3:04:50:d0"
      profile = local.unifi_device_types.wattbox.profile
      dev_id  = local.unifi_device_types.wattbox.dev_id
    }
    "huebridge01" = {
      mac     = "00:17:88:77:3e:3c"
      profile = local.unifi_device_types.hue_bridge.profile
      dev_id  = local.unifi_device_types.hue_bridge.dev_id
    }
    "motu828es" = {
      mac     = "00:01:f2:00:d1:63"
      profile = local.unifi_device_types.mixer.profile
    }
    "macmini" = {
      mac     = "5c:e9:1e:ea:15:e7"
      profile = local.unifi_device_types.mac_mini.profile
    }
    "echospot" = {
      mac    = "00:71:47:c5:03:02"
      dev_id = local.unifi_device_types.echo_spot.dev_id
    }
    "iphone" = {
      mac    = "24:d0:df:6c:05:ca"
      dev_id = local.unifi_device_types.iphone_se.dev_id
    }
    "nanoleaf" = {
      mac    = "00:55:da:52:5c:55"
      dev_id = local.unifi_device_types.nanoleaf.dev_id
    }
  }

  unifi_networks = {
    main = {
      name          = "Main"
      id            = 1
      type          = "unrestricted"
      wifi          = true
      multicast_dns = true
      dns = [
        "10.10.30.1",
        "10.1.0.1",
      ]
      dns_v6 = [
        "2603:6010:5300:ad01::10:1",
        "2603:6010:5300:ad0b::1",
      ]
    }
    guest = {
      name          = "Guest"
      id            = 2
      purpose       = "guest"
      multicast_dns = true
    }
    wfh = {
      name = "WFH"
      id   = 3
      wifi = true
    }
    vpn = {
      name         = "VPN"
      id           = 4
      wifi         = true
      disable_ipv6 = true
    }
    lab_management = {
      name = "Lab Management"
      id   = 9
    }
    lab = {
      name = "Lab"
      id   = 10
    }
    iot = {
      name          = "IoT"
      id            = 20
      wifi          = true
      wifi_profile  = "compatability"
      multicast_dns = true
    }
    k8s_services = {
      name = "home Services"
      id   = 112
      mask = 12
      type = "reservation"
    }
    k8s_pods = {
      name = "home Pods"
      id   = 128
      mask = 14
      type = "reservation"
    }
    nas01_services = {
      name = "nas01 Services"
      id   = 132
      mask = 16
      type = "reservation"
    }
    nas01_pods = {
      name = "nas01 Pods"
      id   = 133
      mask = 16
      type = "reservation"
    }
    nas02_services = {
      name = "nas02 Services"
      id   = 134
      mask = 16
      type = "reservation"
    }
    nas02_pods = {
      name = "nas02 Pods"
      id   = 135
      mask = 16
      type = "reservation"
    }
  }
}

module "unifi_common" {
  source = "../modules/unifi-common"
}

module "unifi" {
  source = "../modules/unifi"

  domain_name = var.domain_name
  site_code   = "H"

  clients  = local.unifi_clients
  networks = local.unifi_networks
}

resource "unifi_device" "agg0101" {
  name = "USW-Pro-Aggregation"

  forget_on_destroy = false

  port_override {
    number          = 13
    name            = "SFP+ 13"
    port_profile_id = module.unifi.port_profile[local.unifi_clients.knode13.profile].id
  }
  port_override {
    number          = 14
    name            = "SFP+ 14"
    port_profile_id = module.unifi.port_profile[local.unifi_clients.knode14.profile].id
  }
  port_override {
    number          = 15
    name            = "SFP+ 15"
    port_profile_id = module.unifi.port_profile[local.unifi_clients.knode15.profile].id
  }
  port_override {
    number          = 21
    name            = "SFP+ 21"
    port_profile_id = module.unifi.port_profile[local.unifi_clients.unraid.profile].id
  }
  port_override {
    number          = 22
    name            = "SFP+ 22"
    port_profile_id = module.unifi.port_profile[local.unifi_clients.nas01net.profile].id
  }

  port_override {
    number              = 25
    name                = "SFP+ 25"
    op_mode             = "aggregate"
    aggregate_num_ports = 2
    native_network_id   = module.unifi.default_network_id
  }
}

resource "unifi_device" "sw0101" {
  name = "USW-Pro-24-PoE"

  forget_on_destroy = false

  port_override {
    number          = 1
    name            = "Port 1"
    port_profile_id = module.unifi.port_profile[local.unifi_clients.knode01.profile].id
  }
  port_override {
    number          = 2
    name            = "Port 2"
    port_profile_id = module.unifi.port_profile[local.unifi_clients.knode02.profile].id
  }
  port_override {
    number          = 3
    name            = "Port 3"
    port_profile_id = module.unifi.port_profile[local.unifi_clients.knode03.profile].id
  }
  port_override {
    number          = 4
    name            = "Port 4"
    port_profile_id = module.unifi.port_profile[local.unifi_clients.knode13mgmt.profile].id
  }
  port_override {
    number          = 5
    name            = "Port 5"
    port_profile_id = module.unifi.port_profile[local.unifi_clients.knode14mgmt.profile].id
  }
  port_override {
    number          = 6
    name            = "Port 6"
    port_profile_id = module.unifi.port_profile[local.unifi_clients.knode15mgmt.profile].id
  }
  port_override {
    number          = 9
    name            = "Port 9"
    port_profile_id = module.unifi.port_profile[local.unifi_clients.wattbox0101.profile].id
  }
  port_override {
    number          = 12
    name            = "Port 12"
    port_profile_id = module.unifi.port_profile[local.unifi_clients.nas01mgmt.profile].id
  }

  port_override {
    number              = 25
    name                = "SFP+ 1"
    op_mode             = "aggregate"
    aggregate_num_ports = 2
    native_network_id   = module.unifi.default_network_id
  }
}

resource "unifi_device" "sw0201" {
  name = "USW-Pro-24"

  forget_on_destroy = false

  port_override {
    number          = 1
    name            = "Port 1"
    port_profile_id = module.unifi.port_profile[local.unifi_clients.macmini.profile].id
  }
  port_override {
    number          = 7
    name            = "Port 7"
    port_profile_id = module.unifi.port_profile[local.unifi_clients.motu828es.profile].id
  }
  port_override {
    number          = 15
    name            = "Port 15"
    port_profile_id = module.unifi.port_profile[local.unifi_clients.wattbox0202.profile].id
  }
  port_override {
    number          = 16
    name            = "Port 16"
    port_profile_id = module.unifi.port_profile[local.unifi_clients.wattbox0201.profile].id
  }
  port_override {
    number          = 18
    name            = "Port 18"
    port_profile_id = module.unifi.port_profile[local.unifi_clients.huebridge01.profile].id
  }
}
