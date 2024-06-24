module "nas01_k3s" {
  source = "./modules/truenas-k3s"

  fqdn = var.nas01_fqdn
  ipv4 = var.nas01_ipv4

  ssh_password = data.doppler_secrets.tf_main_home.map.NAS01_SSH_PASSWORD

  argocd_kustomization      = abspath("../../hack/extra/argocd")
  argocd_apps_kustomization = abspath("../../hack/extra/argocd-apps")
  doppler_kustomization     = abspath("../../hack/extra/doppler")

  doppler_secrets_tpl_doppler_token = data.doppler_secrets.tf_main_home.map.NAS01_DOPPLER_TOKEN
}

output "kubeconfig" {
  sensitive = true
  value     = module.nas01_k3s.kubeconfig
}
