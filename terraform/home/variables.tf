variable "mikrotik_devices" {
  type = map(object({
    name     = string
    ipv4     = string
    username = string
    password = string
  }))
  default = {
    agg = {
      name     = "mikrotik-agg.home.macro.network"
      ipv4     = "10.0.1.1"
      username = ""
      password = ""
    }
  }
}

variable "truenas_devices" {
  type = map(object({
    name         = string
    ipv4         = string
    ssh_password = string
    apikey       = string
  }))
  default = {
    store01 = {
      name         = "store01.home.macro.network"
      ipv4         = "10.0.2.1"
      ssh_password = ""
      apikey       = ""
    }
  }
}

variable "doppler_token" {
  type      = string
  sensitive = true
}
