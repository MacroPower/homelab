[package]
name = "kube_openebs_mgmt"
version = "0.1.0"

[dependencies]
kube_openebs_base = { path = "../base" }

[profile]
entries = ["main.k", "${konfig:KCL_MOD}/models/render/render.k"]
