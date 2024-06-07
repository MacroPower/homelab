local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='gadget',
  path='applications/base/gadget',
  namespace=ns.metadata.name,
).withChart(
  name='gadget',
  repoURL='https://inspektor-gadget.github.io/charts',
  targetRevision='0.29.0',
  releaseName='gadget',
  values='values.yaml'
)
