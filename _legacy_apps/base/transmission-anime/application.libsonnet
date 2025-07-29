local app = import '../../lib/app.libsonnet';
local ns = import '../transmission/namespace.libsonnet';

app.new(
  name='transmission-anime',
  path='applications/base/transmission-anime',
  namespace=ns.metadata.name,
).withChart(
  name='transmission',
  repoURL='https://jacobcolvin.com/helm-charts/',
  targetRevision='0.6.0',
  releaseName='transmission-anime',
  values='values.yaml'
)
