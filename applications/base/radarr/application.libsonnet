local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='radarr',
  path='applications/base/radarr',
  namespace=ns.metadata.name,
).withChart(
  name='servarr',
  repoURL='https://jacobcolvin.com/helm-charts/',
  targetRevision='0.1.2',
  releaseName='radarr',
  values='values.yaml'
)
