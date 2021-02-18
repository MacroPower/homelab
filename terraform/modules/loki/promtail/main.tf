locals {
  image_reference = "grafana/promtail:2.0.0"

  container_name               = "promtail"
  container_hostname           = var.hostname
  container_network            = var.network
  container_port_9080_external = var.port_9080_external
  container_port_3500_external = var.port_3500_external
  container_port_3600_external = var.port_3600_external
  container_port_1514_external = var.port_1514_external
  container_config_file        = "/mnt/config/promtail-config.yaml"

  loki_address = var.loki
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
  vars = {
    loki_address = local.loki_address
  }
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
    internal = 9080
    external = local.container_port_9080_external
  }

  ports {
    internal = 3500
    external = local.container_port_3500_external
  }

  ports {
    internal = 3600
    external = local.container_port_3600_external
  }

  ports {
    internal = 1514
    external = local.container_port_1514_external
  }
}
