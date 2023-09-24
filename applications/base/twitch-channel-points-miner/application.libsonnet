local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='twitch-channel-points-miner',
  path='applications/base/twitch-channel-points-miner',
  namespace=ns.metadata.name,
).withChart(
  name='twitch-channel-points-miner',
  repoURL='https://jacobcolvin.com/helm-charts/',
  targetRevision='0.1.0',
  releaseName='twitch-channel-points-miner',
  values='values.yaml'
)
