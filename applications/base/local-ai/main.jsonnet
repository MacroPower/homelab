// jsonnet base/local-ai/main.jsonnet -J vendor --ext-str ingressAnnotations='{}' --ext-str ingressSuffix=''

local ingress = import 'ingress.libsonnet';
local ns = import 'namespace.libsonnet';
local ui = import 'ui.libsonnet';

[ns] + ui + ingress
