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
