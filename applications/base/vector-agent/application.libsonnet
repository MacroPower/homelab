local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='vector-agent',
  path='applications/base/vector-agent',
  namespace=ns.metadata.name,
).withChart(
  name='vector',
  repoURL='https://helm.vector.dev/',
  targetRevision='0.36.0',
  releaseName='vector-agent',
  values='values.yaml'
)
