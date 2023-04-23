local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='rclone-media-webdav',
  path='applications/base/rclone-media-webdav',
  namespace=ns.metadata.name,
).withChart(
  name='rclone',
  repoURL='https://jacobcolvin.com/helm-charts/',
  targetRevision='0.3.0',
  releaseName='rclone',
  values='values.yaml'
)
