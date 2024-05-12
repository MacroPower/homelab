// jsonnet base/cilium/main.jsonnet -J vendor

local policies = import 'policies/main.libsonnet';
local ingress = import 'ingress.libsonnet';

policies
+ ingress
