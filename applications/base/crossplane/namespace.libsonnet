local k = import '../../lib/k.libsonnet';

k.core.v1.namespace.new('crossplane') +
k.core.v1.namespace.metadata.withLabelsMixin({
  'odigos-instrumentation': 'enabled',
})
