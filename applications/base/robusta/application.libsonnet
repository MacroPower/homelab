local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='robusta',
  path='applications/base/robusta',
  namespace=ns.metadata.name,
).withChart(
  name='robusta',
  repoURL='https://robusta-charts.storage.googleapis.com',
  targetRevision='0.20.0',
  releaseName='robusta',
  values='values.yaml'
)
