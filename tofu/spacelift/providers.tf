terraform {
  required_providers {
    spacelift = {
      source = "spacelift-io/spacelift"
    }
    doppler = {
      source = "DopplerHQ/doppler"
    }
  }
}

provider "spacelift" {}

provider "doppler" {
  doppler_token = var.doppler_token
}
