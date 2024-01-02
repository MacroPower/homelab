variable "truenas_devices" {
  type = map(object({
    fqdn         = string
    ipv4         = string
    ssh_password = string
    apikey       = string
  }))
  sensitive = true
}

variable "domain_name" {
  type = string
}

variable "unifi_username" {
  type = string
}

variable "unifi_password" {
  type      = string
  sensitive = true
}

variable "unifi_api_url" {
  type = string
}

variable "unifi_site" {
  type = string
}

variable "doppler_token" {
  type      = string
  sensitive = true
}
