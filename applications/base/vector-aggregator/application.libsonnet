local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='vector-aggregator',
  path='applications/base/vector-aggregator',
  namespace=ns.metadata.name,
).withChart(
  name='vector',
  repoURL='https://helm.vector.dev/',
  targetRevision='0.37.0',
  releaseName='vector-aggregator',
  values='values.yaml'
)
