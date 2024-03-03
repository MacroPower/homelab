local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='ntp-client',
  path='applications/base/ntp-client',
  namespace=ns.metadata.name,
).withChart(
  name='template',
  repoURL='https://jacobcolvin.com/helm-charts',
  targetRevision='0.2.0',
  releaseName='ntp-client',
  values='values.yaml'
)
