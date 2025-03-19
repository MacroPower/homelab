[package]
name = "{{.TenantName}}_{{.AppName}}_mgmt"
version = "0.1.0"

[dependencies]
{{.TenantName}}_{{.AppName}}_base = { path = "../base" }

[profile]
entries = ["main.k", "${konfig:KCL_MOD}/models/render/render.k"]
