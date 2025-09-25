terraform {
  required_providers {
    hcloud = {
      source = "hetznercloud/hcloud"
      version = "1.50.0"
    }
    cloudflare = {
      source = "cloudflare/cloudflare"
      version = "4.52.5"
    }
  }
}

provider "hcloud" {
  token = var.hcloud_token
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}
