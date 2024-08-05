local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='ocis-nats',
  path='applications/base/ocis-nats',
  namespace=ns.metadata.name,
).withChart(
  name='nats',
  repoURL='https://nats-io.github.io/k8s/helm/charts/',
  targetRevision='1.2.2',
  releaseName='nats',
  values='values.yaml'
)
