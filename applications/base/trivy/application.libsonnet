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
).withChart(
  name='trivy-operator-polr-adapter',
  repoURL='https://fjogeleit.github.io/trivy-operator-polr-adapter',
  targetRevision='0.9.0',
  releaseName='trivy',
  values='values-polr-adapter.yaml'
)
