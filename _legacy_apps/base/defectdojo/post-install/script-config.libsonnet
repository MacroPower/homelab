local k = import '../../../lib/k.libsonnet';

[
  k.core.v1.configMap.new('get-api-token', data={
    'main.py': (importstr 'main.py'),
  }),
]
