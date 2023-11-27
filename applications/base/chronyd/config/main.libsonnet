local k = import '../../../lib/k.libsonnet';

[
  k.core.v1.configMap.new('chrony', data={
    'run.sh': (importstr 'run.sh'),
  }),
]
