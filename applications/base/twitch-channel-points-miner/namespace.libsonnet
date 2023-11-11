local k = import '../../lib/k.libsonnet';

k.core.v1.namespace.new('twitch-channel-points-miner') +
k.core.v1.namespace.metadata.withLabelsMixin({
  'odigos-instrumentation': 'enabled',
})
