// jsonnet base/securecodebox/main.jsonnet -J vendor

local ns = import 'namespace.libsonnet';
local bucket = std.parseYaml(importstr 'bucket.yaml');
local patchDeployment = std.parseYaml(importstr 'patch-deployment.yaml');

[ns] + bucket + patchDeployment
