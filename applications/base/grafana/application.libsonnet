local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='grafana',
  path='applications/base/grafana',
  namespace=ns.metadata.name,
).withChart(
  name='grafana',
  repoURL='https://grafana.github.io/helm-charts',
  targetRevision='6.39.0',
  releaseName='grafana',
  values='values.yaml'
)
