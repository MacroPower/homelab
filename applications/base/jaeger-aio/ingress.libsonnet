local ingress = import '../../lib/ingress.libsonnet';
local ns = import '../jaeger-operator/namespace.libsonnet';

local ingressHost = std.extVar('ingressHost');
local ingressAnnotations = std.parseYaml(std.extVar('ingressAnnotations'));

ingress.new(
  name='jaeger-aio-query-ingress',
  namespace=ns.metadata.name,
  host=ingressHost,
  serviceName='jaeger-aio-query',
  servicePort=16686,
  annotations=ingressAnnotations {
    'traefik.ingress.kubernetes.io/router.middlewares': 'authentik-ak-outpost@kubernetescrd',
    'gethomepage.dev/enabled': 'true',
    'gethomepage.dev/name': 'Jaeger',
    'gethomepage.dev/description': 'Tracing',
    'gethomepage.dev/group': 'Observability',
    'gethomepage.dev/icon': 'jaeger',
    'gethomepage.dev/podSelector': '',
  },
)
