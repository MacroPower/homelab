variable "domain_name" {
  type = string
}

variable "site_code" {
  type = string
  validation {
    condition     = can(regex("^[A-Z]$", var.site_code))
    error_message = "Site code must be a single uppercase character"
  }
}

variable "clients" {
  type = map(object({
    mac     = string
    ipv4    = optional(string)
    profile = optional(string)
    dev_id  = optional(number)
  }))
}

variable "networks" {
  type = map(object({
    name          = string
    id            = number
    type          = optional(string) // null (restricted) or "unrestricted" or "reservation"
    mask          = optional(number) // null (16) or 8-30
    purpose       = optional(string) // null (corperate) or "guest"
    wifi          = optional(bool)   // null (false) or true
    multicast_dns = optional(bool)   // null (false) or true
  }))
}

variable "default_network_id" {
  type    = number
  default = 0
}
