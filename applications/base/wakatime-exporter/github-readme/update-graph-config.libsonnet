local k = import '../../../lib/k.libsonnet';

[
  k.core.v1.configMap.new('github-readme-scripts', data={
    'update-graph.sh': (importstr 'update-graph.sh'),
  }),
]
