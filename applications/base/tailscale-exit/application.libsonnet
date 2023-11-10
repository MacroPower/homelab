local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='tailscale-exit',
  path='applications/base/tailscale-exit',
  namespace=ns.metadata.name,
).withChart(
  name='template',
  repoURL='https://jacobcolvin.com/helm-charts',
  targetRevision='0.2.0',
  releaseName='tailscale-exit',
  values='values.yaml'
)
