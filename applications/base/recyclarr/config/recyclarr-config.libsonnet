local k = import '../../../lib/k.libsonnet';

[
  k.core.v1.configMap.new('recyclarr-config', data={
    'recyclarr.yaml': (importstr 'recyclarr.yaml'),
  }),
]
