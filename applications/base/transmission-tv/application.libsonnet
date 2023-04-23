local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='transmission',
  path='applications/base/transmission',
  namespace=ns.metadata.name,
).withChart(
  name='transmission',
  repoURL='https://jacobcolvin.com/helm-charts/',
  targetRevision='0.6.0',
  releaseName='transmission',
  values='values.yaml'
)
