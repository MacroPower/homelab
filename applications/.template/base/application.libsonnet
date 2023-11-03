local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='{{ .Name }}',
  path='applications/base/{{ .Name }}',
  namespace=ns.metadata.name,
).withChart(
  name='{{ .Name }}',
  repoURL='https://jacobcolvin.com/helm-charts',
  targetRevision='0.1.0',
  releaseName='{{ .Name }}',
  values='values.yaml'
)
