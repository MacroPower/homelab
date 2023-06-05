local ns = import '../../../base/linkerd-multicluster/namespace.libsonnet';
local app = import '../../../lib/app.libsonnet';

app.new(
  name='local-volume-static-provisioner',
  path='applications/environments/seedbox/local-volume-static-provisioner',
  namespace='kube-system',
).withChart(
  name='local-volume-static-provisioner',
  repoURL='https://jacobcolvin.com/helm-charts/',
  targetRevision='1.0.0',
  releaseName='local-volume-static-provisioner',
  values='values.yaml',
)
