resource "random_string" "server" {
  length  = 3
  lower   = true
  special = false
  numeric = false
  upper   = false

  keepers = {
    # We re-create the apart of the name changes.
    name = var.name
  }
}

locals {
  # ssh_agent_identity is not set if the private key is passed directly, but if ssh agent is used, the public key tells ssh agent which private key to use.
  # For terraforms provisioner.connection.agent_identity, we need the public key as a string.
  ssh_agent_identity = var.ssh_private_key == null ? var.ssh_public_key : null
  # shared flags for ssh to ignore host keys for all connections during provisioning.
  ssh_args = "-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o IdentitiesOnly=yes"

  # ssh_client_identity is used for ssh "-i" flag, its the private key if that is set, or a public key
  # if an ssh agent is used.
  ssh_client_identity = var.ssh_private_key == null ? var.ssh_public_key : var.ssh_private_key

  # Final list of packages to install
  needed_packages = join(" ", concat(["k3s-selinux"], var.packages_to_install))

  # the hosts name with its unique suffix attached
  name = "${var.name}-${random_string.server.id}"

  cloudinit_config = templatefile(
    "${path.module}/templates/cloud.cfg.tpl",
    {}
  )

  cloudinit_userdata_config = templatefile(
    "${path.module}/templates/userdata.yaml.tpl",
    {
      hostname          = local.name
      sshPort           = var.ssh_port
      sshAuthorizedKeys = concat([var.ssh_public_key], var.ssh_additional_public_keys)
      dnsServers        = var.dns_servers
      networkInterface  = var.network_interface
    }
  )
}

resource "null_resource" "k3s_host" {
  lifecycle {
    create_before_destroy = true
  }

  connection {
    user           = "root"
    private_key    = var.ssh_private_key
    agent_identity = local.ssh_agent_identity
    host           = var.ipv4_address
    port           = var.ssh_port
  }

  provisioner "remote-exec" {
    inline = [<<-EOT
      set -ex

      transactional-update shell <<<"
zypper remove -y busybox-hostname ; \
zypper --gpg-auto-import-keys install -y \
    cloud-init k3s-selinux && \
zypper --gpg-auto-import-keys install -y --no-recommends \
    patterns-microos-base patterns-microos-base-zypper patterns-microos-basesystem patterns-microos-defaults patterns-containers-container_runtime && \
systemctl enable cloud-init-local.service && \
systemctl enable cloud-init.service && \
systemctl enable cloud-config.service && \
systemctl enable cloud-final.service && \
ls -l /etc/cloud/cloud.cfg.d && \
{ tee /etc/cloud/cloud.cfg << EOFCLOUDCFG
${replace(local.cloudinit_config, "\"", "\\\"")}
EOFCLOUDCFG
} && \
{ tee /etc/cloud/cloud.cfg.d/init.cfg << EOFCLOUDUSERDATA
${replace(local.cloudinit_userdata_config, "\"", "\\\"")}
EOFCLOUDUSERDATA
} && \
cloud-init init --local
      "

      sleep 1 && udevadm settle
      EOT
    ]
  }

  # Enable open-iscsi
  provisioner "remote-exec" {
    inline = [<<-EOT
      set -ex
      if [[ $(systemctl list-units --all -t service --full --no-legend "iscsid.service" | sed 's/^\s*//g' | cut -f1 -d' ') == iscsid.service ]]; then
        systemctl enable --now iscsid
      fi
      EOT
    ]
  }

  provisioner "remote-exec" {
    inline = var.automatically_upgrade_os ? [<<-EOT
      echo "Automatic OS updates are enabled"
      EOT
      ] : [
      <<-EOT
      echo "Automatic OS updates are disabled"
      systemctl --now disable transactional-update.timer
      EOT
    ]
  }

  provisioner "remote-exec" {
    connection {
      user           = "root"
      private_key    = var.ssh_private_key
      agent_identity = local.ssh_agent_identity
      host           = var.ipv4_address
      port           = var.ssh_port

      allow_missing_exit_status = true
    }

    inline = [
      "reboot"
    ]
  }
}

resource "time_sleep" "wait_60_seconds" {
  depends_on = [null_resource.k3s_host]

  create_duration = "60s"
}

resource "null_resource" "k3s_host_verify" {
  depends_on = [time_sleep.wait_60_seconds]

  triggers = {
    always_run = "${timestamp()}"
  }

  connection {
    user           = "root"
    private_key    = var.ssh_private_key
    agent_identity = local.ssh_agent_identity
    host           = var.ipv4_address
    port           = var.ssh_port
  }

  provisioner "remote-exec" {
    inline = [
      "echo \"Hello world!\""
    ]
  }
}
