[
  import 'namespace.libsonnet',
  std.parseYaml(importstr 'sa-token.yaml'),
] + import 'ingress.libsonnet'
