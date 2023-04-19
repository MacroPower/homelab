local app = import '../../lib/app.libsonnet';

app.new(
  name='argocd',
  path='applications/base/argocd',
  namespace='argocd',
)
