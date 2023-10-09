// jsonnet base/adguard-home/main.jsonnet -J vendor

local ns = import 'namespace.libsonnet';
local ingress = import 'ingress.libsonnet';
local config = import 'config.libsonnet';

[ns] + ingress + config
