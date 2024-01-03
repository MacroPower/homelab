// jsonnet base/cilium/main.jsonnet -J vendor

local collector = std.parseYaml(importstr 'collector.yaml');
local policies = import 'policies/main.libsonnet';
local spire = import 'spire/main.libsonnet';
local ingress = import 'ingress.libsonnet';

collector
+ policies
+ spire
+ ingress
