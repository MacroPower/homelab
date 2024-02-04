local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='template-controller',
  path='applications/base/template-controller',
  namespace=ns.metadata.name,
).withChart(
  name='template-controller',
  repoURL='https://kluctl.github.io/charts',
  targetRevision='0.2.3',
  releaseName='template-controller',
  values='values.yaml'
)
