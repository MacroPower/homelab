local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='loki',
  path='applications/base/loki',
  namespace=ns.metadata.name,
).withChart(
  name='loki',
  repoURL='https://grafana.github.io/helm-charts',
  targetRevision='5.43.1',
  releaseName='loki',
  values='values.yaml'
)
