local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='opentelemetry-operator',
  path='applications/base/opentelemetry-operator',
  namespace=ns.metadata.name,
).withChart(
  name='opentelemetry-operator',
  repoURL='https://open-telemetry.github.io/opentelemetry-helm-charts',
  targetRevision='0.64.4',
  releaseName='opentelemetry-operator',
  values='values.yaml'
)
