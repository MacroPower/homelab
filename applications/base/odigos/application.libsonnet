local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='odigos',
  path='applications/base/odigos',
  namespace=ns.metadata.name,
).withChart(
  name='odigos',
  repoURL='https://keyval-dev.github.io/odigos-charts/',
  targetRevision='0.2.39',
  releaseName='odigos',
  values='values.yaml'
)
