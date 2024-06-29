terraform {
  cloud {
    organization = "MacroPower"
    hostname     = "app.terraform.io"

    workspaces {
      name = "home-authentik"
    }
  }
}

resource "null_resource" "init" {}
