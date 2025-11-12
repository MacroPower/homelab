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
      version = "5.12.0"
    }
  }
}

provider "doppler" {
  doppler_token = var.doppler_hel_token
  alias         = "hel"
}

data "doppler_secrets" "hel" {
  project  = "hcloud-wireguard"
  config   = "hel"
  provider = doppler.hel
}

provider "hcloud" {
  token = data.doppler_secrets.hel.map.HCLOUD_TOKEN
}

provider "cloudflare" {
  api_token = data.doppler_secrets.hel.map.CLOUDFLARE_DNS_API_TOKEN
  alias     = "dns"
}
