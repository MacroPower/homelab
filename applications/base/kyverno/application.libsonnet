local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='kyverno',
  path='applications/base/kyverno',
  namespace=ns.metadata.name,
  annotations={
    'argocd.argoproj.io/sync-options': 'SkipDryRunOnMissingResource=true'
  }
).withChart(
  name='kyverno',
  repoURL='https://kyverno.github.io/kyverno/',
  targetRevision='3.3.5',
  releaseName='kyverno',
  values='values.yaml'
)
