data "hcloud_servers" "agents" {
  with_selector = "role=agent_node"
}

resource "hcloud_floating_ip" "agent_ip" {
  type      = "ipv4"
  server_id = data.hcloud_servers.agents.servers[0].id
}

resource "random_string" "identity_file" {
  length  = 20
  lower   = true
  special = false
  numeric = true
  upper   = false
}

locals {
  node_sum = length(flatten([for i in var.nodepools: range(i["count"])]))
}

resource "null_resource" "agent_floating_ip" {
  count = local.node_sum

  triggers = {
    agent_id = data.hcloud_servers.agents.servers[count.index].name
  }

  connection {
    user           = "root"
    private_key    = var.ssh_private_key
    agent_identity = var.ssh_public_key
    host           = data.hcloud_servers.agents.servers[count.index].ipv4_address
    port           = var.ssh_port
  }

  provisioner "remote-exec" {
    inline = [
      "echo \"Adding ${hcloud_floating_ip.agent_ip.ip_address}\"",
      "ip addr del ${hcloud_floating_ip.agent_ip.ip_address} dev eth0 || echo \"This is fine...\"",
      "ip addr add ${hcloud_floating_ip.agent_ip.ip_address} dev eth0",
    ]
  }
}
