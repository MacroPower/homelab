// jsonnet base/goldilocks/main.jsonnet -J vendor --ext-str ingressAnnotations='{}' --ext-str ingressHost=''

[
  import 'namespace.libsonnet',
  import 'ingress.libsonnet',
]
