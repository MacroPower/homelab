output "kubeconfig" {
  description = "Kubeconfig file content with external IP address"
  value       = module.kube-hetzner.kubeconfig
  sensitive   = true
}

output "kubeconfig_data" {
  description = "Structured kubeconfig data to supply to other providers"
  value       = module.kube-hetzner.kubeconfig_data
  sensitive   = true
}
