variable "name" {
  type = string
}

variable "ipv4" {
  type = string
}

variable "ssh_password" {
  type = string
}

variable "argocd_kustomization" {
  type = string
}

variable "argocd_apps_kustomization" {
  type = string
}

variable "doppler_kustomization" {
  type = string
}

variable "doppler_secrets_tpl_doppler_token" {
  type      = string
  sensitive = true
}
