local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='{{ .Name }}',
  path='applications/base/{{ .Name }}',
  namespace=ns.metadata.name,
).withChart(
  name='{{ .Name }}',
  repoURL='https://< REPLACE ME >',
  targetRevision='0.0.0',
  releaseName='{{ .Name }}',
  values='values.yaml'
)
