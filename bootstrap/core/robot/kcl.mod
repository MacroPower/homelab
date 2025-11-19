[package]
name = "bootstrap_core_robot"
version = "0.1.0"

[dependencies]
bootstrap = { path = "../base" }
kube_csr_approver = { path = "../../../apps/kube/csr-approver/robot" }
cilium_system = { path = "../../../apps/cilium/system/robot" }

[profile]
entries = ["main.k", "${konfig:KCL_MOD}/models/render/render.k"]
