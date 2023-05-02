// jsonnet base/grafana/main.jsonnet -J vendor --ext-str ingressAnnotations='{}' --ext-str ingressHost=''

local ingress = import 'ingress.libsonnet';
local ns = import 'namespace.libsonnet';
local secrets = std.parseYaml(importstr 'secrets.yaml');
local ds_grafana_cloud = std.parseYaml(importstr 'datasources/grafana-cloud.yaml');
local ds_grafana_cloud_secrets = std.parseYaml(importstr 'datasources/grafana-cloud-secrets.yaml');
local dashboards = import 'dashboards.libsonnet';

ingress +
[ns] +
[secrets] +
[ds_grafana_cloud] +
[ds_grafana_cloud_secrets] +
dashboards
