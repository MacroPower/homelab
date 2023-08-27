local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='transmission-webdav',
  path='applications/base/transmission-webdav',
  namespace=ns.metadata.name,
).withChart(
  name='sftpgo',
  repoURL='https://charts.sagikazarmark.dev',
  targetRevision='0.19.0',
  releaseName='transmission-webdav',
  values='values.yaml'
)
