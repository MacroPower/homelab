// jsonnet base/grafana/main.jsonnet -J vendor --ext-str ingressAnnotations='{}' --ext-str ingressHost=''

[
  import 'namespace.libsonnet',
  import 'ingress.libsonnet',
  std.parseYaml(importstr 'secrets.yaml'),
  std.parseYaml(importstr 'datasources/grafana-cloud.yaml'),
  std.parseYaml(importstr 'datasources/grafana-cloud-secrets.yaml'),
] + import 'dashboards.libsonnet'
