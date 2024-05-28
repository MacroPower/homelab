local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='opentelemetry-collector',
  path='applications/base/opentelemetry-collector',
  namespace=ns.metadata.name,
).withIgnoreDifferences([{
  'group': 'opentelemetry.io',
  'kind': 'OpenTelemetryCollector',
  'namespace': ns.metadata.name,
  'jsonPointers': [
    '/metadata/generation',
  ],
}])
