// jsonnet base/policy-reporter/main.jsonnet -J vendor

local ns = import 'namespace.libsonnet';
local ingress = import 'ingress.libsonnet';

[ns] + ingress
