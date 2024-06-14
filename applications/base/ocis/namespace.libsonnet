local k = import '../../lib/k.libsonnet';

k.core.v1.namespace.new('ocis') +
k.core.v1.namespace.mixin.metadata.withAnnotations({
  'instrumentation.opentelemetry.io/inject-sdk': 'opentelemetry/default',
})
