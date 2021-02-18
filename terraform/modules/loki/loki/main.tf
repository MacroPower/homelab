locals {
  image_reference = "grafana/loki:2.0.0"

  container_name               = "loki"
  container_hostname           = var.hostname
  container_network            = var.network
  container_port_3100_external = var.port_3100_external
  container_config_file        = "/mnt/config/loki-config.yaml"
}

data "docker_registry_image" "image" {
  name = local.image_reference
}

resource "docker_image" "image" {
  provider      = docker
  name          = data.docker_registry_image.image.name
  pull_triggers = [data.docker_registry_image.image.sha256_digest]
}

data "template_file" "config" {
  template = file("${path.module}/config.yaml")
}

resource "docker_container" "container" {
  provider = docker
  image    = docker_image.image.latest

  name         = local.container_name
  hostname     = local.container_hostname
  network_mode = local.container_network
  user         = "10001:10001"

  restart = "always"

  upload {
    content = data.template_file.config.rendered
    file    = local.container_config_file
  }

  capabilities {
    add  = ["ALL"]
    drop = ["SYS_ADMIN"]
  }

  env = []

  command = [
    "-config.file=${local.container_config_file}",
  ]

  ports {
    internal = 3100
    external = local.container_port_3100_external
  }
}
