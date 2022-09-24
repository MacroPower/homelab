variable "apiserver_url" {
  type      = string
  sensitive = true
}

variable "client_certificate_data" {
  type      = string
  sensitive = true
}

variable "client_key_data" {
  type      = string
  sensitive = true
}

variable "certificate_authority_data" {
  type      = string
  sensitive = true
}

provider "kubernetes" {
  host                   = var.apiserver_url
  client_certificate     = var.client_certificate_data
  client_key             = var.client_key_data
  cluster_ca_certificate = var.certificate_authority_data
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
