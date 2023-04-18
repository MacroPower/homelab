// jsonnet base/fluent-bit/main.jsonnet -J vendor

[
  import 'namespace.libsonnet',
  std.parseYaml(importstr 'service-monitor.yaml'),
  std.parseYaml(importstr 'secrets.yaml'),
]
