local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='homepage',
  path='applications/base/homepage',
  namespace=ns.metadata.name,
).withChart(
  name='homepage',
  repoURL='https://jameswynn.github.io/helm-charts',
  targetRevision='2.0.1',
  releaseName='homepage',
  values='values.yaml'
)
