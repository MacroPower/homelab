locals {
  image_reference = "docker.elastic.co/elasticsearch/elasticsearch:7.10.0"
  container_name  = "elasticsearch"

  container_hostname           = var.hostname
  container_network            = var.network
  container_user               = var.user
  container_mount_data         = var.mount_data_dir
  container_port_9200_external = var.port_9200_external
  container_port_9300_external = var.port_9300_external
  container_external_hostname  = var.external_hostname
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

  labels {
    label = "co.elastic.logs/module"
    value = "elasticsearch"
  }

  mounts {
    source    = local.container_mount_data
    target    = "/usr/share/elasticsearch/data"
    read_only = false
    type      = "bind"
  }

  mounts {
    target    = "/tmp"
    read_only = false
    type      = "tmpfs"
  }

  ports {
    internal = 9200
    external = local.container_port_9200_external
  }

  ports {
    internal = 9300
    external = local.container_port_9300_external
  }

  env = [
    "discovery.type=single-node",
    "http.cors.enabled=true",
    "http.cors.allow-origin=http://${local.container_external_hostname}:1358",
    "http.cors.allow-headers=X-Requested-With,X-Auth-Token,Content-Type,Content-Length,Authorization",
    "http.cors.allow-credentials=true",
  ]
}
