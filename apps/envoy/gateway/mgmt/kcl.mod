[package]
name = "envoy_gateway_mgmt"
version = "0.1.0"

[dependencies]
envoy_gateway_base = { path = "../base" }
cluster = { path = "../../../../clusters/mgmt" }

[profile]
entries = ["main.k", "${konfig:KCL_MOD}/models/render/render.k"]
