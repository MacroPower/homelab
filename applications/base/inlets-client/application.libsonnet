local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='inlets-client',
  path='applications/base/inlets-client',
  namespace=ns.metadata.name,
).withChart(
  name='inlets-client',
  repoURL='https://jacobcolvin.com/helm-charts/',
  targetRevision='0.1.2',
  releaseName='linkerd-tunnel',
  values='values.yaml'
)
