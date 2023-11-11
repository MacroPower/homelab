// jsonnet base/odigos/main.jsonnet -J vendor

local ns = import 'namespace.libsonnet';
local ingress = import 'ingress.libsonnet';
local config = std.parseYaml(importstr 'config.yaml');

[ns] + ingress + config
