resource "random_password" "k3s_token" {
  length  = 48
  special = false
}

resource "null_resource" "destroy_cluster_loadbalancer" {

  # this only gets triggered before total destruction of the cluster, but when the necessary elements to run the commands are still available
  triggers = {
    kustomization_id = null_resource.kustomization.id
    cluster_name     = var.cluster_name
  }

  depends_on = [
    null_resource.control_planes[0],
  ]
}
