// jsonnet base/argocd/main.jsonnet -J vendor --ext-str ingressAnnotations='{}' --ext-str ingressHost=''

[
  import 'ingress.libsonnet',
  std.parseYaml(importstr 'limit-range.yaml'),
] + std.parseYaml(importstr 'service-monitor.yaml')
