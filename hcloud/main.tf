variable "hcloud_token" {
  type      = string
  sensitive = true
}

variable "ssh_key" {
  type      = string
  sensitive = true
}

module "k8s" {
  source = "./modules/k8s"

  hcloud_token = var.hcloud_token
  ssh_key      = var.ssh_key
}

provider "kubectl" {
  alias = "k8s"

  load_config_file       = false
  host                   = "https://${module.k8s.load_balancer_ipv4}:6443"
  client_certificate     = module.k8s.client_certificate_data
  client_key             = module.k8s.client_key_data
  cluster_ca_certificate = module.k8s.certificate_authority_data
}


module "namespaces" {
  source = "./modules/namespaces"

  depends_on = [
    module.k8s,
  ]

  providers = {
    kubectl = kubectl.k8s
  }
}

module "argocd" {
  source = "./modules/argocd"

  depends_on = [
    module.k8s,
    module.namespaces,
  ]

  providers = {
    kubectl = kubectl.k8s
  }
}
