local ingress = import '../../lib/ingress.libsonnet';

local ingressHost = std.extVar('ingressHost');
local ingressAnnotations = std.parseYaml(std.extVar('ingressAnnotations'));

ingress.new(
  name='goldilocks-ingress',
  host=ingressHost,
  serviceName='goldilocks-dashboard',
  servicePort=80,
  annotations=ingressAnnotations,
)
