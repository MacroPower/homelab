[package]
name = "twitch_channel_points_miner_local"
version = "0.1.0"

[dependencies]
twitch_channel_points_miner_base = { path = "../base" }
cluster = { path = "../../../../clusters/local" }

[profile]
entries = ["main.k", "${konfig:KCL_MOD}/models/render/render.k"]
