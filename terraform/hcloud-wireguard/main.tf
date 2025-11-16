terraform {
  cloud {
    organization = "MacroPower"
    hostname     = "app.terraform.io"

    workspaces {
      name = "hcloud-wireguard"
    }
  }
}

resource "tls_private_key" "hcloud_ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "hcloud_ssh_key" "wg_terraform" {
  name       = "wg-terraform"
  public_key = tls_private_key.hcloud_ssh_key.public_key_openssh
}

resource "hcloud_ssh_key" "keys" {
  for_each = var.public_keys_openssh

  name       = each.key
  public_key = each.value
}

resource "hcloud_firewall" "wg" {
  name = "wireguard"

  # rule {
  #   direction  = "in"
  #   protocol   = "tcp"
  #   port       = "22"
  #   source_ips = ["0.0.0.0/0", "::/0"]
  # }
  # rule {
  #   direction  = "in"
  #   protocol   = "udp"
  #   port       = "22"
  #   source_ips = ["0.0.0.0/0", "::/0"]
  # }
  # rule {
  #   direction  = "in"
  #   protocol   = "tcp"
  #   port       = "443"
  #   source_ips = ["0.0.0.0/0", "::/0"]
  # }
  # rule {
  #   direction  = "in"
  #   protocol   = "udp"
  #   port       = "443"
  #   source_ips = ["0.0.0.0/0", "::/0"]
  # }

  rule {
    direction  = "in"
    protocol   = "udp"
    port       = "51820"
    source_ips = ["0.0.0.0/0", "::/0"]
  }
}

resource "hcloud_network" "main" {
  name     = "main"
  ip_range = "10.42.0.0/16"

  # NOTE: Make sure to `ip route del 10.42.0.0/16 dev wg0` on the wg server.
  # The wireguard interface should only route traffic for the wireguard subnet.
  expose_routes_to_vswitch = true
}

resource "hcloud_network_subnet" "robot" {
  network_id   = hcloud_network.main.id
  type         = "vswitch"
  network_zone = "eu-central"
  ip_range     = "10.42.2.0/24"
  vswitch_id   = "70675"
}

resource "hcloud_network_subnet" "wg" {
  network_id   = hcloud_network.main.id
  type         = "cloud"
  network_zone = "eu-central"
  ip_range     = "10.42.1.0/24"
}

resource "hcloud_server" "wg" {
  name        = "wireguard"
  image       = "wireguard"
  server_type = "cax11" # 2 vCPU, 4 GB RAM - 3.29 EUR/month
  location    = "fsn1"  # DE Falkenstein
  ssh_keys = concat(
    [hcloud_ssh_key.wg_terraform.name],
    keys(var.public_keys_openssh),
  )
  firewall_ids = [hcloud_firewall.wg.id]
  public_net {
    ipv4_enabled = true # 0.50 EUR/month
    ipv6_enabled = true
  }
  network {
    network_id = hcloud_network_subnet.wg.network_id
    ip         = "10.42.1.10" # 10.42.1.10/24
  }
}

resource "cloudflare_dns_record" "wg_ipv4" {
  zone_id  = data.doppler_secrets.fsn.map.CLOUDFLARE_DNS_ZONE_ID
  name     = "wg.fsn"
  content  = hcloud_server.wg.ipv4_address
  ttl      = 300
  type     = "A"
  proxied  = false
  provider = cloudflare.dns
}

resource "cloudflare_dns_record" "wg_ipv6" {
  zone_id  = data.doppler_secrets.fsn.map.CLOUDFLARE_DNS_ZONE_ID
  name     = "wg.fsn"
  content  = hcloud_server.wg.ipv6_address
  ttl      = 300
  type     = "AAAA"
  proxied  = false
  provider = cloudflare.dns
}
