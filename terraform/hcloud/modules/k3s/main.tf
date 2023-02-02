resource "random_password" "k3s_token" {
  length  = 48
  special = false
}

resource "hcloud_ssh_key" "k3s" {
  count      = var.hcloud_ssh_key_id == null ? 1 : 0
  name       = var.cluster_name
  public_key = var.ssh_public_key
  labels     = local.labels
}

resource "hcloud_network" "k3s" {
  name     = var.cluster_name
  ip_range = local.network_ipv4_cidr
  labels   = local.labels
}

# We start from the end of the subnets cird array,
# as we would have fewer control plane nodepools, than angent ones.
resource "hcloud_network_subnet" "control_plane" {
  count        = length(var.control_plane_nodepools)
  network_id   = hcloud_network.k3s.id
  type         = "cloud"
  network_zone = var.network_region
  ip_range     = local.network_ipv4_subnets[255 - count.index]
}

# Here we start at the beginning of the subnets cird array
resource "hcloud_network_subnet" "agent" {
  count        = length(var.agent_nodepools)
  network_id   = hcloud_network.k3s.id
  type         = "cloud"
  network_zone = var.network_region
  ip_range     = local.network_ipv4_subnets[count.index]
}

resource "hcloud_firewall" "k3s" {
  name   = var.cluster_name
  labels = local.labels

  dynamic "rule" {
    for_each = local.firewall_rules_list
    content {
      direction       = rule.value.direction
      protocol        = rule.value.protocol
      port            = lookup(rule.value, "port", null)
      destination_ips = lookup(rule.value, "destination_ips", [])
      source_ips      = lookup(rule.value, "source_ips", [])
    }
  }
}

resource "hcloud_placement_group" "control_plane" {
  count  = ceil(local.control_plane_count / 10)
  name   = "${var.cluster_name}-control-plane-${count.index + 1}"
  labels = local.labels
  type   = "spread"
}

resource "hcloud_placement_group" "agent" {
  count  = ceil(local.agent_count / 10)
  name   = "${var.cluster_name}-agent-${count.index + 1}"
  labels = local.labels
  type   = "spread"
}

resource "null_resource" "destroy_cluster_loadbalancer" {

  # this only gets triggered before total destruction of the cluster, but when the necessary elements to run the commands are still available
  triggers = {
    kustomization_id = null_resource.kustomization.id
    cluster_name     = var.cluster_name
  }

  depends_on = [
    null_resource.control_planes[0],
    hcloud_network_subnet.control_plane,
    hcloud_network_subnet.agent,
    hcloud_placement_group.control_plane,
    hcloud_placement_group.agent,
    hcloud_network.k3s,
    hcloud_firewall.k3s,
    hcloud_ssh_key.k3s
  ]
}
