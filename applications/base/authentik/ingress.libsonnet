local ingress = import '../../lib/ingress.libsonnet';

local ingressAnnotations = std.parseYaml(std.extVar('ingressAnnotations'));

ingress.new(
  name='authentik-ingress',
  host='authentik.macro.network',
  serviceName='authentik',
  servicePort=80,
  annotations=ingressAnnotations,
)
