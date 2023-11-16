local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='groundcover',
  path='applications/base/groundcover',
  namespace=ns.metadata.name,
).withChart(
  name='groundcover',
  repoURL='https://helm.groundcover.com',
  targetRevision='1.6.6',
  releaseName='groundcover',
  values='values.yaml'
)
