local k = import '../../../lib/k.libsonnet';

[
  k.core.v1.configMap.new('loki-rules', data={
  }),
]
