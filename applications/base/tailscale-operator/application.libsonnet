local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='tailscale-operator',
  path='applications/base/tailscale-operator',
  namespace=ns.metadata.name,
).withChart(
  name='tailscale-operator',
  repoURL='https://jacobcolvin.com/helm-charts',
  targetRevision='0.1.0',
  releaseName='tailscale-operator',
  values='values.yaml'
)
