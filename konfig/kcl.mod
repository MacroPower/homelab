[package]
name = "konfig"
edition = "v0.9.3"
version = "0.0.1"

[dependencies]
argo-cd = "0.1.1"
cert-manager = "0.1.2"
cilium = { path = "vendor/cilium" }
crossplane = "1.15.2"
crossplane-provider-terraform = "0.10.0"
external-secrets = "0.1.0"
grafana-operator = "0.1.0"
k8s = "1.28"
opentelemetry-operator = "0.0.2"
prometheus-operator = "0.0.1"
secure-code-box = "0.1.0"
traefik = "0.1.1"

