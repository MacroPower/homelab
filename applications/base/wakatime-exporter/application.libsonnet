local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='wakatime-exporter',
  path='applications/base/wakatime-exporter',
  namespace=ns.metadata.name,
).withChart(
  name='wakatime-exporter',
  repoURL='https://jacobcolvin.com/helm-charts/',
  targetRevision='0.1.1',
  releaseName='wakatime-exporter',
  values='values.yaml'
)
