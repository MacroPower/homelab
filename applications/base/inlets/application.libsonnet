local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='inlets-server',
  path='applications/base/inlets-server',
  namespace=ns.metadata.name,
).withChart(
  name='inlets-server',
  repoURL='https://jacobcolvin.com/helm-charts/',
  targetRevision='0.1.1',
  releaseName='linkerd-tunnel',
  values='values.yaml'
)
