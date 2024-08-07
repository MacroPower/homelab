local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='argo-workflows',
  path='applications/base/argo-workflows',
  namespace=ns.metadata.name,
).withChart(
  name='argo-workflows',
  repoURL='https://argoproj.github.io/argo-helm',
  targetRevision='0.41.14',
  releaseName='argo-workflows',
  values='values.yaml'
)
