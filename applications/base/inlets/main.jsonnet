[
  import 'namespace.libsonnet',
  std.parseYaml(importstr 'secrets.yaml'),
] + std.parseYaml(importstr 'issuer.yaml')
