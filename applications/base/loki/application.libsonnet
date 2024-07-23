local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='loki',
  path='applications/base/loki',
  namespace=ns.metadata.name,
).withChart(
  name='loki',
  repoURL='https://grafana.github.io/helm-charts',
  targetRevision='6.7.2',
  releaseName='loki',
  values='values.yaml'
)
