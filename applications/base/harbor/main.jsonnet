// jsonnet base/harbor/main.jsonnet -J vendor

local ns = import 'namespace.libsonnet';
local bucket = std.parseYaml(importstr 'bucket.yaml');
local secrets = std.parseYaml(importstr 'secrets.yaml');

[ns] + bucket + secrets
