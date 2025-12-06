terraform {
  required_providers {
    doppler = {
      source  = "DopplerHQ/doppler"
      version = "1.21.0"
    }
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "1.56.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "5.14.0"
    }
  }
}

provider "doppler" {
  doppler_token = var.doppler_fsn_token
  alias         = "fsn"
}

data "doppler_secrets" "fsn" {
  project  = "hcloud-wireguard"
  config   = "fsn"
  provider = doppler.fsn
}

provider "hcloud" {
  token = data.doppler_secrets.fsn.map.HCLOUD_TOKEN
}

provider "cloudflare" {
  api_token = data.doppler_secrets.fsn.map.CLOUDFLARE_DNS_API_TOKEN
  alias     = "dns"
}
