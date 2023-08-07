local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='kube-prometheus-stack',
  path='applications/base/prometheus-stack',
  namespace=ns.metadata.name,
).withChart(
  name='kube-prometheus-stack',
  repoURL='https://prometheus-community.github.io/helm-charts',
  targetRevision='48.3.1',
  releaseName='kube-prometheus-stack',
  values='values.yaml',
  skipCrds=true,
)
