local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='spegel',
  path='applications/base/spegel',
  namespace=ns.metadata.name,
).withChart(
  name='spegel',
  repoURL='ghcr.io/spegel-org/helm-charts',
  targetRevision='v0.0.23',
  releaseName='spegel',
  values='values.yaml'
)
