// jsonnet base/authentik/main.jsonnet -J vendor --ext-str ingressAnnotations='{}' --ext-str ingressHost=''

[
  import 'namespace.libsonnet',
  import 'ingress.libsonnet',
] + std.parseYaml(importstr 'secrets.yaml')
