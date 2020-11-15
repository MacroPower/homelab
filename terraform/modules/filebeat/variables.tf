variable "hostname" {
  description = "Base hostname for the node"
  type        = string
  default     = "filebeat"
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

variable "mount_config_file" {
  type    = string
  default = "/filebeat/filebeat.yml"
}

variable "elasticsearch" {
  description = "Elasticsearch host"
  type        = string
}

variable "elasticsearch_username" {
  description = "Elasticsearch username"
  type        = string
  default     = "elastic"
}

variable "elasticsearch_password" {
  description = "Elasticsearch password"
  type        = string
  default     = "changeme"
}
