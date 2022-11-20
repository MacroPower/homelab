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

resource "random_string" "identity_file" {
  length  = 20
  lower   = true
  special = false
  numeric = true
  upper   = false
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

  # Prepare ssh identity file
  provisioner "local-exec" {
    command = <<-EOT
      install -b -m 600 /dev/null /tmp/${random_string.identity_file.id}
      echo "${local.ssh_client_identity}" > /tmp/${random_string.identity_file.id}
    EOT
  }

  # Install MicroOS
  provisioner "remote-exec" {
    connection {
      user           = "root"
      private_key    = var.ssh_private_key
      agent_identity = local.ssh_agent_identity
      host           = var.ipv4_address

      # We cannot use different ports here as this runs inside Hetzner Rescue image and thus uses the
      # standard 22 TCP port.
      port = 22
    }

    inline = [
      "set -ex",
      "wget --timeout=5 --waitretry=5 --tries=5 --retry-connrefused --inet4-only https://ftp.gwdg.de/pub/opensuse/repositories/devel:/kubic:/images/openSUSE_Tumbleweed/openSUSE-MicroOS.x86_64-OpenStack-Cloud.qcow2",
      "apt-get install -y libguestfs-tools",
      "mkdir -p /mnt/disk",
      "guestmount -a $(ls -a | grep -ie '^opensuse.*microos.*qcow2$') -m \"/dev/sda3:/:subvol=@/root\" --rw /mnt/disk",
      "mkdir -p /mnt/disk/.ssh",
      "chmod 700 /mnt/disk/.ssh",
      "echo \"${var.ssh_public_key}\" | tee /mnt/disk/.ssh/authorized_keys",
      "chmod 600 /mnt/disk/.ssh/authorized_keys",
      "guestunmount /mnt/disk",
      "sleep 3",
      "qemu-img convert -p -f qcow2 -O host_device $(ls -a | grep -ie '^opensuse.*microos.*qcow2$') ${var.os_device}",
    ]
  }

  # Issue a reboot command.
  provisioner "local-exec" {
    command = <<-EOT
      ssh ${local.ssh_args} -i /tmp/${random_string.identity_file.id} root@${var.ipv4_address} '(sleep 2; reboot)&'; sleep 3
    EOT
  }

  # Wait for MicroOS to reboot and be ready.
  provisioner "local-exec" {
    command = <<-EOT
      until ssh ${local.ssh_args} -i /tmp/${random_string.identity_file.id} -o ConnectTimeout=2 root@${var.ipv4_address} true 2> /dev/null
      do
        echo "Waiting for MicroOS to reboot and become available..."
        sleep 3
      done
    EOT
  }

  provisioner "remote-exec" {
    connection {
      user           = "root"
      private_key    = var.ssh_private_key
      agent_identity = local.ssh_agent_identity
      host           = var.ipv4_address

      # We cannot use different ports here as this is pre cloud-init and thus uses the
      # standard 22 TCP port.
      port = 22
    }

    inline = [<<-EOT
      set -ex

      transactional-update shell <<<"
zypper --gpg-auto-import-keys install -y k3s-selinux && \
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

  # Issue a reboot command.
  provisioner "local-exec" {
    command = <<-EOT
      ssh ${local.ssh_args} -i /tmp/${random_string.identity_file.id} root@${var.ipv4_address} '(sleep 3; reboot)&'; sleep 3
    EOT
  }

  # Wait for MicroOS to reboot and be ready
  provisioner "local-exec" {
    command = <<-EOT
      until ssh ${local.ssh_args} -i /tmp/${random_string.identity_file.id} -o ConnectTimeout=2 -p ${var.ssh_port} root@${var.ipv4_address} true 2> /dev/null
      do
        echo "Waiting for MicroOS to reboot and become available..."
        sleep 3
      done
    EOT
  }

  # Cleanup ssh identity file
  provisioner "local-exec" {
    command = <<-EOT
      rm /tmp/${random_string.identity_file.id}
    EOT
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
}
