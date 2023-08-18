local ingress = import '../../lib/ingress.libsonnet';
local ns = import 'namespace.libsonnet';

local ingressHost = std.extVar('ingressHost');
local ingressAnnotations = std.parseYaml(std.extVar('ingressAnnotations'));

ingress.new(
  name='local-ai-ingress',
  namespace=ns.metadata.name,
  host=ingressHost,
  serviceName='local-ai-frontend',
  servicePort=3000,
  annotations=ingressAnnotations {
    'traefik.ingress.kubernetes.io/router.middlewares': 'authentik-ak-outpost@kubernetescrd',
    'gethomepage.dev/enabled': 'true',
    'gethomepage.dev/name': 'local-ai',
    'gethomepage.dev/description': 'example',
    'gethomepage.dev/group': 'example',
    'gethomepage.dev/icon': 'example',
    'gethomepage.dev/podSelector': '',
  },
)
