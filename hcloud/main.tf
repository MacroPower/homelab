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

module "argocd" {
  source = "./modules/argocd"

  depends_on = [
    module.k8s,
  ]

  apiserver_url              = module.k8s.apiserver_url
  client_certificate_data    = module.k8s.client_certificate_data
  client_key_data            = module.k8s.client_key_data
  certificate_authority_data = module.k8s.certificate_authority_data
}
