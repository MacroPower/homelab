local k = import '../../lib/k.libsonnet';

k.core.v1.namespace.new('tailscale-exit') +
k.core.v1.namespace.metadata.withLabelsMixin({
  'odigos-instrumentation': 'enabled',
})
