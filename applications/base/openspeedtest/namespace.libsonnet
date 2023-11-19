local k = import '../../lib/k.libsonnet';

k.core.v1.namespace.new('openspeedtest') +
k.core.v1.namespace.metadata.withLabelsMixin({
  'odigos-instrumentation': 'enabled',
})
