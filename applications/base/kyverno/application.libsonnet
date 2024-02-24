local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='kyverno',
  path='applications/base/kyverno',
  namespace=ns.metadata.name,
  annotations={
    'argocd.argoproj.io/hook': 'PreSync',
  },
).withChart(
  name='kyverno',
  repoURL='https://kyverno.github.io/kyverno/',
  targetRevision='3.1.4',
  releaseName='kyverno',
  values='values.yaml'
)
