local k = import '../../../lib/k.libsonnet';

[
  k.core.v1.configMap.new('chrony-agent', data={
    'run.sh': (importstr 'agent.sh'),
    'chrony.conf': (importstr 'agent.conf'),
  }),
  k.core.v1.configMap.new('chrony', data={
    'run.sh': (importstr 'server.sh'),
    'chrony.conf': (importstr 'server.conf'),
  }),
]
