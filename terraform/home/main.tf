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

  fqdn = var.truenas_devices.nas01.fqdn
  ipv4 = var.truenas_devices.nas01.ipv4

  ssh_password = var.truenas_devices.nas01.ssh_password

  argocd_kustomization      = abspath("../../hack/extra/argocd")
  argocd_apps_kustomization = abspath("../../hack/extra/argocd-apps")
  doppler_kustomization     = abspath("../../hack/extra/doppler")

  doppler_secrets_tpl_doppler_token = var.doppler_token
}

output "kubeconfig" {
  sensitive = true
  value     = module.nas01_k3s.kubeconfig
}

module "unifi" {
  source = "./modules/unifi"

  domain_name = var.unifi_sites.home.domain_name

  providers = {
    unifi = unifi.home
  }
}
