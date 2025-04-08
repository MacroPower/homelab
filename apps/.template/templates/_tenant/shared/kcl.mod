[package]
name = "{{.TenantName}}"
version = "0.1.0"

[dependencies]
{{.TenantName}}_tenant = { path = "../base" }

[profile]
entries = ["main.k", "${konfig:KCL_MOD}/models/render/render.k"]
