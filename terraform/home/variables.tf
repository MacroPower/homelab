variable "truenas_devices" {
  type = map(object({
    name         = string
    ipv4         = string
    ssh_password = string
    apikey       = string
  }))
  sensitive = true
}

variable "unifi_sites" {
  type = map(object({
    username    = string
    password    = string
    api_url     = string
    site        = string
    domain_name = string
  }))
  sensitive = true
}

variable "doppler_token" {
  type      = string
  sensitive = true
}
