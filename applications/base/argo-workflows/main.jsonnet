// jsonnet base/argo-workflows/main.jsonnet -J vendor

local ns = import 'namespace.libsonnet';
local ingress = import 'ingress.libsonnet';
local auth = import 'auth/main.libsonnet';

[ns] + ingress + auth
