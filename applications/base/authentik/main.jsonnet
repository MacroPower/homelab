// jsonnet base/authentik/main.jsonnet -J vendor --ext-str ingressAnnotations='{}' --ext-str ingressHost=''

local ingress = import 'ingress.libsonnet';
local ns = import 'namespace.libsonnet';
local secrets = std.parseYaml(importstr 'secrets.yaml');
local tf = import 'terraform/terraform.libsonnet';

[ns] + ingress + secrets + tf
