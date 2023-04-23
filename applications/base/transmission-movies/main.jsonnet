[
  import 'namespace.libsonnet',
  std.parseYaml(importstr 'config.yaml'),
  std.parseYaml(importstr 'config-secrets.yaml'),
]
