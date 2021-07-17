variable "hostname" {
  description = "Base hostname for the node"
  type        = string
  default     = "elasticsearch"
}

variable "external_hostname" {
  description = "Hostname for the docker host"
  type        = string
  default     = "localhost"
}

variable "user" {
  description = "User to run the container with"
  type        = string
  default     = "root"
}

variable "network" {
  type    = string
  default = "bridge"
}

variable "mount_data_dir" {
  type    = string
  default = "/elasticsearch/data"
}

variable "port_9200_external" {
  type    = number
  default = 9200
}

variable "port_9300_external" {
  type    = number
  default = 9300
}
