local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='liqo',
  path='applications/base/liqo',
  namespace=ns.metadata.name,
).withChart(
  name='liqo',
  repoURL='https://helm.liqo.io/',
  targetRevision='0.10.3',
  releaseName='liqo',
  values='values.yaml'
)
