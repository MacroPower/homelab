// jsonnet base/cilium/main.jsonnet -J vendor

local collector = std.parseYaml(importstr 'collector.yaml');
local policies = import 'policies/main.libsonnet';

collector
+ policies
