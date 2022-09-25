variable "hcloud_token" {
  type      = string
  sensitive = true
}

variable "ssh_key" {
  type      = string
  sensitive = true
}

module "cluster" {
  source = "./modules/cluster"

  hcloud_token = var.hcloud_token
  ssh_key      = var.ssh_key
}

provider "kubectl" {
  alias = "k8s"

  load_config_file       = false
  host                   = "https://${module.cluster.load_balancer_ipv4}:6443"
  client_certificate     = module.cluster.client_certificate_data
  client_key             = module.cluster.client_key_data
  cluster_ca_certificate = module.cluster.certificate_authority_data
}

module "namespaces" {
  source = "./modules/namespaces"

  depends_on = [
    module.cluster,
  ]

  providers = {
    kubectl = kubectl.k8s
  }
}

module "argocd" {
  source = "./modules/argocd"

  depends_on = [
    module.cluster,
    module.namespaces,
  ]

  providers = {
    kubectl = kubectl.k8s
  }
}
