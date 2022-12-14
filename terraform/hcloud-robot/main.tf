terraform {
  cloud {
    organization = "MacroPower"
    hostname     = "app.terraform.io"

    workspaces {
      name = "hcloud-robot"
    }
  }
}

resource "random_integer" "ssh_port" {
  min = 40000
  max = 50000
}

module "k3s" {
  source = "./modules/k3s"

  cluster_name = "hcloud-robot"

  control_plane_nodepools = [
    {
      name              = "control-plane-1",
      ipv4_address      = var.ipv4_address
      network_interface = "eth0"
      os_device         = "/dev/nvme0n1"
      labels            = [],
      taints            = [],
      count             = 1
    },
  ]
  agent_nodepools = [
    {
      name              = "agent-1",
      ipv4_address      = var.ipv4_address
      network_interface = "eth0"
      os_device         = "/dev/nvme0n1"
      labels            = [],
      taints            = [],
      count             = 0
    },
  ]

  # Single node config
  allow_scheduling_on_control_plane = true
  automatically_upgrade_k3s         = false
  automatically_upgrade_os          = false
  enable_klipper_metal_lb           = true

  ssh_public_key             = var.ssh_public_key
  ssh_private_key            = var.ssh_private_key
  ssh_additional_public_keys = var.ssh_additional_public_keys

  cni_plugin = "flannel"

  enable_traefik        = false
  enable_metrics_server = false
  enable_longhorn       = false
  enable_cert_manager   = false
  enable_rancher        = false

  ssh_port = random_integer.ssh_port.result

  dns_servers = []
}
