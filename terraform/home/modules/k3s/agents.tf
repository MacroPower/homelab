module "agents" {
  source = "./modules/host"

  for_each = local.agent_nodes

  name                         = "${var.use_cluster_name_in_node_name ? "${var.cluster_name}-" : ""}${each.value.nodepool_name}"
  ipv4_address                 = each.value.ipv4_address
  os_device                    = each.value.os_device
  network_interface            = each.value.network_interface
  ssh_port                     = var.ssh_port
  ssh_public_key               = var.ssh_public_key
  ssh_private_key              = var.ssh_private_key
  ssh_additional_public_keys   = var.ssh_additional_public_keys
  packages_to_install          = local.packages_to_install
  dns_servers                  = var.dns_servers
  k3s_registries               = var.k3s_registries
  k3s_registries_update_script = local.k3s_registries_update_script
  opensuse_microos_mirror_link = var.opensuse_microos_mirror_link

  automatically_upgrade_os = var.automatically_upgrade_os
}

resource "null_resource" "agents" {
  for_each = local.agent_nodes

  triggers = {
    agent_id = module.agents[each.key].id
  }

  connection {
    user           = "root"
    private_key    = var.ssh_private_key
    agent_identity = local.ssh_agent_identity
    host           = module.agents[each.key].ipv4_address
    port           = var.ssh_port
  }

  # Generating k3s agent config file
  provisioner "file" {
    content = yamlencode({
      node-name     = module.agents[each.key].name
      server        = "https://${module.control_planes[keys(module.control_planes)[0]].private_ipv4_address}:6443"
      token         = random_password.k3s_token.result
      kubelet-arg   = local.kubelet_arg
      flannel-iface = module.agents[each.key].network_interface
      node-ip       = module.agents[each.key].private_ipv4_address
      node-label    = each.value.labels
      node-taint    = each.value.taints
    })
    destination = "/tmp/config.yaml"
  }

  # Install k3s agent
  provisioner "remote-exec" {
    inline = local.install_k3s_agent
  }

  # Start the k3s agent and wait for it to have started
  provisioner "remote-exec" {
    inline = [
      "systemctl start k3s-agent 2> /dev/null",
      <<-EOT
      timeout 120 bash <<EOF
        until systemctl status k3s-agent > /dev/null; do
          systemctl start k3s-agent 2> /dev/null
          echo "Waiting for the k3s agent to start..."
          sleep 2
        done
      EOF
      EOT
    ]
  }

  depends_on = [
    null_resource.first_control_plane,
  ]
}
