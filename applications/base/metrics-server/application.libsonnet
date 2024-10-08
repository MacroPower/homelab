local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='metrics-server',
  path='applications/base/metrics-server',
  namespace=ns.metadata.name,
).withChart(
  name='metrics-server',
  repoURL='https://kubernetes-sigs.github.io/metrics-server/',
  targetRevision='3.12.2',
  releaseName='metrics-server',
  values='values.yaml',
)
