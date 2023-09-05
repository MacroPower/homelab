local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='rclone-restic',
  path='applications/base/rclone-restic',
  namespace=ns.metadata.name,
).withChart(
  name='rclone',
  repoURL='https://jacobcolvin.com/helm-charts/',
  targetRevision='1.0.1',
  releaseName='restic',
  values='values.yaml'
)
