terraform {
  cloud {
    organization = "MacroPower"
    hostname     = "app.terraform.io"

    workspaces {
      name = "home"
    }
  }
}

# module "truenas_store01_k3s" {
#   source = "./modules/truenas-k3s"

#   name = var.truenas_devices.store01.name
#   ipv4 = var.truenas_devices.store01.ipv4

#   ssh_password = var.truenas_devices.store01.ssh_password

#   argocd_kustomization      = abspath("../../hack/extra/argocd")
#   argocd_apps_kustomization = abspath("../../hack/extra/argocd-apps")
#   doppler_kustomization     = abspath("../../hack/extra/doppler")

#   doppler_secrets_tpl_doppler_token = var.doppler_token
# }

module "unifi" {
  source = "./modules/unifi"

  domain_name = var.unifi_sites.home.domain_name

  providers = {
    unifi = unifi.home
  }
}
