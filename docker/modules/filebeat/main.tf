locals {
  image_reference = "docker.elastic.co/beats/filebeat:7.10.0"

  # Container config
  container_name         = "filebeat"
  container_hostname     = var.hostname
  container_network      = var.network
  container_user         = var.user
  container_mount_config = var.mount_config_file

  # Service config
  service_elastic      = var.elasticsearch
  service_elastic_user = var.elasticsearch_username
  service_elastic_pw   = var.elasticsearch_password
}

data "docker_registry_image" "image" {
  name = local.image_reference
}

resource "docker_image" "image" {
  provider      = docker
  name          = data.docker_registry_image.image.name
  pull_triggers = [data.docker_registry_image.image.sha256_digest]
}

resource "docker_container" "container" {
  provider = docker
  image    = docker_image.image.latest

  name         = local.container_name
  hostname     = local.container_hostname
  network_mode = local.container_network
  user         = local.container_user

  restart = "always"

  capabilities {
    add  = ["ALL"]
    drop = ["SYS_ADMIN"]
  }

  env = [
    "output.elasticsearch.hosts=[\"${local.service_elastic}\"]",
    "ELASTICSEARCH_HOSTS=[\"${local.service_elastic}\"]",
    "ELASTICSEARCH_USERNAME=${local.service_elastic_user}",
    "ELASTICSEARCH_PASSWORD=${local.service_elastic_pw}",
  ]

  mounts {
    source    = local.container_mount_config
    target    = "/usr/share/filebeat/filebeat.yml"
    read_only = false
    type      = "bind"
  }

  mounts {
    target    = "/var/lib/docker/containers"
    source    = "/var/lib/docker/containers"
    read_only = true
    type      = "bind"
  }

  mounts {
    target    = "/var/run/docker.sock"
    source    = "/var/run/docker.sock"
    read_only = true
    type      = "bind"
  }

  mounts {
    target    = "/var/log/syslog"
    source    = "/var/log/syslog"
    read_only = true
    type      = "bind"
  }

  mounts {
    target    = "/var/log/auth.log"
    source    = "/var/log/auth.log"
    read_only = true
    type      = "bind"
  }
}
