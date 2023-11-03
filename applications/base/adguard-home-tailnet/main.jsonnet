// jsonnet base/adguard-home-tailnet/main.jsonnet -J vendor

local ns = import 'namespace.libsonnet';
local ingress = import 'ingress.libsonnet';
local config = import 'config.libsonnet';
local certs = std.parseYaml(importstr 'certs.yaml');

[ns] + ingress + config + certs
