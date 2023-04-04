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
  source = "github.com/MacroPower/terraform-kube-microos"

  cluster_name = "home"

  control_plane_nodepools = [
    {
      name              = "control-plane-1",
      ipv4_address      = "10.0.5.1"
      network_interface = "eth0"
      os_device         = "/dev/vda"
      labels            = [],
      taints            = [],
      count             = 1
    },
  ]
  agent_nodepools = [
    {
      name              = "agent-4",
      ipv4_address      = "10.0.5.5"
      network_interface = "eno0"
      os_device         = "/dev/nvme0n1"
      labels            = [],
      taints            = [],
      count             = 1
    },
  ]

  ssh_public_key             = var.ssh_public_key
  ssh_private_key            = var.ssh_private_key
  ssh_additional_public_keys = var.ssh_additional_public_keys

  allow_scheduling_on_control_plane = true

  automatically_upgrade_k3s = false
  automatically_upgrade_os  = false

  enable_klipper_metal_lb = true
  enable_metrics_server   = false
  enable_longhorn         = true
  longhorn_fstype         = "xfs"
  enable_cert_manager     = false
  enable_rancher          = false
  disable_hetzner_csi     = true
  cni_plugin              = "flannel"
  ingress_controller      = "none"

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
