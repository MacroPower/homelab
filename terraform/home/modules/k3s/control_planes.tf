module "control_planes" {
  source = "./modules/host"

  for_each = local.control_plane_nodes

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

resource "null_resource" "control_planes" {
  for_each = local.control_plane_nodes

  triggers = {
    control_plane_id = module.control_planes[each.key].id
  }

  connection {
    user           = "root"
    private_key    = var.ssh_private_key
    agent_identity = local.ssh_agent_identity
    host           = module.control_planes[each.key].ipv4_address
    port           = var.ssh_port
  }

  # Generating k3s server config file
  provisioner "file" {
    content = yamlencode(
      merge(
        {
          node-name = module.control_planes[each.key].name
          server = length(module.control_planes) == 1 ? null : "https://${
            module.control_planes[each.key].private_ipv4_address == module.control_planes[keys(module.control_planes)[0]].private_ipv4_address ?
            module.control_planes[keys(module.control_planes)[1]].private_ipv4_address :
          module.control_planes[keys(module.control_planes)[0]].private_ipv4_address}:6443"
          token                       = random_password.k3s_token.result
          disable-cloud-controller    = true
          disable                     = local.disable_extras
          kubelet-arg                 = local.kubelet_arg
          kube-controller-manager-arg = local.kube_controller_manager_arg
          flannel-iface               = module.control_planes[each.key].network_interface
          node-ip                     = module.control_planes[each.key].private_ipv4_address
          advertise-address           = module.control_planes[each.key].private_ipv4_address
          node-label                  = each.value.labels
          node-taint                  = each.value.taints
          write-kubeconfig-mode       = "0644" # needed for import into rancher
        },
        lookup(local.cni_k3s_settings, var.cni_plugin, {}),
        {
          tls-san = concat([
            module.control_planes[each.key].ipv4_address
          ], var.additional_tls_sans)
        },
        local.etcd_s3_snapshots,
        var.control_planes_custom_config
      )
    )

    destination = "/tmp/config.yaml"
  }

  # Install k3s server
  provisioner "remote-exec" {
    inline = local.install_k3s_server
  }

  # Start the k3s server and wait for it to have started correctly
  provisioner "remote-exec" {
    inline = [
      "systemctl start k3s 2> /dev/null",
      <<-EOT
      timeout 120 bash <<EOF
        until systemctl status k3s > /dev/null; do
          systemctl start k3s 2> /dev/null
          echo "Waiting for the k3s server to start..."
          sleep 3
        done
      EOF
      EOT
    ]
  }

  depends_on = [
    null_resource.first_control_plane,
  ]
}
