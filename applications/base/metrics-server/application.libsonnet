local app = import '../../lib/app.libsonnet';

app.new(
  name='metrics-server',
  path='applications/base/metrics-server',
  namespace='kube-system',
).withChart(
  name='metrics-server',
  repoURL='https://kubernetes-sigs.github.io/metrics-server/',
  targetRevision='3.8.3',
  releaseName='metrics-server',
)
