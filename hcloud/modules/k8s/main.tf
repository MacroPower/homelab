variable "hcloud_token" {
  type      = string
  sensitive = true
}

variable "ssh_key" {
  type      = string
  sensitive = true
}

provider "hcloud" {
  token = var.hcloud_token
}

module "cluster" {
  source  = "tibordp/dualstack-k8s/hcloud"
  version = "1.0.1"

  name               = "k8s"
  hcloud_ssh_key     = var.ssh_key
  hcloud_token       = var.hcloud_token
  location           = "hel1"
  master_server_type = "cx31"
  worker_server_type = "cx31"

  worker_count = 3
  master_count = 2

  control_plane_lb_type = "lb11"

  kubernetes_version = "1.24.0"
}

output "kubeconfig" {
  value     = module.k8s.kubeconfig
  sensitive = true
}

output "load_balancer_ipv4" {
  value = module.k8s.load_balancer.ipv4
}

output "host" {
  value = module.k8s.apiserver_url
}

output "client_certificate" {
  value = module.k8s.client_certificate_data
}

output "client_key" {
  value = module.k8s.client_key_data
}

output "cluster_ca_certificate" {
  value = module.k8s.certificate_authority_data
}
