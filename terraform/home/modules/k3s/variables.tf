variable "ssh_port" {
  description = "The main SSH port to connect to the nodes."
  type        = number
  default     = 22

  validation {
    condition     = var.ssh_port >= 0 && var.ssh_port <= 65535
    error_message = "The SSH port must use a valid range from 0 to 65535."
  }
}

variable "ssh_public_key" {
  description = "SSH public Key."
  type        = string
}

variable "ssh_private_key" {
  description = "SSH private Key."
  type        = string
  sensitive   = true
}

variable "ssh_additional_public_keys" {
  description = "Additional SSH public Keys. Use them to grant other team members root access to your cluster nodes."
  type        = list(string)
  default     = []
}

variable "control_plane_nodepools" {
  description = "Number of control plane nodes."
  type        = list(any)
  default     = []
}

variable "agent_nodepools" {
  description = "Number of agent nodes."
  type        = list(any)
  default     = []
}

variable "kured_version" {
  type        = string
  default     = null
  description = "Version of Kured"
}

variable "enable_nginx" {
  type        = bool
  default     = false
  description = "Whether to enable or disbale the installation of the Nginx Ingress Controller."
}

variable "nginx_ingress_values" {
  type        = string
  default     = ""
  description = "Additional helm values file to pass to nginx as 'valuesContent' at the HelmChart."
}

variable "enable_klipper_metal_lb" {
  type        = bool
  default     = false
  description = "Use klipper load balancer."
}

variable "etcd_s3_backup" {
  description = "Etcd cluster state backup to S3 storage"
  type        = map(any)
  sensitive   = true
  default     = {}
}

variable "enable_traefik" {
  type        = bool
  default     = true
  description = "Whether to enable or disable the installation of the Traefik Ingress Controller."
}

variable "traefik_acme_tls" {
  type        = bool
  default     = false
  description = "Whether to include the TLS configuration with the Traefik configuration."
}

variable "traefik_acme_email" {
  type        = string
  default     = ""
  description = "Email used to recieved expiration notice for certificate."
}

variable "traefik_additional_options" {
  type        = list(string)
  default     = []
  description = "Additional options to pass to Traefik as a list of strings. These are the ones that go into the additionalArguments section of the Traefik helm values file."
}

variable "traefik_ingress_values" {
  type        = string
  default     = ""
  description = "Additional helm values file to pass to Traefik as 'valuesContent' at the HelmChart."
}

variable "allow_scheduling_on_control_plane" {
  type        = bool
  default     = false
  description = "Whether to allow non-control-plane workloads to run on the control-plane nodes."
}

variable "enable_metrics_server" {
  type        = bool
  default     = true
  description = "Whether to enable or disbale k3s mertric server."
}

variable "initial_k3s_channel" {
  type        = string
  default     = "v1.24"
  description = "Allows you to specify an initial k3s channel."

  validation {
    condition     = contains(["stable", "latest", "testing", "v1.16", "v1.17", "v1.18", "v1.19", "v1.20", "v1.21", "v1.22", "v1.23", "v1.24", "v1.25"], var.initial_k3s_channel)
    error_message = "The initial k3s channel must be one of stable, latest or testing, or any of the minor kube versions like v1.22."
  }
}

variable "automatically_upgrade_k3s" {
  type        = bool
  default     = true
  description = "Whether to automatically upgrade k3s based on the selected channel."
}

variable "automatically_upgrade_os" {
  type        = bool
  default     = true
  description = "Whether to enable or disable automatic os updates. Defaults to true. Should be disabled for single-node clusters"
}

variable "extra_firewall_rules" {
  type        = list(any)
  default     = []
  description = "Additional firewall rules to apply to the cluster."
}

variable "use_cluster_name_in_node_name" {
  type        = bool
  default     = true
  description = "Whether to use the cluster name in the node name."
}

variable "cluster_name" {
  type        = string
  default     = "k3s"
  description = "Name of the cluster."

  validation {
    condition     = can(regex("^[a-z0-9\\-]+$", var.cluster_name))
    error_message = "The cluster name must be in the form of lowercase alphanumeric characters and/or dashes."
  }
}

variable "base_domain" {
  type        = string
  default     = ""
  description = "Base domain of the cluster, used for reserve dns."

  validation {
    condition     = can(regex("^(?:(?:(?:[A-Za-z0-9])|(?:[A-Za-z0-9](?:[A-Za-z0-9\\-]+)?[A-Za-z0-9]))+(\\.))+([A-Za-z]{2,})([\\/?])?([\\/?][A-Za-z0-9\\-%._~:\\/?#\\[\\]@!\\$&\\'\\(\\)\\*\\+,;=]+)?$", var.base_domain)) || var.base_domain == ""
    error_message = "It must be a valid domain name (FQDN)."
  }
}

