local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='dragonfly-operator',
  path='applications/base/dragonfly-operator',
  namespace=ns.metadata.name,
).withChart(
  name='dragonfly-operator',
  repoURL='https://jacobcolvin.com/helm-charts',
  targetRevision='0.1.1',
  releaseName='dragonfly-operator',
  values='values.yaml'
)
