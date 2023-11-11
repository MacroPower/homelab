local k = import '../../lib/k.libsonnet';

k.core.v1.namespace.new('local-ai') +
k.core.v1.namespace.metadata.withLabelsMixin({
  'odigos-instrumentation': 'enabled',
})
