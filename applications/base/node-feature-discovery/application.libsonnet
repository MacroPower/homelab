local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='node-feature-discovery',
  path='applications/base/node-feature-discovery',
  namespace=ns.metadata.name,
).withChart(
  name='node-feature-discovery',
  repoURL='https://kubernetes-sigs.github.io/node-feature-discovery/charts',
  targetRevision='0.17.1',
  releaseName='node-feature-discovery',
  values='values.yaml'
)