variable "disable_network_policy" {
  type        = bool
  default     = false
  description = "Disable k3s default network policy controller (default false, automatically true for calico and cilium)."
}

variable "cni_plugin" {
  type        = string
  default     = "flannel"
  description = "CNI plugin for k3s."

  validation {
    condition     = contains(["flannel", "calico", "cilium"], var.cni_plugin)
    error_message = "The cni_plugin must be one of \"flannel\", \"calico\", or \"cilium\"."
  }
}

variable "cilium_values" {
  type        = string
  default     = ""
  description = "Additional helm values file to pass to Cilium as 'valuesContent' at the HelmChart."
}

variable "enable_longhorn" {
  type        = bool
  default     = false
  description = "Whether of not to enable Longhorn."
}

variable "longhorn_fstype" {
  type        = string
  default     = "ext4"
  description = "The longhorn fstype."

  validation {
    condition     = contains(["ext4", "xfs"], var.longhorn_fstype)
    error_message = "Must be one of \"ext4\" or \"xfs\""
  }
}

variable "longhorn_replica_count" {
  type        = number
  default     = 3
  description = "Number of replicas per longhorn volume."
}

variable "longhorn_values" {
  type        = string
  default     = ""
  description = "Additional helm values file to pass to longhorn as 'valuesContent' at the HelmChart."
}

variable "enable_cert_manager" {
  type        = bool
  default     = false
  description = "Enable cert manager."
}

variable "cert_manager_values" {
  type        = string
  default     = ""
  description = "Additional helm values file to pass to Cert-Manager as 'valuesContent' at the HelmChart."
}

variable "enable_rancher" {
  type        = bool
  default     = false
  description = "Enable rancher."
}

variable "rancher_install_channel" {
  type        = string
  default     = "stable"
  description = "The rancher installation channel."

  validation {
    condition     = contains(["stable", "latest"], var.rancher_install_channel)
    error_message = "The allowed values for the Rancher install channel are stable or latest."
  }
}

variable "rancher_hostname" {
  type        = string
  default     = ""
  description = "The rancher hostname."

  validation {
    condition     = can(regex("^(?:(?:(?:[A-Za-z0-9])|(?:[A-Za-z0-9](?:[A-Za-z0-9\\-]+)?[A-Za-z0-9]))+(\\.))+([A-Za-z]{2,})([\\/?])?([\\/?][A-Za-z0-9\\-%._~:\\/?#\\[\\]@!\\$&\\'\\(\\)\\*\\+,;=]+)?$", var.rancher_hostname)) || var.rancher_hostname == ""
    error_message = "It must be a valid domain name (FQDN)."
  }
}

variable "rancher_registration_manifest_url" {
  type        = string
  description = "The url of a rancher registration manifest to apply. (see https://rancher.com/docs/rancher/v2.6/en/cluster-provisioning/registered-clusters/)."
  default     = ""
  sensitive   = true
}

variable "rancher_bootstrap_password" {
  type        = string
  default     = ""
  description = "Rancher bootstrap password."
  sensitive   = true

  validation {
    condition     = (length(var.rancher_bootstrap_password) >= 48) || (length(var.rancher_bootstrap_password) == 0)
    error_message = "The Rancher bootstrap password must be at least 48 characters long."
  }
}

variable "rancher_values" {
  type        = string
  default     = ""
  description = "Additional helm values file to pass to Rancher as 'valuesContent' at the HelmChart."
}

variable "block_icmp_ping_in" {
  type        = bool
  default     = false
  description = "Block entering ICMP ping."
}

variable "use_control_plane_lb" {
  type        = bool
  default     = false
  description = "When this is enabled, rather than the first node, all external traffic will be routed via a control-plane loadbalancer, allowing for high availability."
}

variable "dns_servers" {
  type        = list(string)
  default     = ["1.1.1.1", " 1.0.0.1", "8.8.8.8"]
  description = "IP Addresses to use for the DNS Servers, set to an empty list to use the ones provided by Hetzner."
}

variable "extra_packages_to_install" {
  type        = list(string)
  default     = []
  description = "A list of additional packages to install on nodes."
}

variable "extra_kustomize_parameters" {
  type        = map(any)
  default     = {}
  description = "All values will be passed to the `kustomization.tmp.yml` template."
}

variable "create_kubeconfig" {
  type        = bool
  default     = true
  description = "Create the kubeconfig as a local file resource. Should be disabled for automatic runs."
}

variable "create_kustomization" {
  type        = bool
  default     = true
  description = "Create the kustomization backup as a local file resource. Should be disabled for automatic runs."
}
