local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='transmission-audio',
  path='applications/base/transmission-audio',
  namespace=ns.metadata.name,
).withChart(
  name='transmission',
  repoURL='https://jacobcolvin.com/helm-charts/',
  targetRevision='0.6.0',
  releaseName='transmission-audio',
  values='values.yaml'
)
