local ingress = import '../../lib/ingress.libsonnet';
local ns = import 'namespace.libsonnet';

local ingressHost = std.extVar('ingressHost');
local ingressAnnotations = std.parseYaml(std.extVar('ingressAnnotations'));

ingress.new(
  name='homepage-ingress',
  namespace=ns.metadata.name,
  host=ingressHost,
  serviceName='homepage',
  servicePort=3000,
  annotations=ingressAnnotations {
    'traefik.ingress.kubernetes.io/router.middlewares': 'authentik-ak-outpost@kubernetescrd',
    'gethomepage.dev/enabled': 'true',
    'gethomepage.dev/name': 'Homepage',
    'gethomepage.dev/description': 'Homepage',
    'gethomepage.dev/group': 'Apps',
    'gethomepage.dev/icon': 'homepage',
    'gethomepage.dev/podSelector': '',
    'gethomepage.dev/siteMonitor': 'http://localhost:3000/',
  },
)
