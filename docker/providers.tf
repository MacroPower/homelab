provider "docker" {
  host  = "ssh://${var.docker_user}@${var.docker_compute_node_1}:22"
  alias = "compute_1"
}
