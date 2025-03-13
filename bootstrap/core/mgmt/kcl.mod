[package]
name = "bootstrap_core_mgmt"
version = "0.1.0"

[dependencies]
bootstrap = { path = "../base" }
kube_csr_approver = { path = "../../../apps/kube/csr-approver/mgmt" }
cilium_system = { path = "../../../apps/cilium/system/mgmt" }
argo_cd = { path = "../../../apps/argo/cd/base" }

[profile]
entries = ["main.k", "${konfig:KCL_MOD}/models/render/render.k"]
