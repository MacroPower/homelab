local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='linkerd-jaeger',
  path='applications/base/linkerd-jaeger',
  namespace=ns.metadata.name,
).withChart(
  name='linkerd-jaeger',
  repoURL='https://helm.linkerd.io/edge',
  targetRevision='30.9.1-edge',
  releaseName='linkerd-jaeger',
  values='values.yaml'
)
