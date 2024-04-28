// jsonnet base/wireguard/main.jsonnet -J vendor

local ns = import 'namespace.libsonnet';
local netPolicy = std.parseYaml(importstr 'network-policy.yaml');

[ns] + netPolicy
