terraform {
  cloud {
    organization = "MacroPower"
    hostname     = "app.terraform.io"

    workspaces {
      name = "hcloud-unifi"
    }
  }
}

resource "tls_private_key" "hcloud_ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "hcloud_ssh_key" "unifi_terraform" {
  name       = "unifi_terraform"
  public_key = tls_private_key.hcloud_ssh_key.public_key_openssh
}

resource "hcloud_ssh_key" "keys" {
  for_each = var.public_keys_openssh

  name       = each.key
  public_key = each.value
}

resource "hcloud_firewall" "unifi" {
  name = "unifi"

  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "22"
    source_ips = ["0.0.0.0/0", "::/0"]
  }
  rule {
    direction  = "in"
    protocol   = "udp"
    port       = "22"
    source_ips = ["0.0.0.0/0", "::/0"]
  }
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
}

resource "hcloud_network" "unifi" {
  name     = "unifi"
  ip_range = "10.200.0.0/14"

  expose_routes_to_vswitch = true
}

resource "hcloud_network_subnet" "default" {
  network_id   = hcloud_network.unifi.id
  type         = "cloud"
  network_zone = "eu-central"
  ip_range     = "10.200.0.0/16"
}

resource "hcloud_network_route" "cin_lab" {
  network_id  = hcloud_network.unifi.id
  destination = "10.10.0.0/16"
  gateway     = "10.200.0.2"
}

resource "hcloud_server" "unifi" {
  name        = "unifi"
  image       = "ubuntu-24.04"
  server_type = "cax11" # 2 vCPU, 4 GB RAM - 3.29 EUR/month
  location    = "fsn1"  # DE Falkenstein
  ssh_keys = concat(
    [hcloud_ssh_key.unifi_terraform.name],
    keys(var.public_keys_openssh),
  )
  firewall_ids = [hcloud_firewall.unifi.id]
  public_net {
    ipv4_enabled = true # 0.50 EUR/month
    ipv6_enabled = true
  }
  network {
    network_id = hcloud_network_subnet.default.network_id
    ip         = "10.200.0.2"
  }
  user_data = <<-EOF
    #cloud-config
    package_update: true
    package_upgrade: true
    packages:
      - podman
  EOF
  lifecycle {
    ignore_changes = [
      ssh_keys,
    ]
  }
}

resource "cloudflare_dns_record" "unifi_ipv4" {
  zone_id  = data.doppler_secrets.fsn.map.CLOUDFLARE_DNS_ZONE_ID
  name     = "unifi.fsn"
  content  = hcloud_server.unifi.ipv4_address
  ttl      = 300
  type     = "A"
  proxied  = false
  provider = cloudflare.dns
}

resource "cloudflare_dns_record" "unifi_ipv6" {
  zone_id  = data.doppler_secrets.fsn.map.CLOUDFLARE_DNS_ZONE_ID
  name     = "unifi.fsn"
  content  = hcloud_server.unifi.ipv6_address
  ttl      = 300
  type     = "AAAA"
  proxied  = false
  provider = cloudflare.dns
}
