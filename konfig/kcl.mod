[package]
name = "konfig"
edition = "v0.11.1"
version = "0.0.1"

[dependencies]
helm = { oci = "oci://ghcr.io/macropower/kclipper/helm", tag = "0.10.0" }
cilium = "0.4.1"
k8s = "1.31.2"
