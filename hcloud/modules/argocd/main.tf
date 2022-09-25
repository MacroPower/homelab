resource "kubectl_manifest" "argocd_namespace" {
    yaml_body = <<YAML
apiVersion: v1
kind: Namespace
metadata:
  name: argocd
YAML
}

locals {
  install_split_doc  = split("---", file("${path.module}/install/install.yaml"))
  install_valid_yaml = [for doc in local.install_split_doc : doc if try(yamldecode(doc).metadata.name, "") != ""]

  install_dict = {
    for doc in toset(local.install_valid_yaml) :
      "${yamldecode(doc).kind}-${yamldecode(doc).metadata.name}" => doc
  }
}

resource "kubectl_manifest" "argocd" {
  for_each  = local.install_dict
  yaml_body = each.value
}
