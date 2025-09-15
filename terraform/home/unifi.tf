
locals {
  unifi_extra_device_types = {
    storage_management = {
      profile = "lab_management"
    }
    k8s_node_management = {
      profile = "lab_management"
    }
    home_assistant = {
      profile = "lab"
      dev_id  = module.unifi_common.device_types.rpi.dev_id
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
    k8s_node_rk1 = {
      profile = "lab"
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
    desktop = {
      profile = "main"
    }
    nanoleaf = {
      profile = "iot"
    }
  }
}

module "unifi_device_types" {
  source  = "cloudposse/config/yaml//modules/deepmerge"
  version = "1.0.2"
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
    "nas01i" = {
      mac     = "7c:c2:55:26:0e:56"
      ipv4    = "10.9.2.1"
      profile = local.unifi_device_types.storage_management.profile
      dev_id  = local.unifi_device_types.truenas.dev_id
    }
    "nas01" = {
      mac     = "00:07:43:74:34:20"
      ipv4    = "10.10.1.1"
      profile = local.unifi_device_types.truenas.profile
      dev_id  = local.unifi_device_types.truenas.dev_id
    }
    "nas01net01" = {
      mac     = "00:07:43:74:34:2f"
      profile = local.unifi_device_types.truenas.profile
      dev_id  = local.unifi_device_types.truenas.dev_id
    }
    "nas01net02" = {
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
    "kmain07mgmt" = {
      mac     = "3c:ec:ef:cd:f6:de"
      ipv4    = "10.9.10.13"
      profile = local.unifi_device_types.k8s_node_management.profile
    }
    "kmain08mgmt" = {
      mac     = "3c:ec:ef:cd:f7:a6"
      ipv4    = "10.9.10.14"
      profile = local.unifi_device_types.k8s_node_management.profile
    }
    "kmain09mgmt" = {
      mac     = "3c:ec:ef:cd:f7:a7"
      ipv4    = "10.9.10.15"
      profile = local.unifi_device_types.k8s_node_management.profile
    }
    "kmgmt01" = {
      desc    = "Node 1-4 (Control Plane)"
      mac     = "e4:5f:01:6e:db:a8"
      ipv4    = "10.10.8.1"
      profile = local.unifi_device_types.k8s_node_rpi.profile
      dev_id  = local.unifi_device_types.k8s_node_rpi.dev_id
    }
    "kmgmt02" = {
      desc    = "Node 2-4 (Control Plane)"
      mac     = "e4:5f:01:6e:ce:7e"
      ipv4    = "10.10.8.2"
      profile = local.unifi_device_types.k8s_node_rpi.profile
      dev_id  = local.unifi_device_types.k8s_node_rpi.dev_id
    }
    "kmgmt03" = {
      desc    = "Node 3-4 (Control Plane)"
      mac     = "e4:5f:01:6e:d0:58"
      ipv4    = "10.10.8.3"
      profile = local.unifi_device_types.k8s_node_rpi.profile
      dev_id  = local.unifi_device_types.k8s_node_rpi.dev_id
    }
    "kmgmt04" = {
      desc    = "Node 1-3"
      mac     = "7a:c0:a9:f4:7d:47"
      ipv4    = "10.10.8.4"
      profile = local.unifi_device_types.k8s_node_rk1.profile
    }
    "kmgmt05" = {
      desc    = "Node 2-3"
      mac     = "de:9a:68:e8:7e:24"
      ipv4    = "10.10.8.5"
      profile = local.unifi_device_types.k8s_node_rk1.profile
    }
    "kmgmt06" = {
      desc    = "Node 3-3"
      mac     = "5a:04:d1:f7:7f:32"
      ipv4    = "10.10.8.6"
      profile = local.unifi_device_types.k8s_node_rk1.profile
    }
    "kmain01" = {
      desc    = "Node 1-1 (Control Plane)"
      mac     = "6e:e2:c7:35:3e:65"
      ipv4    = "10.10.10.1"
      profile = local.unifi_device_types.k8s_node_rk1.profile
    }
    "kmain02" = {
      desc    = "Node 2-1 (Control Plane)"
      mac     = "56:13:8a:32:ff:96"
      ipv4    = "10.10.10.2"
      profile = local.unifi_device_types.k8s_node_rk1.profile
    }
    "kmain03" = {
      desc    = "Node 3-1 (Control Plane)"
      mac     = "ee:2f:d9:80:0f:c2"
      ipv4    = "10.10.10.3"
      profile = local.unifi_device_types.k8s_node_rk1.profile
    }
    "kmain04" = {
      desc    = "Node 1-2"
      mac     = "fe:c2:a6:93:6e:8a"
      ipv4    = "10.10.10.4"
      profile = local.unifi_device_types.k8s_node_rk1.profile
    }
    "kmain05" = {
      desc    = "Node 2-2"
      mac     = "16:55:cd:bc:cc:83"
      ipv4    = "10.10.10.5"
      profile = local.unifi_device_types.k8s_node_rk1.profile
    }
    "kmain06" = {
      desc    = "Node 3-2"
      mac     = "fa:fa:0b:10:5e:18"
      ipv4    = "10.10.10.6"
      profile = local.unifi_device_types.k8s_node_rk1.profile
    }
    "kmain07" = {
      desc    = "Node 5-1"
      mac     = "00:02:c9:56:fe:52"
      ipv4    = "10.10.10.7"
      profile = local.unifi_device_types.k8s_node_supermicro.profile
    }
    "kmain08" = {
      desc    = "Node 5-2"
      mac     = "00:02:c9:56:d1:a4"
      ipv4    = "10.10.10.8"
      profile = local.unifi_device_types.k8s_node_supermicro.profile
    }
    "kmain09" = {
      desc    = "Node 5-3"
      mac     = "00:02:c9:53:0a:86"
      ipv4    = "10.10.10.9"
      profile = local.unifi_device_types.k8s_node_supermicro.profile
    }
    "knas01" = {
      desc    = "TrueNAS Container 1"
      mac     = "e4:dd:9a:b9:42:89"
      ipv4    = "10.10.12.1"
      profile = local.unifi_device_types.truenas.profile
    }
    "hass" = {
      desc    = "Home Assistant"
      mac     = "d8:3a:dd:ba:e3:3b"
      ipv4    = "10.10.0.20"
      profile = local.unifi_device_types.home_assistant.profile
      dev_id  = local.unifi_device_types.home_assistant.dev_id
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
    "huebridge0101" = {
      mac     = "00:17:88:77:3e:3c"
      ipv4    = "10.20.0.100"
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
    "desktop" = {
      mac     = "a8:a1:59:f6:ca:d2"
      profile = local.unifi_device_types.desktop.profile
    }
    "echospot" = {
      mac    = "00:71:47:c5:03:02"
      dev_id = local.unifi_device_types.echo_spot.dev_id
    }
    "iphone" = {
      mac    = "24:d0:df:6c:05:ca"
      dev_id = local.unifi_device_types.iphone_se.dev_id
    }
    "nanoleaf0101" = {
      mac    = "00:55:da:52:5c:55"
      ipv4   = "10.20.0.110"
      dev_id = local.unifi_device_types.nanoleaf.dev_id
    }
  }

  unifi_networks = {
    main = {
      name          = "Main"
      id            = 1
      type          = "trusted"
      wifi          = true
      multicast_dns = true
      dns = [
        "10.10.40.20",
        "10.1.0.1",
      ]
      dns_v6 = [
        "::ffff:a0a:2814",
        "::ffff:a01:1",
      ]
    }
    guest = {
      name          = "Guest"
      id            = 2
      purpose       = "guest"
      type          = "isolated"
      multicast_dns = true
    }
    wfh = {
      name = "WFH"
      id   = 3
      type = "isolated"
      wifi = true
    }
    vpn = {
      name         = "VPN"
      id           = 4
      type         = "isolated"
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
      type = "trusted"
      allow_ingress = [
        "lab_management",
      ]
    }
    iot = {
      name          = "IoT"
      id            = 20
      wifi          = true
      wifi_profile  = "compatability"
      multicast_dns = true
      allow_ingress = [
        "lab",
      ]
    }
    k8s_seedbox_services = {
      name = "seedbox Services"
      id   = 43
      mask = 16
      type = "remote"
      allow_ingress = [
        "lab",
      ]
    }
    kmgmt_services = {
      name            = "kmgmt Services"
      id              = 110
      mask            = 16
      type            = "isolated"
      disable_ipv6_ra = true
      disable_dhcp    = true
    }
    kmgmt_pods = {
      name = "kmgmt Pods"
      id   = 111
      mask = 16
      type = "reservation"
    }
    kmain_services = {
      name            = "kmain Services"
      id              = 112
      mask            = 12
      type            = "isolated"
      disable_ipv6_ra = true
      disable_dhcp    = true
    }
    kmain_pods = {
      name = "kmain Pods"
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
  ipv6_pd     = "fc42::/56"

  clients  = local.unifi_clients
  networks = local.unifi_networks

  firewall_exceptions = {
    adguard_home = {
      name = "Adguard Home"
      id   = 1
      ipv4 = "10.10.40.20"
    }
    work_things = {
      name = "Work Things"
      id   = 2
      ipv4 = "10.54.32.58"
    }
  }
}

resource "unifi_device" "agg0101" {
  name = "USW-Pro-Aggregation"

  forget_on_destroy = false

  port_override {
    number          = 13
    name            = "SFP+ 13"
    port_profile_id = module.unifi.port_profile[local.unifi_clients.kmain07.profile].id
  }
  port_override {
    number          = 14
    name            = "SFP+ 14"
    port_profile_id = module.unifi.port_profile[local.unifi_clients.kmain08.profile].id
  }
  port_override {
    number          = 15
    name            = "SFP+ 15"
    port_profile_id = module.unifi.port_profile[local.unifi_clients.kmain09.profile].id
  }
  port_override {
    number          = 21
    name            = "SFP+ 21"
    op_mode         = "aggregate"
    port_profile_id = module.unifi.port_profile[local.unifi_clients.nas01.profile].id
  }
  port_override {
    number            = 25
    name              = "SFP+ 25"
    op_mode           = "aggregate"
    native_network_id = module.unifi.default_network_id
  }
  port_override {
    number          = 27
    name            = "SFP+ 27"
    port_profile_id = module.unifi.port_profile[local.unifi_clients.unraid.profile].id
  }
}

resource "unifi_device" "sw0101" {
  name = "USW-Pro-24-PoE"

  forget_on_destroy = false

  port_override {
    number          = 1
    name            = "Port 1"
    port_profile_id = module.unifi.port_profile[local.unifi_clients.kmgmt01.profile].id
  }
  port_override {
    number          = 2
    name            = "Port 2"
    port_profile_id = module.unifi.port_profile[local.unifi_clients.kmgmt02.profile].id
  }
  port_override {
    number          = 3
    name            = "Port 3"
    port_profile_id = module.unifi.port_profile[local.unifi_clients.kmgmt03.profile].id
  }
  port_override {
    number          = 4
    name            = "Port 4"
    port_profile_id = module.unifi.port_profile[local.unifi_clients.kmain07mgmt.profile].id
  }
  port_override {
    number          = 5
    name            = "Port 5"
    port_profile_id = module.unifi.port_profile[local.unifi_clients.kmain08mgmt.profile].id
  }
  port_override {
    number          = 6
    name            = "Port 6"
    port_profile_id = module.unifi.port_profile[local.unifi_clients.kmain09mgmt.profile].id
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
    number          = 14
    name            = "Port 14"
    port_profile_id = module.unifi.port_profile[local.unifi_clients.nas01i.profile].id
  }
  port_override {
    number          = 23
    name            = "Port 23"
    port_profile_id = module.unifi.port_profile[local.unifi_clients.hass.profile].id
  }
  port_override {
    number            = 25
    name              = "SFP+ 1"
    op_mode           = "aggregate"
    native_network_id = module.unifi.default_network_id
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
    number          = 16
    name            = "Port 16"
    port_profile_id = module.unifi.port_profile[local.unifi_clients.wattbox0201.profile].id
  }
  port_override {
    number          = 18
    name            = "Port 18"
    port_profile_id = module.unifi.port_profile[local.unifi_clients.huebridge0101.profile].id
  }
  port_override {
    number          = 21
    name            = "Port 21"
    port_profile_id = module.unifi.port_profile[local.unifi_clients.wattbox0202.profile].id
  }
  port_override {
    number          = 23
    name            = "Port 23"
    port_profile_id = module.unifi.port_profile[local.unifi_clients.desktop.profile].id
  }
}
