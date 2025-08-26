[package]
name = "kube_csr_approver_main"
version = "0.1.0"

[dependencies]
kube_csr_approver_base = { path = "../base" }

[profile]
entries = ["main.k", "${konfig:KCL_MOD}/models/render/render.k"]
