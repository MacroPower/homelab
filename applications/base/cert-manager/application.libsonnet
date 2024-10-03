local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='cert-manager',
  path='applications/base/cert-manager',
  namespace=ns.metadata.name,
).withChart(
  name='cert-manager',
  repoURL='https://charts.jetstack.io',
  targetRevision='v1.16.0',
  releaseName='cert-manager',
  values='values.yaml'
)
