// jsonnet base/inlets-server/main.jsonnet -J vendor --ext-str ingressAnnotations='{}' --ext-str ingressHost=''

local cert = import 'cert.libsonnet';
local ingress = import 'ingress.libsonnet';
local ns = import 'namespace.libsonnet';
local secrets = std.parseYaml(importstr 'secrets.yaml');
local issuer = std.parseYaml(importstr 'issuer.yaml');

[ns] + cert + ingress + [secrets] + issuer
