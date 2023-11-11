local ingress = import '../../lib/ingress.libsonnet';
local ns = import 'namespace.libsonnet';

local ingressHost = std.extVar('ingressHost');
local ingressAnnotations = std.parseYaml(std.extVar('ingressAnnotations'));

ingress.new(
  name='odigos-ingress',
  namespace=ns.metadata.name,
  host=ingressHost,
  serviceName='odigos-ui',
  servicePort=3000,
  annotations=ingressAnnotations {
    'traefik.ingress.kubernetes.io/router.middlewares': 'authentik-ak-outpost@kubernetescrd',
    'gethomepage.dev/enabled': 'true',
    'gethomepage.dev/name': 'odigos',
    'gethomepage.dev/description': '',
    'gethomepage.dev/group': 'Observability',
    'gethomepage.dev/icon': '',
    'gethomepage.dev/podSelector': '',
  },
)
