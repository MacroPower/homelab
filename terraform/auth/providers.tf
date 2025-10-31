terraform {
  required_providers {
    doppler = {
      source = "DopplerHQ/doppler"
      version = "1.21.0"
    }
    auth0 = {
      source = "auth0/auth0"
      version = "1.33.0"
    }
    cloudflare = {
      source = "cloudflare/cloudflare"
      version = "5.11.0"
    }
  }
}

provider "doppler" {
  doppler_token = var.doppler_auth_token
  alias         = "auth"
}

provider "doppler" {
  doppler_token = var.doppler_cin_token
  alias         = "cin"
}

provider "doppler" {
  doppler_token = var.doppler_cin_mgmt_token
  alias         = "cin_mgmt"
}

data "doppler_secrets" "colvin" {
  project  = "auth"
  config   = "colvin"
  provider = doppler.auth
}

provider "auth0" {
  domain        = "colvin.us.auth0.com"
  client_id     = data.doppler_secrets.colvin.map.AUTH0_CLIENT_ID
  client_secret = data.doppler_secrets.colvin.map.AUTH0_CLIENT_SECRET
}

provider "cloudflare" {
  api_token = data.doppler_secrets.colvin.map.CLOUDFLARE_DNS_API_TOKEN
  alias     = "dns"
}
