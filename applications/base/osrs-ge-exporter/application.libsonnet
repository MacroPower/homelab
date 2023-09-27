local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='osrs-ge-exporter',
  path='applications/base/osrs-ge-exporter',
  namespace=ns.metadata.name,
).withChart(
  name='osrs-ge-exporter',
  repoURL='https://jacobcolvin.com/helm-charts/',
  targetRevision='0.3.0',
  releaseName='osrs-ge-exporter',
  values='values.yaml'
)
