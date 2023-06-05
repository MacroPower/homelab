local ns = import '../../../base/inlets-client/namespace.libsonnet';
local app = import '../../../lib/app.libsonnet';

app.new(
  name='inlets-client-seedbox',
  path='applications/environments/home/inlets-client-seedbox',
  namespace=ns.metadata.name,
).withChart(
  name='inlets-client',
  repoURL='https://jacobcolvin.com/helm-charts/',
  targetRevision='0.1.2',
  releaseName='linkerd-tunnel-seedbox',
  values='../../../base/inlets-client/values.yaml'
).withChartParams({
  'inlets.url': 'wss://linkerd-tunnel-sb.macro.network',
})
