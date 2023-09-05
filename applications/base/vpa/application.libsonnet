local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='vpa',
  path='applications/base/vpa',
  namespace=ns.metadata.name,
).withChart(
  name='vpa',
  repoURL='https://charts.fairwinds.com/stable',
  targetRevision='2.5.1',
  releaseName='vpa',
  values='values.yaml'
)
