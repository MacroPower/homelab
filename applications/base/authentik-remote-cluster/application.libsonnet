local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='authentik-remote-cluster',
  path='applications/base/authentik-remote-cluster',
  namespace=ns.metadata.name,
).withChart(
  name='authentik-remote-cluster',
  repoURL='https://charts.goauthentik.io/',
  targetRevision='1.2.2',
  releaseName='authentik-remote-cluster',
)
