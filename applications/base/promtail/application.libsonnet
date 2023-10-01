local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='promtail',
  path='applications/base/promtail',
  namespace=ns.metadata.name,
).withChart(
  name='promtail',
  repoURL='https://grafana.github.io/helm-charts',
  targetRevision='6.15.2',
  releaseName='promtail',
  values='values.yaml'
)
