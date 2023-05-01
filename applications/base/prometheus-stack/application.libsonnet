local app = import '../../lib/app.libsonnet';

app.new(
  name='prometheus-stack',
  path='applications/base/prometheus-stack',
  namespace='prometheus',
).withChart(
  name='kube-prometheus-stack',
  repoURL='https://prometheus-community.github.io/helm-charts',
  targetRevision='45.23.0',
  releaseName='kube-prometheus-stack',
  values='values.yaml',
  skipCrds=true,
)
