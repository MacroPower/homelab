local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='cloudnative-pg',
  path='applications/base/cloudnative-pg',
  namespace=ns.metadata.name,
).withChart(
  name='cloudnative-pg',
  repoURL='https://cloudnative-pg.io/charts/',
  targetRevision='0.19.1',
  releaseName='cloudnative-pg',
  values='values.yaml'
)
