local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='adguard-home',
  path='applications/base/adguard-home',
  namespace=ns.metadata.name,
).withChart(
  name='adguard-home',
  repoURL='https://jacobcolvin.com/helm-charts/',
  targetRevision='0.3.0',
  releaseName='adguard-home',
  values='values.yaml'
)
