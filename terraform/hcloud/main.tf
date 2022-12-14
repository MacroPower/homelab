terraform {
  cloud {
    organization = "MacroPower"
    hostname     = "app.terraform.io"

    workspaces {
      name = "hcloud"
    }
  }
}

variable "hcloud_token" {
  type      = string
  sensitive = true
}

variable "ssh_key" {
  type      = string
  sensitive = true
}

provider "hcloud" {
  token = var.hcloud_token
}

resource "hcloud_ssh_key" "root-key" {
  name       = "root"
  public_key = var.ssh_key
}

module "cluster" {
  providers = {
    hcloud = hcloud
  }
  source = "./modules/cluster"

  hcloud_token = var.hcloud_token
  ssh_key      = var.ssh_key
}
