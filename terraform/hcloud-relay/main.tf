resource "tls_private_key" "hcloud_ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "hcloud_ssh_key" "terraform" {
  name       = "terraform"
  public_key = tls_private_key.hcloud_ssh_key.public_key_openssh
}

resource "hcloud_ssh_key" "keys" {
  for_each = var.public_keys_openssh

  name       = each.key
  public_key = each.value
}

resource "hcloud_server" "relay_server" {
  name        = "relay"
  image       = "ubuntu-22.04"
  server_type = "cpx11" # 2 vCPU, 2 GB RAM - 3.85 EUR/month
  location    = "ash"   # Ashburn, VA
  ssh_keys = concat(
    [hcloud_ssh_key.terraform.name],
    keys(var.public_keys_openssh),
  )
  public_net {
    ipv4_enabled = true # 0.50 EUR/month
    ipv6_enabled = true
  }
  user_data = templatefile("${path.module}/cloud-config.yaml", {
    init_script = templatefile("${path.module}/init.sh", {
      tailscale_auth_key = var.tailscale_auth_key
    })
  })
}

data "cloudflare_zone" "net" {
  name = "macro.network"
}

resource "cloudflare_record" "relay_ipv4" {
  zone_id = data.cloudflare_zone.net.id
  name    = "hcloud-relay"
  value   = hcloud_server.relay_server.ipv4_address
  type    = "A"
  proxied = false
}

resource "cloudflare_record" "relay_ipv6" {
  zone_id = data.cloudflare_zone.net.id
  name    = "hcloud-relay"
  value   = hcloud_server.relay_server.ipv6_address
  type    = "AAAA"
  proxied = false
}
