local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='transmission-music',
  path='applications/base/transmission-music',
  namespace=ns.metadata.name,
).withChart(
  name='transmission',
  repoURL='https://jacobcolvin.com/helm-charts/',
  targetRevision='0.6.0',
  releaseName='transmission-music',
  values='values.yaml'
)
