local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='radarr',
  path='applications/base/radarr',
  namespace=ns.metadata.name,
).withChart(
  name='app-template',
  repoURL='ghcr.io/bjw-s/helm',
  targetRevision='3.2.1',
  releaseName='app-template',
  values='values.yaml'
)
