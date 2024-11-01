local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='opentelemetry-operator',
  path='applications/base/opentelemetry-operator',
  namespace=ns.metadata.name,
).withChart(
  name='opentelemetry-operator',
  repoURL='https://open-telemetry.github.io/opentelemetry-helm-charts',
  targetRevision='0.72.0',
  releaseName='opentelemetry-operator',
  values='values.yaml'
)
