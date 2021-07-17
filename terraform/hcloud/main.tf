variable "hcloud_token" {
  type      = string
  sensitive = true
}

module "k3s" {
  source = "./modules/k3s"

  hcloud_token = var.hcloud_token
}
