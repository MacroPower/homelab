local ingress = import '../../lib/ingress.libsonnet';

local ingressHost = std.extVar('ingressHost');
local ingressAnnotations = std.parseYaml(std.extVar('ingressAnnotations'));

ingress.new(
  name='argocd-ingress',
  host=ingressHost,
  serviceName='argocd-server',
  servicePort=80,
  annotations=ingressAnnotations,
)
