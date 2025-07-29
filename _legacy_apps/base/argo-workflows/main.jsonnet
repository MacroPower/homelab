// jsonnet base/argo-workflows/main.jsonnet -J vendor

local ns = import 'namespace.libsonnet';
local auth = std.parseYaml(importstr 'auth.yaml');
local ingress = import 'ingress.libsonnet';
local roles = import 'roles/main.libsonnet';

[ns] + auth + ingress + roles
