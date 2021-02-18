variable "hostname" {
  description = "Base hostname for the node"
  type        = string
  default     = "loki"
}

variable "network" {
  type    = string
  default = "bridge"
}

variable "port_3100_external" {
  type    = number
  default = 3100
}
