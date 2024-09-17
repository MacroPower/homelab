local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='crossplane',
  path='applications/base/crossplane',
  namespace=ns.metadata.name,
).withChart(
  name='crossplane',
  repoURL='https://charts.crossplane.io/stable',
  targetRevision='1.17.1',
  releaseName='crossplane',
  values='values.yaml'
)
