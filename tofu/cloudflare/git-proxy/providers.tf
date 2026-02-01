terraform {
  required_providers {
    doppler = {
      source = "DopplerHQ/doppler"
    }
    cloudflare = {
      source = "cloudflare/cloudflare"
    }
  }
}

provider "doppler" {
  doppler_token = var.doppler_token
}

provider "cloudflare" {
  api_token = data.doppler_secrets.this.map.API_TOKEN
}
