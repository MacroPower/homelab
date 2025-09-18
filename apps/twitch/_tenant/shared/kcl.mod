[package]
name = "twitch"
version = "0.1.0"

[dependencies]
twitch_tenant = { path = "../base" }

[profile]
entries = ["main.k", "${konfig:KCL_MOD}/models/render/render.k"]
