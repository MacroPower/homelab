local app = import '../../lib/app.libsonnet';
local ns = import '../transmission/namespace.libsonnet';

app.new(
  name='transmission-webdav',
  path='applications/base/transmission-webdav',
  namespace=ns.metadata.name,
).withChart(
  name='rclone',
  repoURL='https://jacobcolvin.com/helm-charts/',
  targetRevision='0.3.0',
  releaseName='transmission-webdav',
  values='values.yaml'
)
