[package]
name = "home_hass"
version = "0.1.0"

[dependencies]
haconfig = { path = "../../haconfig" }

[profile]
entries = ["*.k", "${haconfig:KCL_MOD}/models/render/render.k"]
