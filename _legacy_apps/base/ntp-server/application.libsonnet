local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='ntp-server',
  path='applications/base/ntp-server',
  namespace=ns.metadata.name,
).withChart(
  name='template',
  repoURL='https://jacobcolvin.com/helm-charts',
  targetRevision='0.2.0',
  releaseName='ntp-server',
  values='values.yaml'
)
