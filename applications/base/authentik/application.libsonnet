local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='authentik',
  path='applications/base/authentik',
  namespace=ns.metadata.name,
).withChart(
  name='authentik',
  repoURL='https://charts.goauthentik.io/',
  targetRevision='2023.8.2',
  releaseName='authentik',
  values='values.yaml'
)
