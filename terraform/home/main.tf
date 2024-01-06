terraform {
  cloud {
    organization = "MacroPower"
    hostname     = "app.terraform.io"

    workspaces {
      name = "home"
    }
  }
}

module "nas01_k3s" {
  source = "./modules/truenas-k3s"

  fqdn = var.nas01_fqdn
  ipv4 = var.nas01_ipv4

  ssh_password = var.nas01_ssh_password

  argocd_kustomization      = abspath("../../hack/extra/argocd")
  argocd_apps_kustomization = abspath("../../hack/extra/argocd-apps")
  doppler_kustomization     = abspath("../../hack/extra/doppler")

  doppler_secrets_tpl_doppler_token = var.doppler_token
}

output "kubeconfig" {
  sensitive = true
  value     = module.nas01_k3s.kubeconfig
}
