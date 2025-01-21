local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='komoplane',
  path='applications/base/komoplane',
  namespace=ns.metadata.name,
).withChart(
  name='komoplane',
  repoURL='https://helm-charts.komodor.io',
  targetRevision='0.1.6',
  releaseName='komoplane',
  values='values.yaml'
)
