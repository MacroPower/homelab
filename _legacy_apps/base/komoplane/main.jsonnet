// jsonnet base/komoplane/main.jsonnet -J vendor

local ns = import 'namespace.libsonnet';
local ingress = import 'ingress.libsonnet';

[ns] + ingress
