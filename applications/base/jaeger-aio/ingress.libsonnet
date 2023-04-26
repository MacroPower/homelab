local ingress = import '../../lib/ingress.libsonnet';

local ingressHost = std.extVar('ingressHost');
local ingressAnnotations = std.parseYaml(std.extVar('ingressAnnotations'));

ingress.new(
  name='jaeger-aio-query-ingress',
  host=ingressHost,
  serviceName='jaeger-aio-query',
  servicePort=16686,
  annotations=ingressAnnotations {
    'traefik.ingress.kubernetes.io/router.middlewares': 'traefik-authentik@kubernetescrd',
  },
)
