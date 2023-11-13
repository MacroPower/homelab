// jsonnet base/chronyd/main.jsonnet -J vendor

local ns = import 'namespace.libsonnet';
local config = import 'config/main.libsonnet';
local netPolicy = std.parseYaml(importstr 'network-policy.yaml');

[ns] + config + netPolicy
