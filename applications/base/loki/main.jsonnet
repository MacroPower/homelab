// jsonnet base/loki/main.jsonnet -J vendor

local ns = import 'namespace.libsonnet';
local bucket = std.parseYaml(importstr 'bucket.yaml');
local rules = import 'rules/rules.libsonnet';

[ns] + bucket + rules
