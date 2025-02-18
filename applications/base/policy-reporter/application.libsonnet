local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='policy-reporter',
  path='applications/base/policy-reporter',
  namespace=ns.metadata.name,
).withChart(
  name='policy-reporter',
  repoURL='https://kyverno.github.io/policy-reporter',
  targetRevision='3.0.4',
  releaseName='policy-reporter',
  values='values.yaml'
)
