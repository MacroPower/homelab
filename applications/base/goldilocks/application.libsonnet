local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='goldilocks',
  path='applications/base/goldilocks',
  namespace=ns.metadata.name,
).withChart(
  name='goldilocks',
  repoURL='https://charts.fairwinds.com/stable',
  targetRevision='8.0.1',
  releaseName='goldilocks',
  values='values.yaml'
)
