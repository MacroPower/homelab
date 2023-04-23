[
  import 'namespace.libsonnet',
  std.parseYaml(importstr 'init-job.yaml'),
  std.parseYaml(importstr 'init-scripts.yaml'),
  std.parseYaml(importstr 'secrets.yaml'),
]
