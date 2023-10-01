local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='goldilocks',
  path='applications/base/goldilocks',
  namespace=ns.metadata.name,
).withChart(
  name='goldilocks',
  repoURL='https://charts.fairwinds.com/stable',
  targetRevision='7.3.0',
  releaseName='goldilocks',
  values='values.yaml'
)
