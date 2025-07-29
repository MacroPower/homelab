local k = import '../../lib/k.libsonnet';

[
  k.core.v1.configMap.new('twitch-config', data={
    'run.py': (importstr 'run.py'),
  }),
]
