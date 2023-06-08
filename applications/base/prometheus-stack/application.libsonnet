local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='prometheus-stack',
  path='applications/base/prometheus-stack',
  namespace=ns.metadata.name,
).withChart(
  name='kube-prometheus-stack',
  repoURL='https://prometheus-community.github.io/helm-charts',
  targetRevision='46.7.0',
  releaseName='kube-prometheus-stack',
  values='values.yaml',
  skipCrds=true,
)
