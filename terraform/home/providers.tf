terraform {
  required_providers {
    unifi = {
      source  = "akerl/unifi"
      version = "1.0.4"
    }
    doppler = {
      source  = "dopplerhq/doppler"
      version = "1.21.1"
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

provider "doppler" {
  doppler_token = var.doppler_token
}
