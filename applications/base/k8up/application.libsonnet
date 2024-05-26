local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='k8up',
  path='applications/base/k8up',
  namespace=ns.metadata.name,
).withChart(
  name='k8up',
  repoURL='https://k8up-io.github.io/k8up',
  targetRevision='4.4.3',
  releaseName='k8up',
  values='values.yaml'
)
