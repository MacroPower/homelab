local ingress = import '../../lib/ingress.libsonnet';

local ingressHost = std.extVar('ingressHost');
local ingressAnnotations = std.parseYaml(std.extVar('ingressAnnotations'));

ingress.new(
  name='grafana-ingress',
  host=ingressHost,
  serviceName='grafana',
  servicePort=80,
  annotations=ingressAnnotations,
)
