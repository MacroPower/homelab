local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='traefik',
  path='applications/base/traefik',
  namespace=ns.metadata.name,
).withChart(
  name='traefik',
  repoURL='https://helm.traefik.io/traefik',
  targetRevision='31.1.1',
  releaseName='traefik',
  values='values.yaml'
)
