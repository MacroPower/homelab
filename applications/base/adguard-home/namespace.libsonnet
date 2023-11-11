local k = import '../../lib/k.libsonnet';

k.core.v1.namespace.new('adguard-home') +
k.core.v1.namespace.metadata.withLabelsMixin({
  'odigos-instrumentation': 'enabled',
})
