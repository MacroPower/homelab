local app = import '../../lib/app.libsonnet';

app.new(
  name='argocd',
  path='applications/base/argocd',
  namespace='argocd',
).withChart(
  name='argo-cd',
  repoURL='https://argoproj.github.io/argo-helm',
  targetRevision='7.3.0',
  releaseName='argocd',
  values='values.yaml'
)
