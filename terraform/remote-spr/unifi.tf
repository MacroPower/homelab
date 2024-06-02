
locals {
  unifi_extra_device_types = {}
}

module "unifi_device_types" {
  source  = "cloudposse/config/yaml//modules/deepmerge"
  version = "0.8.1"
  maps = [
    module.unifi_common.device_types,
    local.unifi_extra_device_types,
  ]
}

locals {
  unifi_device_types = module.unifi_device_types.merged

  unifi_clients = {
    aqm01 = {
      mac    = "08:91:15:ad:a4:49"
      dev_id = local.unifi_device_types.amazon_aqm.dev_id
    }
    ps4 = {
      mac    = "a4:fc:77:ea:30:19"
      dev_id = local.unifi_device_types.ps4.dev_id
    }
    tv01 = {
      mac = "74:40:be:db:a1:8c"
    }
    tv02 = {
      mac    = "78:80:38:a3:59:75"
      dev_id = local.unifi_device_types.roku.dev_id
    }
    echo01 = {
      mac    = "f0:81:73:f8:a3:b9"
      dev_id = local.unifi_device_types.echo_3rd_gen.dev_id
    }
  }

  unifi_default_network_id = 100
  unifi_networks = {
    main = {
      name          = "Main"
      id            = 101
      type          = "trusted"
      wifi          = true
      wifi_profile  = "compatability"
      multicast_dns = true
    }
    guest = {
      name          = "Guest"
      id            = 102
      purpose       = "guest"
      type          = "isolated"
      wifi_profile  = "compatability"
      multicast_dns = true
    }
    lab_management = {
      name = "Lab Management"
      id   = 109
    }
    lab = {
      name = "Lab"
      id   = 110
    }
  }
}

module "unifi_common" {
  source = "../modules/unifi-common"
}

module "unifi" {
  source = "../modules/unifi"

  domain_name        = var.domain_name
  site_code          = "C"
  ipv6_pd            = "2603:6011:5100:2e"
  ipv6_pd_mask       = 56
  default_network_id = local.unifi_default_network_id

  clients  = local.unifi_clients
  networks = local.unifi_networks
}

resource "unifi_device" "sw01" {
  name = "USW-Lite-8-PoE"

  forget_on_destroy = false

  port_override {
    number            = 1
    name              = "Port 1"
    native_network_id = module.unifi.default_network_id
  }
  port_override {
    number          = 2
    name            = "Port 2"
    port_profile_id = module.unifi.port_profile["disabled"].id
  }
  port_override {
    number          = 3
    name            = "Port 3"
    port_profile_id = module.unifi.port_profile["disabled"].id
  }
  port_override {
    number            = 4
    name              = "Port 4"
    native_network_id = module.unifi.default_network_id
  }
  port_override {
    number            = 5
    name              = "Port 5"
    native_network_id = module.unifi.default_network_id
  }
  port_override {
    number          = 6
    name            = "Port 6"
    port_profile_id = module.unifi.port_profile["disabled"].id
  }
  port_override {
    number          = 7
    name            = "Port 7"
    port_profile_id = module.unifi.port_profile["disabled"].id
  }
  port_override {
    number          = 8
    name            = "Port 8"
    port_profile_id = module.unifi.port_profile["disabled"].id
  }
}

resource "unifi_device" "ap01" {
  name = "U6-LR"

  forget_on_destroy = false

  // 2ghz_channel_width                = 20
  // 2ghz_channel                      = 6
  // 2ghz_tx_power                     = 8
  // 2ghz_min_rssi                     = -67
  // 2ghz_interference_blocker_enabled = false

  // 5ghz_channel_width                = 80
  // 5ghz_channel                      = 36
  // 5ghz_tx_power                     = 26
  // 5ghz_min_rssi                     = -80
  // 5ghz_interference_blocker_enabled = false

  // band_steering = "off"
}

resource "unifi_device" "ap02" {
  name = "U6-Extender-1"

  forget_on_destroy = false

  // 2ghz_channel_width                = 20
  // 2ghz_channel                      = 11
  // 2ghz_tx_power                     = 6
  // 2ghz_min_rssi                     = -67
  // 2ghz_interference_blocker_enabled = false

  // 5ghz_channel_width                = auto
  // 5ghz_channel                      = auto
  // 5ghz_tx_power                     = 18
  // 5ghz_min_rssi                     = -67
  // 5ghz_interference_blocker_enabled = false

  // band_steering = "off"
}

resource "unifi_device" "ap03" {
  name = "U6-Extender-2"

  forget_on_destroy = false

  // 2ghz_channel_width                = 20
  // 2ghz_channel                      = 11
  // 2ghz_tx_power                     = 6
  // 2ghz_min_rssi                     = -67
  // 2ghz_interference_blocker_enabled = false

  // 5ghz_channel_width                = auto
  // 5ghz_channel                      = auto
  // 5ghz_tx_power                     = 18
  // 5ghz_min_rssi                     = -67
  // 5ghz_interference_blocker_enabled = false

  // band_steering = "off"
}
