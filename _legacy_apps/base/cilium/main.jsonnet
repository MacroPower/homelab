// jsonnet base/cilium/main.jsonnet -J vendor

local policies = import 'policies/main.libsonnet';
local ingress = import 'ingress.libsonnet';
local vectorSidecar = std.parseYaml(importstr 'vector-sidecar.yaml');
local dashboards = std.parseYaml(importstr 'dashboards.yaml');

policies
+ ingress
+ vectorSidecar
+ dashboards
