module "elasticsearch" {
  source = "./modules/elasticsearch"
  providers = {
    docker = docker.compute_1
  }

  mount_data_dir    = "${var.docker_appdata}/elasticsearch/data"
  external_hostname = var.docker_compute_node_1
}

module "filebeat" {
  source = "./modules/filebeat"
  providers = {
    docker = docker.compute_1
  }

  mount_config_file = "${var.docker_appdata}/filebeat/filebeat.yml"
  elasticsearch     = module.elasticsearch.hostname
}

module "loki" {
  source = "./modules/loki/loki"
  providers = {
    docker = docker.compute_1
  }
}

module "promtail" {
  source = "./modules/loki/promtail"
  providers = {
    docker = docker.compute_1
  }

  loki = module.loki.hostname
}
