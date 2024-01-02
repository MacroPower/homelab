resource "unifi_user" "clients" {
  for_each = var.clients

  mac  = each.value.mac
  name = each.key
  note = "Managed by Terraform"

  fixed_ip         = lookup(each.value, "ipv4", null)
  network_id       = lookup(each.value, "vlan", null)
  local_dns_record = lookup(each.value, "ipv4", null) != null ? format("%s.%s", each.key, var.domain_name) : null
  dev_id_override  = lookup(each.value, "dev_id", null)
}
