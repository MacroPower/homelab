variable "mikrotik_devices" {
  type = map(object({
    name     = string
    ipv4     = string
    username = string
    password = string
  }))
  sensitive = true
}

variable "truenas_devices" {
  type = map(object({
    name         = string
    ipv4         = string
    ssh_password = string
    apikey       = string
  }))
  sensitive = true
}

variable "doppler_token" {
  type      = string
  sensitive = true
}
