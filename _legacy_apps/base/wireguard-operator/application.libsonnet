local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='wireguard-operator',
  path='applications/base/wireguard-operator',
  namespace=ns.metadata.name,
).withChart(
  name='wireguard-operator',
  repoURL='https://jacobcolvin.com/helm-charts',
  targetRevision='0.2.0',
  releaseName='wireguard-operator',
  values='values.yaml'
)
