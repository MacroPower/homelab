local external_service = import '../../lib/external_service.libsonnet';
local ns = import 'namespace.libsonnet';

external_service.new(
  name='pfsense-node-exporter',
  namespace=ns.metadata.name,
  ipAddress='10.0.0.1',
  portName='metrics',
  port=9100,
  monitor=true,
) +
external_service.new(
  name='pfsense-telegraf',
  namespace=ns.metadata.name,
  ipAddress='10.0.0.1',
  portName='metrics',
  port=9273,
  monitor=true,
) +
external_service.new(
  name='unraid-telegraf',
  namespace=ns.metadata.name,
  ipAddress='10.0.1.3',
  portName='metrics',
  port=9273,
  monitor=true,
) +
external_service.new(
  name='desktop',
  namespace=ns.metadata.name,
  ipAddress='10.0.10.1',
  portName='metrics',
  port=9182,
  monitor=true,
) +
external_service.new(
  name='mac-mini',
  namespace=ns.metadata.name,
  ipAddress='10.0.10.2',
  portName='metrics',
  port=9100,
  monitor=true,
)
