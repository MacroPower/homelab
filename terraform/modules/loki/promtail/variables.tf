variable "hostname" {
  description = "Base hostname for the node"
  type        = string
  default     = "promtail"
}

variable "network" {
  type    = string
  default = "bridge"
}

variable "port_9080_external" {
  type    = number
  default = 9080
}

variable "port_3500_external" {
  type    = number
  default = 3500
}

variable "port_3600_external" {
  type    = number
  default = 3600
}

variable "port_1514_external" {
  type    = number
  default = 1514
}

variable "loki" {
  description = "Loki host"
  type        = string
}
