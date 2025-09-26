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

variable "doppler_token" {
  type      = string
  sensitive = true
}

variable "ssh_key" {
  type      = string
  sensitive = true
}

variable "control_plane_nodepools" {
  description = "Number of control plane nodes."
  type = list(object({
    name        = string
    server_type = string
    location    = string
    backups     = optional(bool)
    labels      = list(string)
    taints      = list(string)
    count       = number
  }))

  default = [
    {
      name        = "control-plane-hel1",
      server_type = "cx21",
      location    = "hel1",
      labels      = [],
      taints      = [],
      count       = 3
    }
  ]
}

variable "agent_nodepools" {
  description = "Number of agent nodes."
  type = list(object({
    name        = string
    server_type = string
    location    = string
    backups     = optional(bool)
    floating_ip = optional(bool)
    labels      = list(string)
    taints      = list(string)
    count       = number
  }))

  default = [
    {
      name        = "agent-hel1",
      server_type = "cpx31",
      location    = "hel1",
      labels      = [],
      taints      = [],
      count       = 2
    },
  ]
}

provider "hcloud" {
  token = var.hcloud_token
}

resource "tls_private_key" "k8s_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "random_integer" "ssh_port" {
  min = 40000
  max = 50000
}

module "kube-hetzner" {
  source  = "kube-hetzner/kube-hetzner/hcloud"
  version = "2.18.2"

  providers = {
    hcloud = hcloud
  }
  hcloud_token = var.hcloud_token

  cluster_name = "hcloud-k8s"

  # Then fill or edit the below values. Only the first values starting with a * are obligatory; the rest can remain with their default values, or you
  # could adapt them to your needs.

  # Note that some values, notably "location" and "public_key" have no effect after initializing the cluster.
  # This is to keep Terraform from re-provisioning all nodes at once, which would lose data. If you want to update
  # those, you should instead change the value here and manually re-provision each node. Grep for "lifecycle".

  # Customize the SSH port (by default 22)
  ssh_port = random_integer.ssh_port.result

  ssh_public_key  = tls_private_key.k8s_key.public_key_openssh
  ssh_private_key = tls_private_key.k8s_key.private_key_openssh

  ssh_additional_public_keys = [var.ssh_key]

  # These can be customized, or left with the default values
  # * For Hetzner locations see https://docs.hetzner.com/general/others/data-centers-and-connection/
  network_region = "eu-central" # change to `us-east` if location is ash

  control_plane_nodepools = var.control_plane_nodepools
  agent_nodepools         = var.agent_nodepools

  # * LB location and type, the latter will depend on how much load you want it to handle, see https://www.hetzner.com/cloud/load-balancer
  load_balancer_type         = "lb11"
  load_balancer_location     = "hel1"
  load_balancer_disable_ipv6 = true

  # When this is enabled, rather than the first node, all external traffic will be routed via a control-plane loadbalancer, allowing for high availability.
  # The default is false.
  use_control_plane_lb = true

  restrict_outbound_traffic = false

  extra_firewall_rules = [
    {
      description     = "HTTP"
      direction       = "in"
      protocol        = "tcp"
      port            = "80"
      source_ips      = ["0.0.0.0/0", "::/0"]
      destination_ips = [] # Won't be used for this rule
    },
    {
      description     = "HTTPS"
      direction       = "in"
      protocol        = "tcp"
      port            = "443"
      source_ips      = ["0.0.0.0/0", "::/0"]
      destination_ips = [] # Won't be used for this rule
    },
    {
      description     = "Linkerd Gateway"
      direction       = "in"
      protocol        = "tcp"
      port            = "4143"
      source_ips      = ["0.0.0.0/0", "::/0"]
      destination_ips = [] # Won't be used for this rule
    },
    {
      description     = "Linkerd Gateway"
      direction       = "in"
      protocol        = "tcp"
      port            = "4191"
      source_ips      = ["0.0.0.0/0", "::/0"]
      destination_ips = [] # Won't be used for this rule
    },
  ]

  automatically_upgrade_k3s = true
  automatically_upgrade_os  = true

  enable_cert_manager     = false
  enable_metrics_server   = false
  enable_longhorn         = false
  enable_rancher          = false
  cni_plugin              = "flannel"
  enable_klipper_metal_lb = false
  ingress_controller      = "none"

  dns_servers = [
    "8.8.8.8",
    "8.8.4.4",
    "1.1.1.1",
    "1.0.0.1",
  ]

  # Extra values that will be passed to the `extra-manifests/kustomization.yaml.tpl` if its present.
  extra_kustomize_parameters = {
    doppler_token_b64 = base64encode(var.doppler_token)
    cluster_cidr_ipv4 = "10.42.0.0/16"
  }
}

module "floating-ip" {
  source = "./modules/floating-ip"

  providers = {
    hcloud = hcloud
  }

  nodepools = var.agent_nodepools

  # Customize the SSH port (by default 22)
  ssh_port = random_integer.ssh_port.result

  ssh_public_key  = tls_private_key.k8s_key.public_key_openssh
  ssh_private_key = tls_private_key.k8s_key.private_key_openssh

  depends_on = [
    module.kube-hetzner
  ]
}
