local ingress = import '../../lib/ingress.libsonnet';

local ingressHost = std.extVar('ingressHost');
local ingressAnnotations = std.parseYaml(std.extVar('ingressAnnotations'));

ingress.new(
  name='authentik-ingress',
  host=ingressHost,
  serviceName='authentik-home',
  servicePort=80,
  annotations=ingressAnnotations,
)
