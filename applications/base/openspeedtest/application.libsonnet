local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='openspeedtest',
  path='applications/base/openspeedtest',
  namespace=ns.metadata.name,
).withChart(
  name='openspeedtest',
  repoURL='https://openspeedtest.github.io/Helm-chart/',
  targetRevision='0.1.2',
  releaseName='openspeedtest',
  values='values.yaml'
)
