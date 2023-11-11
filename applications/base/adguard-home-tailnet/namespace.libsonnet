local k = import '../../lib/k.libsonnet';

k.core.v1.namespace.new('adguard-home-tailnet') +
k.core.v1.namespace.metadata.withLabelsMixin({
  'odigos-instrumentation': 'enabled',
})
