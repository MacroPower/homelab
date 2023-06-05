local ns = import '../../../base/inlets-client/namespace.libsonnet';
local app = import '../../../lib/app.libsonnet';

app.new(
  name='inlets-client-hcloud',
  path='applications/environments/home/inlets-client-hcloud',
  namespace=ns.metadata.name,
).withChart(
  name='inlets-client',
  repoURL='https://jacobcolvin.com/helm-charts/',
  targetRevision='0.1.2',
  releaseName='linkerd-tunnel-hcloud',
  values='../../../base/inlets-client/values.yaml'
).withChartParams({
  'inlets.url': 'wss://linkerd-tunnel.macro.network',
})
