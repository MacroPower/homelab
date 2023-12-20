terraform {
  required_providers {
    unifi = {
      source  = "akerl/unifi"
      version = "0.41.10"
    }
  }
}

provider "unifi" {
  username       = var.unifi_sites.home.username
  password       = var.unifi_sites.home.password
  api_url        = var.unifi_sites.home.api_url
  site           = var.unifi_sites.home.site
  allow_insecure = true

  alias = "home"
}
