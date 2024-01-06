terraform {
  required_providers {
    unifi = {
      source  = "akerl/unifi"
      version = "0.41.10"
    }
    truenas = {
      source  = "dariusbakunas/truenas"
      version = "0.11.1"
    }
  }
}

provider "unifi" {
  username       = var.unifi_username
  password       = var.unifi_password
  api_url        = var.unifi_api_url
  site           = var.unifi_site
  allow_insecure = true
}

provider "truenas" {
  base_url = "http://${var.nas01_fqdn}:8080/api/v2.0"
  api_key  = var.nas01_api_key

  alias = "nas01"
}
