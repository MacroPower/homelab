variable "nas01_fqdn" {
  type = string
}

variable "nas01_ipv4" {
  type = string
}

variable "nas01_api_key" {
  type = string
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
