// jsonnet base/securecodebox/main.jsonnet -J vendor

local ns = import 'namespace.libsonnet';
local bucket = std.parseYaml(importstr 'bucket.yaml');

[ns] + bucket
