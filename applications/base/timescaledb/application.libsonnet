local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='timescaledb-single',
  path='applications/base/timescaledb-single',
  namespace=ns.metadata.name,
).withChart(
  name='timescaledb-single',
  repoURL='https://charts.timescale.com',
  targetRevision='0.33.1',
  releaseName='timescaledb-single',
  values='values.yaml'
)
