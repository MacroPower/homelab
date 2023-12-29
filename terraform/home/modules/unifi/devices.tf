resource "unifi_device" "usw_pro_aggregation" {
  name = "USW-Pro-Aggregation"

  forget_on_destroy = false

  port_override {
    number          = 13
    name            = "SFP+ 13"
    port_profile_id = local.clients.knode15.profile
  }
  port_override {
    number          = 14
    name            = "SFP+ 14"
    port_profile_id = local.clients.knode14.profile
  }
  port_override {
    number          = 15
    name            = "SFP+ 15"
    port_profile_id = local.clients.knode13.profile
  }
  port_override {
    number          = 21
    name            = "SFP+ 21"
    port_profile_id = local.clients.unraid.profile
  }
  port_override {
    number          = 22
    name            = "SFP+ 22"
    port_profile_id = local.clients.store01.profile
  }

  port_override {
    number              = 25
    name                = "SFP+ 25"
    op_mode             = "aggregate"
    aggregate_num_ports = 2
    native_network_id   = unifi_network.lan_default.id
  }
}

resource "unifi_device" "usw_pro_24_poe" {
  name = "USW-Pro-24-PoE"

  forget_on_destroy = false

  port_override {
    number          = 1
    name            = "Port 1"
    port_profile_id = local.clients.knode01.profile
  }
  port_override {
    number          = 2
    name            = "Port 2"
    port_profile_id = local.clients.knode02.profile
  }
  port_override {
    number          = 3
    name            = "Port 3"
    port_profile_id = local.clients.knode03.profile
  }
  port_override {
    number          = 4
    name            = "Port 4"
    port_profile_id = local.clients.knode13mgmt.profile
  }
  port_override {
    number          = 5
    name            = "Port 5"
    port_profile_id = local.clients.knode14mgmt.profile
  }
  port_override {
    number          = 6
    name            = "Port 6"
    port_profile_id = local.clients.knode15mgmt.profile
  }
  port_override {
    number          = 9
    name            = "Port 9"
    port_profile_id = local.clients.wattbox0101.profile
  }

  port_override {
    number              = 25
    name                = "SFP+ 1"
    op_mode             = "aggregate"
    aggregate_num_ports = 2
    native_network_id   = unifi_network.lan_default.id
  }
}

resource "unifi_device" "usw_pro_24" {
  name = "USW-Pro-24"

  forget_on_destroy = false

  port_override {
    number          = 1
    name            = "Port 1"
    port_profile_id = local.clients.macmini.profile
  }
  port_override {
    number          = 7
    name            = "Port 7"
    port_profile_id = local.clients.motu828es.profile
  }
  port_override {
    number          = 17
    name            = "Port 17"
    port_profile_id = local.clients.wattbox0201.profile
  }
  port_override {
    number          = 18
    name            = "Port 18"
    port_profile_id = local.clients.huebridge01.profile
  }
}
