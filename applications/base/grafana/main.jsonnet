// jsonnet base/grafana/main.jsonnet -J vendor --ext-str ingressAnnotations='{}' --ext-str ingressHost=''

local ingress = import 'ingress.libsonnet';
local ns = import 'namespace.libsonnet';
local secrets = std.parseYaml(importstr 'secrets.yaml');
local dashboards = import 'dashboards.libsonnet';
local datasources = import 'datasources.libsonnet';

ingress +
[ns] +
[secrets] +
dashboards +
datasources
