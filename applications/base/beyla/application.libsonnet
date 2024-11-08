local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='beyla',
  path='applications/base/beyla',
  namespace=ns.metadata.name,
).withChart(
  name='beyla',
  repoURL='https://grafana.github.io/helm-charts',
  targetRevision='1.4.11',
  releaseName='beyla',
  values='values.yaml'
)
