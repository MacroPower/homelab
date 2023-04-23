[
  import 'namespace.libsonnet',
  std.parseYaml(importstr 'init-scripts.yaml'),
  std.parseYaml(importstr 'secrets.yaml'),
  std.parseYaml(importstr 'config.yaml'),
  std.parseYaml(importstr 'init-scripts-secrets.yaml'),
  std.parseYaml(importstr 'config-secrets.yaml'),
]
