local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='prowlarr',
  path='applications/base/prowlarr',
  namespace=ns.metadata.name,
).withChart(
  name='servarr',
  repoURL='https://jacobcolvin.com/helm-charts/',
  targetRevision='0.1.2',
  releaseName='prowlarr',
  values='values.yaml'
)
