[
  import 'namespace.libsonnet',
  std.parseYaml(importstr 'sa-token.yaml'),
  std.parseYaml(importstr 'middleware.yaml'),
] + import 'ingress.libsonnet'
