local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='ocis-nack',
  path='applications/base/ocis-nack',
  namespace=ns.metadata.name,
).withChart(
  name='nack',
  repoURL='https://nats-io.github.io/k8s/helm/charts/',
  targetRevision='0.25.4',
  releaseName='nack',
  values='values.yaml'
)
