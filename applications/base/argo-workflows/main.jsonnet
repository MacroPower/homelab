// jsonnet base/argo-workflows/main.jsonnet -J vendor

local ns = import 'namespace.libsonnet';
local ingress = import 'ingress.libsonnet';

[ns] + ingress
