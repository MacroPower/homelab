local k = import '../../lib/k.libsonnet';

k.core.v1.namespace.new('tailscale-operator') +
k.core.v1.namespace.metadata.withLabelsMixin({
  'odigos-instrumentation': 'enabled',
})
