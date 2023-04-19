local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='k8s-event-logger',
  path='applications/base/k8s-event-logger',
  namespace='kube-system',
).withChart(
  name='k8s-event-logger',
  repoURL='https://charts.deliveryhero.io/',
  targetRevision='1.1',
  releaseName='k8s-event-logger',
  values='values.yaml'
)
