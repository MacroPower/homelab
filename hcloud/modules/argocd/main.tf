terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "2.13.1"
    }
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

resource "kubernetes_namespace" "argocd_namespace" {
  metadata {
    name = "argocd"
  }
}

resource "kubernetes_manifest" "argocd_install" {
  depends_on = [
    kubernetes_namespace.argocd_namespace
  ]
  for_each = {
    for value in [
      for yaml in split(
        "\n---\n",
        "\n${replace(file("${path.module}/install/install.yaml"), "/(?m)^---[[:blank:]]*(#.*)?$/", "---")}\n"
      ) :
      yamldecode(yaml)
      if trimspace(replace(yaml, "/(?m)(^[[:blank:]]*(#.*)?$)+/", "")) != ""
    ] : "${value["kind"]}--${value["metadata"]["name"]}" => value
  }
  manifest = each.value
}
