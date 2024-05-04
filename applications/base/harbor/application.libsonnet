local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='harbor',
  path='applications/base/harbor',
  namespace=ns.metadata.name,
).withChart(
  name='harbor',
  repoURL='https://helm.goharbor.io',
  targetRevision='1.14.2',
  releaseName='harbor',
  values='values.yaml'
)
