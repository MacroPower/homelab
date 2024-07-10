// jsonnet base/liqo/main.jsonnet -J vendor

local ns = import 'namespace.libsonnet';
local ingress = import 'ingress.libsonnet';
local dashboards = std.parseYaml(importstr 'dashboards.yaml');

[ns] + ingress + dashboards
