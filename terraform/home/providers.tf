terraform {
  required_providers {
    routeros = {
      source = "terraform-routeros/routeros"
    }
  }
}

provider "routeros" {
  alias = "mikrotik_agg_api"

  hosturl  = "api://${var.mikrotik_devices.agg.ipv4}"
  username = var.mikrotik_devices.agg.username
  password = var.mikrotik_devices.agg.password
  insecure = true
}

provider "routeros" {
  alias = "mikrotik_agg_http"

  hosturl  = "https://${var.mikrotik_devices.agg.ipv4}"
  username = var.mikrotik_devices.agg.username
  password = var.mikrotik_devices.agg.password
  insecure = true
}
