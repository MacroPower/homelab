local app = import '../../lib/app.libsonnet';
local ns = import '../transmission/namespace.libsonnet';

app.new(
  name='transmission-tv',
  path='applications/base/transmission-tv',
  namespace=ns.metadata.name,
).withChart(
  name='transmission',
  repoURL='https://jacobcolvin.com/helm-charts/',
  targetRevision='0.6.0',
  releaseName='transmission-tv',
  values='values.yaml'
)
