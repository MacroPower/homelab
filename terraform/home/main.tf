module "k3s" {
  source = "./modules/k3s"

  cluster_name = "home"

  control_plane_nodepools = [
    {
      name              = "control-plane-1",
      ipv4_address      = var.ipv4_address
      network_interface = "enp2s0"
      labels            = [],
      taints            = [],
      count             = 1
    },
  ]
  agent_nodepools = [
    {
      name              = "agent-1",
      ipv4_address      = var.ipv4_address
      network_interface = "enp2s0"
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

  dns_servers = [var.primary_dns, "8.8.8.8"]
}
