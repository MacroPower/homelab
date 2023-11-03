local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='adguard-home-tailnet',
  path='applications/base/adguard-home-tailnet',
  namespace=ns.metadata.name,
).withChart(
  name='adguard-home',
  repoURL='https://jacobcolvin.com/helm-charts/',
  targetRevision='0.3.0',
  releaseName='adguard-home-tailnet',
  values='values.yaml'
)
