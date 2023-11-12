local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='jaeger-operator',
  path='applications/base/jaeger-operator',
  namespace=ns.metadata.name,
).withChart(
  name='jaeger-operator',
  repoURL='https://jaegertracing.github.io/helm-charts',
  targetRevision='2.49.0',
  releaseName='jaeger-operator',
  values='values.yaml'
)
