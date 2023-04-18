local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='fluent-bit',
  path='applications/base/fluent-bit',
  namespace=ns.metadata.name,
).withChart(
  name='fluent-bit',
  repoURL='https://fluent.github.io/helm-charts',
  targetRevision='0.27.0',
  releaseName='fluent-bit',
  values='values.yaml'
)
