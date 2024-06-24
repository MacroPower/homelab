locals {
  manifests_dir   = "/tmp/manifests"
  argocd_dir      = "${local.manifests_dir}/argocd/"
  argocd_apps_dir = "${local.manifests_dir}/argocd-apps/"
  doppler_dir     = "${local.manifests_dir}/doppler/"

  environment_name = split(".", var.fqdn)[0]

  argocd_apps_apps_tpl_base_filename = "apps.yaml"
  doppler_secrets_tpl_base_filename  = "secrets.yaml"

  k_cmd = "k3s kubectl"
}

resource "null_resource" "truenas_k3s_bootstrap" {
  connection {
    type     = "ssh"
    host     = var.ipv4
    port     = 22
    user     = "root"
    password = var.ssh_password
  }

  provisioner "remote-exec" {
    inline = [
      "rm -rf ${local.manifests_dir}",
      "mkdir ${local.manifests_dir}",
    ]
  }

  provisioner "file" {
    source      = var.argocd_kustomization
    destination = local.argocd_dir
  }

  provisioner "file" {
    source      = var.argocd_apps_kustomization
    destination = local.argocd_apps_dir
  }

  provisioner "file" {
    source      = var.doppler_kustomization
    destination = local.doppler_dir
  }

  provisioner "file" {
    content = templatefile("${var.argocd_apps_kustomization}/${local.argocd_apps_apps_tpl_base_filename}.tpl", {
      environment_name = local.environment_name
    })
    destination = "${local.argocd_apps_dir}${local.argocd_apps_apps_tpl_base_filename}"
  }

  provisioner "file" {
    content = templatefile("${var.doppler_kustomization}/${local.doppler_secrets_tpl_base_filename}.tpl", {
      doppler_token = var.doppler_secrets_tpl_doppler_token
    })
    destination = "${local.doppler_dir}${local.doppler_secrets_tpl_base_filename}"
  }

  provisioner "remote-exec" {
    inline = [
      "${local.k_cmd} kustomize --enable-helm ${local.argocd_dir} | ${local.k_cmd} apply -f -",
      "${local.k_cmd} kustomize --enable-helm ${local.argocd_apps_dir} | ${local.k_cmd} apply -f -",
      "${local.k_cmd} kustomize --enable-helm ${local.doppler_dir} | ${local.k_cmd} apply -f -",
      "rm -rf ${local.manifests_dir}",
    ]
  }
}

data "remote_file" "kubeconfig" {
  conn {
    host     = var.ipv4
    port     = 22
    user     = "root"
    password = var.ssh_password
  }
  path = "/etc/rancher/k3s/k3s.yaml"
}

output "kubeconfig" {
  sensitive = true
  value     = replace(replace(data.remote_file.kubeconfig.content, "127.0.0.1", var.fqdn), "/: default\\n/", ": ${local.environment_name}\n")
}
