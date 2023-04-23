local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='sonarr',
  path='applications/base/sonarr',
  namespace=ns.metadata.name,
).withChart(
  name='servarr',
  repoURL='https://jacobcolvin.com/helm-charts/',
  targetRevision='0.1.2',
  releaseName='sonarr',
  values='values.yaml'
)
