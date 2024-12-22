[package]
name = "konfig"
edition = "v0.10.10"
version = "0.0.1"

[dependencies]
argo-cd = "0.2.1"
cert-manager = "0.3.0"
cilium = "0.4.1"
crossplane = "1.17.3"
crossplane-provider-sql = { path = "vendor/crossplane-provider-sql" }
crossplane-provider-terraform = "0.10.2"
external-secrets = "0.1.4"
grafana-operator = "0.1.1"
helm = { oci = "oci://ghcr.io/macropower/kclx/helm", tag = "0.1.0" }
k8s = "1.31.2"
opentelemetry-operator = "0.1.1"
prometheus-operator = "0.1.1"
secure-code-box = "0.2.1"
traefik = "0.2.1"
