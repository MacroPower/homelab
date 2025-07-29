local ingress = import 'ingress.libsonnet';
local ns = import 'namespace.libsonnet';

[ns] + ingress
