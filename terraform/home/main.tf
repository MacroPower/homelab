terraform {
  cloud {
    organization = "MacroPower"
    hostname     = "app.terraform.io"

    workspaces {
      name = "home"
    }
  }
}

data "doppler_secrets" "tf_main_home" {
  project = "terraform"
  config  = "main_home"
}
