// jsonnet base/grafana/main.jsonnet -J vendor --ext-str ingressAnnotations='{}' --ext-str ingressHost=''

local ns = import 'namespace.libsonnet';
local grafana = std.parseYaml(importstr 'grafana.yaml');
local ingress = import 'ingress.libsonnet';
local secrets = import 'secrets.libsonnet';
local dashboards = import 'dashboards/main.libsonnet';
local datasources = import 'datasources/main.libsonnet';
local provisioning = std.parseYaml(importstr 'configmap-provisioning.yaml');

[ns] +
grafana +
ingress +
secrets +
dashboards +
datasources +
provisioning
