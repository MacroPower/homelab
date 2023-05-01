local ingress = import '../../lib/ingress.libsonnet';

local ingressHost = std.extVar('ingressHost');
local ingressAnnotations = std.parseYaml(std.extVar('ingressAnnotations'));

ingress.new(
  name='authentik-ingress',
  host=ingressHost,
  serviceName='ak-outpost-hcloud',
  servicePort=9000,
  annotations=ingressAnnotations,
)
