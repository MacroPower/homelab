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

  # Important when issuing terraform destroy, otherwise the LB will not let the network get deleted
  provisioner "local-exec" {
    when       = destroy
    command    = "kubectl -n kube-system delete service traefik --kubeconfig kubeconfig.yaml"
    on_failure = continue
  }

  depends_on = [
    null_resource.control_planes[0],
  ]
}
