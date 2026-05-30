[package]
name = "bootstrap_core_local"
version = "0.1.0"

[dependencies]
bootstrap = { path = "../base" }
kube_csr_approver = { path = "../../../apps/kube/csr-approver/local" }
cilium_system_local = { path = "../../../apps/cilium/system/local" }
argo_cd = { path = "../../../apps/argo/cd/local" }

[profile]
entries = ["main.k", "${konfig:KCL_MOD}/models/render/render.k"]
