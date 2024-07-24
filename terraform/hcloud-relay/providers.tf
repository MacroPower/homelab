terraform {
  required_providers {
    hcloud = {
      source = "hetznercloud/hcloud"
      version = "1.47.0"
    }
    cloudflare = {
      source = "cloudflare/cloudflare"
      version = "4.38.0"
    }
  }
}

provider "hcloud" {
  token = var.hcloud_token
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}
