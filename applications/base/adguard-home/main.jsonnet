// jsonnet base/adguard-home/main.jsonnet -J vendor

local ns = import 'namespace.libsonnet';
local ingress = import 'ingress.libsonnet';
local config = import 'config.libsonnet';
local certs = std.parseYaml(importstr 'certs.yaml');
local netPolicy = std.parseYaml(importstr 'network-policy.yaml');

[ns] + ingress + config + certs + netPolicy
