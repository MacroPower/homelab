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
