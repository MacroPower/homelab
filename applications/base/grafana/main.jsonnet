// jsonnet base/grafana/main.jsonnet -J vendor --ext-str ingressAnnotations='{}' --ext-str ingressHost=''

local database = import 'database/main.libsonnet';
local grafana = std.parseYaml(importstr 'grafana.yaml');
local auth = import 'auth/main.libsonnet';
local ingress = import 'ingress.libsonnet';
local secrets = import 'secrets.libsonnet';
local dashboards = import 'dashboards/main.libsonnet';
local datasources = import 'datasources/main.libsonnet';
local provisioning = std.parseYaml(importstr 'configmap-provisioning.yaml');

database +
grafana +
auth +
ingress +
secrets +
dashboards +
datasources +
provisioning
