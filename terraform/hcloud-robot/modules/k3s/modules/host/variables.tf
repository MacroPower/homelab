variable "name" {
  description = "Host name"
  type        = string
}

variable "ipv4_address" {
  description = "IPv4 address"
  type        = string
}

variable "network_interface" {
  description = "Network interface"
  type        = string
}

variable "os_device" {
  description = "OS Device"
  type        = string
  default     = "/dev/sda"
}

variable "ssh_port" {
  description = "SSH port"
  type        = number
  default     = 22
}

variable "ssh_public_key" {
  description = "SSH public Key"
  type        = string
}

variable "ssh_private_key" {
  description = "SSH private Key"
  type        = string
  sensitive   = true
}

variable "ssh_additional_public_keys" {
  description = "Additional SSH public Keys. Use them to grant other team members root access to your cluster nodes"
  type        = list(string)
  default     = []
}

variable "packages_to_install" {
  description = "Packages to install"
  type        = list(string)
  default     = []
}

variable "dns_servers" {
  type        = list(string)
  description = "IP Addresses to use for the DNS Servers, set to an empty list to use the ones provided by Hetzner"
}

variable "automatically_upgrade_os" {
  type    = bool
  default = true
}
