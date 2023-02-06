terraform {
  cloud {
    organization = "MacroPower"
    hostname     = "app.terraform.io"

    workspaces {
      name = "home"
    }
  }
}

module "k3s" {
  source = "./modules/k3s"

  cluster_name = "home"

  control_plane_nodepools = [
    {
      name              = "control-plane-1",
      ipv4_address      = "10.0.5.1"
      network_interface = "enp2s0"
      os_device         = "/dev/sda"
      labels            = [],
      taints            = [],
      count             = 1
    },
  ]
  agent_nodepools = [
    {
      name              = "agent-1",
      ipv4_address      = "10.0.5.1"
      network_interface = "enp2s0"
      os_device         = "/dev/sda"
      labels            = [],
      taints            = [],
      count             = 0
    },
  ]

  allow_scheduling_on_control_plane = true
  automatically_upgrade_k3s         = true
  automatically_upgrade_os          = true
  enable_klipper_metal_lb           = true

  ssh_public_key             = var.ssh_public_key
  ssh_private_key            = var.ssh_private_key
  ssh_additional_public_keys = var.ssh_additional_public_keys

  cni_plugin = "flannel"

  enable_metrics_server = false
  enable_longhorn       = true
  enable_cert_manager   = false
  enable_rancher        = false
  disable_hetzner_csi   = true

  dns_servers = [
    "10.0.0.1",
    "8.8.8.8",
    "8.8.4.4",
    "1.1.1.1",
  ]

  # Extra values that will be passed to the `extra-manifests/kustomization.yaml.tpl` if its present.
  extra_kustomize_parameters = {
    doppler_token_b64 = base64encode(var.doppler_token)
  }
}
