local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='trivy',
  path='applications/base/trivy',
  namespace=ns.metadata.name,
).withChart(
  name='trivy-operator',
  repoURL='https://aquasecurity.github.io/helm-charts/',
  targetRevision='0.22.1',
  releaseName='trivy',
  values='values.yaml'
)
