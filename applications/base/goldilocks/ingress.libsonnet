local ingress = import '../../lib/ingress.libsonnet';
local ns = import 'namespace.libsonnet';

local ingressHost = std.extVar('ingressHost');
local ingressAnnotations = std.parseYaml(std.extVar('ingressAnnotations'));

ingress.new(
  name='goldilocks-ingress',
  namespace=ns.metadata.name,
  host=ingressHost,
  serviceName='goldilocks-dashboard',
  servicePort=80,
  annotations=ingressAnnotations {
    'traefik.ingress.kubernetes.io/router.middlewares': 'authentik-ak-outpost@kubernetescrd',
    'gethomepage.dev/enabled': 'true',
    'gethomepage.dev/name': 'Goldilocks',
    'gethomepage.dev/description': 'Resource Recommendations',
    'gethomepage.dev/group': 'Cluster Management',
    'gethomepage.dev/icon': 'si-saturn',
    'gethomepage.dev/podSelector': '',
  },
)
