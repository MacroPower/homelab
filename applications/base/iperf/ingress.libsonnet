local ingress = import '../../lib/ingress.libsonnet';
local ns = import 'namespace.libsonnet';

local ingressHost = std.extVar('ingressHost');
local ingressAnnotations = std.parseYaml(std.extVar('ingressAnnotations'));

ingress.new(
  name='iperf-ingress',
  namespace=ns.metadata.name,
  host=ingressHost,
  serviceName='iperf',
  servicePort=5201,
  annotations=ingressAnnotations,
  localIngress=false,
)
