variable "hcloud_token" {
  type      = string
  sensitive = true
}

variable "ssh_key" {
  type      = string
  sensitive = true
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
  providers = {
    hcloud = hcloud
  }
  hcloud_token = var.hcloud_token

  # Then fill or edit the below values. Only the first values starting with a * are obligatory; the rest can remain with their default values, or you
  # could adapt them to your needs.

  source = "kube-hetzner/kube-hetzner/hcloud"
  version = "1.5.6"

  # Note that some values, notably "location" and "public_key" have no effect after initializing the cluster.
  # This is to keep Terraform from re-provisioning all nodes at once, which would lose data. If you want to update
  # those, you should instead change the value here and manually re-provision each node. Grep for "lifecycle".

  # Customize the SSH port (by default 22)
  ssh_port = random_integer.ssh_port.result

  ssh_public_key = tls_private_key.k8s_key.public_key_openssh
  ssh_private_key = tls_private_key.k8s_key.private_key_openssh

  ssh_additional_public_keys = [var.ssh_key]

  # These can be customized, or left with the default values
  # * For Hetzner locations see https://docs.hetzner.com/general/others/data-centers-and-connection/
  network_region = "eu-central" # change to `us-east` if location is ash

  # For the control planes, at least three nodes are the minimum for HA. Otherwise, you need to turn off the automatic upgrade (see ReadMe).
  # As per Rancher docs, it must always be an odd number, never even! See https://rancher.com/docs/k3s/latest/en/installation/ha-embedded/
  # For instance, one is ok (non-HA), two is not ok, and three is ok (becomes HA). It does not matter if they are in the same nodepool or not! So they can be in different locations and of various types.

  # Of course, you can choose any number of nodepools you want, with the location you want. The only constraint on the location is that you need to stay in the same network region, Europe, or the US.
  # For the server type, the minimum instance supported is cpx11 (just a few cents more than cx11); see https://www.hetzner.com/cloud.

  # IMPORTANT: Before you create your cluster, you can do anything you want with the nodepools, but you need at least one of each control plane and agent.
  # Once the cluster is up and running, you can change nodepool count and even set it to 0 (in the case of the first control-plane nodepool, the minimum is 1),
  # you can also rename it (if the count is 0), but do not remove a nodepool from the list.

  # The only nodepools that are safe to remove from the list when you edit it are at the end of the lists. That is due to how subnets and IPs get allocated (FILO).
  # You can, however, freely add other nodepools at the end of each list if you want! The maximum number of nodepools you can create combined for both lists is 255.
  # Also, before decreasing the count of any nodepools to 0, it's essential to drain and cordon the nodes in question. Otherwise, it will leave your cluster in a bad state.

  # Before initializing the cluster, you can change all parameters and add or remove any nodepools. You need at least one nodepool of each kind, control plane, and agent.
  # The nodepool names are entirely arbitrary, you can choose whatever you want, but no special characters or underscore, and they must be unique; only alphanumeric characters and dashes are allowed.

  # If you want to have a single node cluster, have one control plane nodepools with a count of 1, and one agent nodepool with a count of 0.
  
  # Please note that changing labels and taints after the first run will have no effect. If needed, you will need to do that through Kubernetes directly.

  # * Example below:

  control_plane_nodepools = [
    {
      name        = "control-plane-hel1",
      server_type = "cpx11",
      location    = "hel1",
      labels      = [],
      taints      = [],
      count       = 3
    }
  ]

  agent_nodepools = [
    {
      name        = "agent-small-hel1",
      server_type = "cpx11",
      location    = "hel1",
      labels      = [],
      taints      = [],
      count       = 5
    },
  ]

  # * LB location and type, the latter will depend on how much load you want it to handle, see https://www.hetzner.com/cloud/load-balancer
  load_balancer_type         = "lb11"
  load_balancer_location     = "hel1"
  load_balancer_disable_ipv6 = true

  # When this is enabled, rather than the first node, all external traffic will be routed via a control-plane loadbalancer, allowing for high availability.
  # The default is false.
  use_control_plane_lb = true

  # Use the klipper LB, instead of the default Hetzner one, that has an advantage of dropping the cost of the setup,
  # Automatically "true" in the case of single node cluster.
  # It can work with any ingress controller that you choose to deploy.
  enable_klipper_metal_lb = false

  # You can refine a base domain name to be use in this form of nodename.base_domain for setting the reserve dns inside Hetzner
  # base_domain = "mycluster.example.com"

  # To use local storage on the nodes, you can enable Longhorn, default is "false".
  enable_longhorn = false

  # If you want to disable the Traefik ingress controller, to use the Nginx ingress controller for instance, you can can set this to "false". Default is "true".
  enable_traefik = false

  # If you want to disable the metric server, you can! Default is "true".
  enable_metrics_server = false

  # If you want to disable the automatic upgrade of k3s, you can set this to false. The default is "true".
  # automatically_upgrade_k3s = false

  # Allows you to specify either stable, latest, testing or supported minor versions (defaults to stable)
  # see https://rancher.com/docs/k3s/latest/en/upgrades/basic/ and https://update.k3s.io/v1-release/channels
  # initial_k3s_channel = "latest"

  # The cluster name, by default "k3s"
  cluster_name = "hcloud-k8s"

  # Whether to use the cluster name in the node name, in the form of {cluster_name}-{nodepool_name}, the default is "true".
  # use_cluster_name_in_node_name = false

  # Adding extra firewall rules, like opening a port
  # More info on the format here https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/firewall
  extra_firewall_rules = [
    {
      direction       = "out"
      protocol        = "icmp"
      port            = ""
      source_ips      = []
      destination_ips = ["::/0"]
    },

    # DNS
    {
      direction       = "out"
      protocol        = "tcp"
      port            = "53"
      source_ips      = []
      destination_ips = ["::/0"]
    },
    {
      direction       = "out"
      protocol        = "udp"
      port            = "53"
      source_ips      = []
      destination_ips = ["::/0"]
    },

    # HTTP(s)
    {
      direction       = "out"
      protocol        = "tcp"
      port            = "80"
      source_ips      = []
      destination_ips = ["::/0"]
    },
    {
      direction       = "out"
      protocol        = "tcp"
      port            = "443"
      source_ips      = []
      destination_ips = ["::/0"]
    },

    #NTP
    {
      direction       = "out"
      protocol        = "udp"
      port            = "123"
      source_ips      = []
      destination_ips = ["::/0"]
    }
  ]
  #   # For Postgres
  #   {
  #     direction       = "in"
  #     protocol        = "tcp"
  #     port            = "5432"
  #     source_ips      = ["0.0.0.0/0", "::/0"]
  #     destination_ips = [] # Won't be used for this rule 
  #   },
  #   # To Allow ArgoCD access to resources via SSH
  #   {
  #     direction       = "out"
  #     protocol        = "tcp"
  #     port            = "22"
  #     source_ips      = [] # Won't be used for this rule 
  #     destination_ips = ["0.0.0.0/0", "::/0"]
  #   }
  # ]

  cni_plugin = "flannel"

  # By default, we allow ICMP ping in to the nodes, to check for liveness for instance. If you do not want to allow that, you can. Just set this flag to true (false by default).
  block_icmp_ping_in = true

  enable_cert_manager = false

  # IP Addresses to use for the DNS Servers, set to an empty list to use the ones provided by Hetzner, defaults to ["1.1.1.1", " 1.0.0.1", "8.8.8.8"].
  # For rancher installs, best to leave it as default.
  dns_servers = [
    "8.8.8.8",
    "8.8.4.4",
    "1.1.1.1",
  ]

  enable_rancher = false

  # Extra values that will be passed to the `extra-manifests/kustomization.yaml.tpl` if its present.
  # extra_kustomize_parameters={}
}

terraform {
  required_version = ">= 1.2.0"
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = ">= 1.35.1"
    }
  }
}
