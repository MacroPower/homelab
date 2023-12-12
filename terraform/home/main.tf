module "mikrotik_agg_api" {
  source = "./modules/mikrotik-api"

  name = var.mikrotik_devices.agg.name
  ipv4 = var.mikrotik_devices.agg.ipv4

  providers = {
    routeros = routeros.mikrotik_agg_api
  }
}

module "mikrotik_agg" {
  source = "./modules/mikrotik"

  name = module.mikrotik_agg_api.identity

  depends_on = [module.mikrotik_agg_api]
  providers = {
    routeros = routeros.mikrotik_agg_http
  }
}

module "truenas_store01_k3s" {
  source = "./modules/truenas-k3s"

  name = var.truenas_devices.store01.name
  ipv4 = var.truenas_devices.store01.ipv4

  ssh_password = var.truenas_devices.store01.ssh_password

  argocd_kustomization      = abspath("../../hack/extra/argocd")
  argocd_apps_kustomization = abspath("../../hack/extra/argocd-apps")
  doppler_kustomization     = abspath("../../hack/extra/doppler")

  doppler_secrets_tpl_doppler_token = var.doppler_token
}
