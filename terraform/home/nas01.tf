locals {
  MiB = 1024 * 1024
  GiB = 1024 * local.MiB
  TiB = 1024 * local.GiB
}

resource "random_password" "nas01_encryption_key" {
  length      = 64
  min_lower   = 1
  min_numeric = 1
  min_special = 1
  min_upper   = 1
}

resource "doppler_secret" "nas01_encryption_key" {
  project = "terraform"
  config  = "main_home"
  name    = "NAS01_ENCRYPTION_KEY"
  value   = random_password.nas01_encryption_key.result
}
