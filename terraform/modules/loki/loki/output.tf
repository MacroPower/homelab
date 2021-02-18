output "hostname" {
  value = "${docker_container.container.ip_address}:3100"
}
