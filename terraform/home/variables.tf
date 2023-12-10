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
