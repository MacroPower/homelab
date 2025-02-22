local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='reloader',
  path='applications/base/reloader',
  namespace=ns.metadata.name,
).withChart(
  name='reloader',
  repoURL='https://stakater.github.io/stakater-charts',
  targetRevision='1.3.0',
  releaseName='reloader',
  values='values.yaml'
)
